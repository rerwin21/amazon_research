# -*- coding: utf-8 -*-
"""
Created on Tue Jun  7 13:29:31 2016

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


#%% define request
def page_request(link, session):
    page = session.get(link)
    if not page.ok:
        print "trying again"
        wait = np.random.randint(1, 6)
        sleep(wait)
        page_request(link, session)
    else:
        #return (page.text, page.ok, page.status_code)
        print page.ok
        

#%% define a function
def scrape_review_page(link, session, parser):
    link = "http://" + link
    page, ok = page_request(link, session)
    tree = etree.parse(StringIO.StringIO(page), parser)
    print link, ok
    num_review = tree.xpath(".//div[@class='small']/b/following-sibling::text()[1]")[0]
    rank = tree.xpath(".//div[@class='tiny' and @style='padding:3px 0 0 10px;']/text()[1]")[0]
    votes = tree.xpath(".//div[@class='tiny' and @style='padding:3px 0 0 10px;']/text()[2]")[0]
    reviewer = link.replace("http://www.amazon.com/gp/cdp/member-reviews/","")
    review_page_info = {'reviewer': reviewer.strip(),
                        'rank': rank.strip(),
                        'votes': votes.strip(),
                        'num_reviews': num_review.strip()}
                        
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