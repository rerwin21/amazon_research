# -*- coding: utf-8 -*-
"""
@author: rerwin21
"""

#%% import modules
import os
import pandas as pd
import numpy as np
from lxml import etree
from time import sleep
import requests
import StringIO
from requests.packages.urllib3.util.retry import Retry
from requests.adapters import HTTPAdapter


#%% change path to location of source data
os.chdir("/home/rerwin21/amazon_proj/")


#%% set up HTML parser
htmlparser = etree.HTMLParser(encoding="utf-8")


#%% load data, reviewer links
review_links = pd.read_csv("iPad_reviewer_profiles_reviews.csv")


#%% read in one page, find out how to grab the number of pages
rand_page_index = np.random.randint(0, len(review_links))
review_page = review_links.ix[rand_page_index, 'reviews_link']


#%% start a session
session = requests.Session()
retries = Retry(total=5,    
                backoff_factor=0.1)

session.mount('http://www.amazon.com', HTTPAdapter(max_retries=retries))


#%% define request
def page_request(link, session):
    page = session.get(link)
    return (page.text, page.ok)
        

#%% define a function
def scrape_review_page(link, session, parser):
    link = "http://" + link
    page, ok = page_request(link, session)
    tree = etree.parse(StringIO.StringIO(page), parser)
    print "%s: %s" % (link, ok)
    
    try:
        num_review = tree.xpath(".//div[@class='small']/b/following-sibling::text()[1]")[0]
        rank = tree.xpath(".//div[@class='tiny' and @style='padding:3px 0 0 10px;']/text()[1]")[0]
        votes = tree.xpath(".//div[@class='tiny' and @style='padding:3px 0 0 10px;']/text()[2]")[0]
    except:
        error_message = ["Didn't work"] * 3
        num_review, rank, votes = error_message 
        
    reviewer = link.replace("http://www.amazon.com/gp/cdp/member-reviews/","")
    review_page_info = {'reviewer': reviewer,
                        'rank': rank,
                        'votes': votes,
                        'num_reviews': num_review}
                        
    return review_page_info
    
    

#%%
test_lst = [scrape_review_page(link, session, htmlparser) 
            for link in review_links['reviews_link']]










#%%
pages = review_links.ix[[100,200], 'reviews_link']

test_lst = [scrape_review_page(link, session, htmlparser) 
            for link in pages]
                
test_df = pd.DataFrame(test_lst)

test_df.replace(u'\xa0', u' ', regex=True, inplace=True)