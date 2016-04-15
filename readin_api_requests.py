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
            if key2 != '':
                key = '_'.join([key2, key])
            extract(value, dict_out, key)
        elif isinstance(value, list):
            for i, j in enumerate(value):
                if isinstance(j, dict):
                    extract(j, dict_out, key)    
                else:
                    if i == 0:
                        keys = key        
                    else:
                        keys = '_'.join([key, str(i + 1)])        
                    dict_out[keys] = j
                    count_key = '_'.join([key, 'count'])    
                    dict_out[count_key] = len(value)
        else:
            if key2 != '':
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
 
        if 'SalesRank' in prod_item:
            attributes_flat['salesrank'] = prod_item['SalesRank']
  
    attributes_flat['prod_id'] = product['product_asin']
    
    df = pd.DataFrame(attributes_flat, index=[product['product_asin']])    
    return df
    
    
#%%
# get the first 100 products and put them in a list
with open(data_file) as myfile:
    head = [next(myfile) for x in xrange(101)]
    
    
#%% input to DataFrame
prod_df = pd.DataFrame()
for prod in head:
    df = product_attributes(prod)
    prod_df = prod_df.append(df)            
    
    
#%% write to disk
# make sure to change the current directory
prod_df.to_csv('api_request_100_v2.csv', index=False, encoding='utf-8')