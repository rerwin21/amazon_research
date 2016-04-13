# -*- coding: utf-8 -*-
"""
Created on Wed Apr 13 13:17:51 2016

@author: rerwin21
"""


#%% import my libraries
import pandas as pd
import numpy as np
import os
import json


#%% where is my data?
data_file = '/home/rerwin21/amazon_proj/api_data/api_request_3.txt'

with open(data_file) as api_data:
    first_line = api_data.readline()
    

#%% load json string as python object

product = json.loads(first_line)


#%% dict function, taken and altered slightly from StackOverflow
def extract(dict_in, dict_out):
    for key, value in dict_in.iteritems():
        if isinstance(value, dict): # If value itself is dictionary
            extract(value, dict_out)
        else:
            # Write to dict_out
            dict_out[key] = value
    return dict_out

    
#%% notes to parse the JSON

# gets the actual item (none of the garbage)
prod_item = product['api_response']['ItemLookupResponse']['Items']['Item']

# get the item attributes
prod_item['ItemAttributes']

# get sales rank
prod_item['SalesRank']


# or just get the values for each key using the function above
empty_dict = {} # for the function
product_all_keyvals = extract(product, empty_dict)