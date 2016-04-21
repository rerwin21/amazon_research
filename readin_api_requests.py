# -*- coding: utf-8 -*-
"""
This script defines a few functions and then uses them to parse JSON strings
into a dataframe, iterating through a file and appending row by row to the 
dataframe.

@author: rerwin21
"""


#%% import my libraries
import pandas as pd
import json


#%% where is my data?
data_file = '/home/rerwin21/amazon_proj/api_data/api_request_3.txt'


#%% dict function, taken and altered from StackOverflow to iinclude the 
# test for list
def extract(dict_in, dict_out, key2=''):
    for key, value in dict_in.iteritems():
        if isinstance(value, dict): # If value itself is dictionary
            if key2 != '': # did we pass the second key?
                key = '_'.join([key2, key]) # if so, concatenate the previous key (key2) with current (key)
            extract(value, dict_out, key) # call function recursively
        elif isinstance(value, list):
            for i, j in enumerate(value):
                if isinstance(j, dict):
                    extract(j, dict_out, key)    
                else:
                    if i == 0:
                        keys = key # if the first item in list, key remains the same        
                    else:
                        keys = '_'.join([key, str(i + 1)]) # otherwise, add the number of times it appears
                    dict_out[keys] = j # add value
                    count_key = '_'.join([key, 'count']) # get total count key     
                    dict_out[count_key] = len(value) # add total count
        else:
            if key2 != '': # make sure to account for keys passed from parent items
                key = '_'.join([key2, key])
            dict_out[key] = value
    return dict_out
     
     
#%%   
# use head as test file object   
def product_attributes(prod_json):
    attributes_flat = {}    
    product = json.loads(prod_json)
    # get the itam    
    if 'Item' in product['api_response']['ItemLookupResponse']['Items']:
        prod_item = product['api_response']['ItemLookupResponse']['Items']['Item']
        # get flattened item attributes
        attributes_flat = extract(prod_item['ItemAttributes'], {})
        if 'SalesRank' in prod_item: # make sure product has a SalesRank value
            attributes_flat['salesrank'] = prod_item['SalesRank']
    attributes_flat['prod_id'] = product['product_asin']
    return attributes_flat
    
    
#%% input to dataframe3
def prof_json_to_df(head):
    df_list = [product_attributes(prod_id) for prod_id in head]
    df_total = pd.DataFrame(df_list)
    return df_total

       
#%%
# get the first 100 products and put them in a list
with open(data_file) as myfile:
    head = [next(myfile) for x in xrange(100)]
    
    
#%% input to DataFrame  
# around 40x faster than previous version
prod_df2 = prof_json_to_df(head)


#%%
# just for consistency
prod_df2.index = prod_df2['prod_id']
    
    
#%% write to disk
# make sure to change the current directory
prod_df2.to_csv('api_request_100_v2.csv', index=False, encoding='utf-8')