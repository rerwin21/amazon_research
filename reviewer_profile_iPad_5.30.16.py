# -*- coding: utf-8 -*-
"""
Get Reviews from this product, B00746W9F2
First Part: gather reviewer profiles from the review pages of the iPad (ASIN above)
    -scrape the pages of review, 492 at the time, and gather all links from those pages
    -filter out the links for those that lead to reviewer profiles
    -save them in a file
Second Part: load the profile links and create review links
    -using pandas, load the text file created in step 1
    -create the links to the pages of reviews
        -each reviewer has a page of all their reviews, and more than one
         page if needed
"""


#%%
'''
First Part
'''


#%%
from bs4 import BeautifulSoup
from time import sleep
import requests

   
#%% get urls
# build the urls to be scraped for the iPad in order to get all the reviewer
# that left a review. At the time of this script, there were 492 pages of 
# reviews   
url_1 = "http://www.amazon.com/Apple-MD531LL-Wi-Fi-White-Silver/product-reviews/B00746W9F2/ref=cm_cr_getr_d_paging_btm_?"
url_2 = "ie=UTF8&linkCode=xm2&showViewpoints=1&sortBy=recent&tag=awsprojectfin-20&pageNumber="
urls = [url_1 + str(x) + url_2 + str(x) for x in xrange(1, 493)]


#%%
# using the urls built in the last step, loop through, get the HTML, get all
# links from the a tags, and store in a list
links = []
for url in urls:
    sleep(2)
    page = requests.get(url)
    page = page.text
    soup = BeautifulSoup(page, "lxml")
    lst = [link.get("href") for link in soup.find_all("a")]
    links.extend(lst)
    
     
#%%
# make sure it's not a NoneType and it is the link we're looking for...
# ... the reviewer profiles     
reviewer_links = ["www.amazon.com" + x
                  for x in links 
                  if x is not None and x.startswith("/gp/pdp/profile/")]
                  
                  
#%%
data_file = 'reviewer_profiles.txt'                  
with open(data_file, 'aw') as outfile:
    for link in reviewer_links:
        outfile.write("%s\n" % link)
        
#%%
'''
Second Part
'''


#%% import packages to load data
import pandas as pd
import os        


#%%        
data_path = "/home/rerwin21/amazon_proj"

# now us the os module to change the working directory
os.chdir(data_path)


#%%
# file name, located in the working directory
file_name = "reviewer_profiles.txt"


# use pandas to read in the data
reviewers = pd.read_csv(file_name,  header=None)

# original doesn't have 
reviewers.columns = ['profile_link']


#%%
# remove  rm_str and replace with replace_str and store in a new column
rm_str = "www.amazon.com/gp/pdp/profile/"
replace_str = "www.amazon.com/gp/cdp/member-reviews/"
reviewers['reviews_link'] = reviewers['profile_link'].replace(rm_str, replace_str, regex=True)


#%%
# save
reviewers.to_csv("iPad_reviewer_profiles_reviews.csv", index=False)    
