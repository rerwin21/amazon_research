# -*- coding: utf-8 -*-
"""
@author: rerwin21

"""


# In[import]
import bottlenose, xmltodict
import simplejson, os
import numpy as np
from time import sleep
import time

# In[how_many_files]
def file_len(fname):
    with open(fname) as f:
        for i, l in enumerate(f):
            pass
    return i + 1


# In[function]
def get_product_attributes(product_id, credentials):
    """ The function takes a product id and dictionary of 
    credentials which should be in the form of:
    
      {'AWSAccessKeyId': your_key,
      'AWSSecretAccessKey': private_key,
      'AssociateTag': your_tag}
      
    which are used for authentication. It returns a JSON string which will be
    saved and loaded to a DB later."""
    
    access_key = credentials['AWSAccessKeyId']
    secret_key = credentials['AWSSecretAccessKey']
    assoc_tag = credentials['AssociateTag']
    
    amazon = bottlenose.Amazon(AWSAccessKeyId=access_key, 
                           AWSSecretAccessKey=secret_key,
                           AssociateTag=assoc_tag,
                           MaxQPS=0.8)
                          
    response = amazon.ItemLookup(ItemId=product_id, 
                                 ResponseGroup="ItemAttributes,SalesRank")
                                  
    response_dict = dict(xmltodict.parse(response))
    response_dict = {'product_asin': product_id,
                       'api_response': response_dict}
    
    return response_dict
    
    
# In[secondary_function]
def aws_product_attrs_storage(prod_df, credentials, data_file, start_row=1, end_row=None, verbose=True):
    """
    Get attributes from get_product_attributes and store, looping through
    a list of ID's.
    
    prod_df = product series taken from dataframe
    credentials = a dictionary of credentials (see get_product_attributes doc)
    data_file = full path to file where data is stored
    start_row = where to start calling the api from
    end_row = where should I stop
    verbose = whether or not to print to the console after every request
    
    Function returns a dictionary with information on how many total products were
    returned, how many failed at one point, and how many total are in the data file.
    """    
    
    if not end_row:
        products = prod_df[start_row:]
    else:
        products = prod_df[start_row:end_row]
    
    worked = 0 # how many successful(ish)?
    not_worked = 0 # how many failed first?
    j = start_row # keep track of product row processed
    max_loops = len(prod_df) # don't want an infinite loop
    for product in products:
        while j < max_loops:
            try:
                sleep(1.15) # throttling method
                
                # call api with product id and credentials
                data_api = get_product_attributes(product, credentials) 
                
                # if the file already exists, open, and write a new line
                if os.path.exists(data_file):
                    with open(data_file, 'aw') as outfile:
                        outfile.write('\n')
                
                # open file (or create if doesn't exist) and dump json string in it
                with open(data_file, 'aw') as outfile:
                    simplejson.dump(data_api, outfile)
                
                # print results to console
                if verbose:
                    just_time = time.strftime('%x %X %z')
                    print "Product (%s) worked! %s have not worked: %s" % (j, not_worked, just_time)
                
                worked += 1# increment this as a successful run
                j += 1 # increment products row counter
            except:
                ''' 
                If the "try" doesn't succeed, then run this block which,
                keeps track of initial failures with "not_worked", prints to the console
                if desired. 
                
                Critical part of this block is that it continues with the same 
                Product ID in the "while" loop until it succeeds: that is, it 
                runs the "try" block again until it succeeds.
                
                Once it succeeds, it will break from the "while" loop and move on
                to the next product id
                '''
                not_worked += 1
                if verbose:
                    just_time = time.strftime('%x %X %z')
                    print "Product (%s) is trying again: %s" % (j, just_time)
                
                time_to_sleep = np.random.randint(30,46) # pause for a while after failure
                sleep(time_to_sleep) # pause 30-45 secs
                continue # 'try' again           
            break
    
    # number of products currently in data_file
    num_products_in_file = file_len(data_file)
    
    # return the number of total products successfully queried, 
    # number of failed attempts, and number of products in our data file
    dict_output = {"Processed": worked,
                   "Failed": not_worked,
                   "Num_in_File": num_products_in_file}
                   
                   
                   
    return dict_output