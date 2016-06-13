# -*- coding: utf-8 -*-
"""
Created on Sat Jun 11 12:28:23 2016

@author: rerwin21
"""

# -*- coding: utf-8 -*-
"""
@author: rerwin21
"""

#%% import modules
import pandas as pd
import numpy as np
from lxml import etree
import requests
import StringIO
import re
from time import sleep
from requests.packages.urllib3.util.retry import Retry
from requests.adapters import HTTPAdapter


#%%
start_row = int(raw_input("Start row: "))
end_row = int(raw_input("End row: "))


#%% load data, reviewer links
review_links = pd.read_csv("iPad_reviewer_profiles_reviews.csv")
    

#%% create a reviewer id
repl_str = "www.amazon.com/gp/pdp/profile/"
review_links['reviewer'] = review_links['profile_link'].replace(repl_str, "", regex=True)
review_links = review_links.ix[start_row:end_row]


#%% start a session
session = requests.Session()
retries = Retry(total=5, backoff_factor=1, status_forcelist=[502, 503, 504])
session.mount('http://www.amazon.com', HTTPAdapter(max_retries=retries))


#%% set up HTML parser
htmlparser = etree.HTMLParser(encoding="utf-8")


#%% define a function
def scrape_review_page(link, session, parser, enumerated=None):
    
    # print sequence
    if enumerated is not None:
        print enumerated
    
    # add random throttling measure
    exp_scale = np.random.randint(1, 3)
    exp_num = np.random.exponential(exp_scale)
    sleep(exp_num)
    
    # does the link already have prefix?
    if not link.startswith("http://"):
        link = "http://" + link
    
    
    # define xpath predicates to be used later
    num_review_xpath = ".//div[@class='small']/b/following-sibling::text()[1]"   
    rank_xpath = ".//div[@class='tiny' and @style='padding:3px 0 0 10px;']/text()[1]"
    votes_xpath = ".//div[@class='tiny' and @style='padding:3px 0 0 10px;']/text()[2]"
    
    # check for status other than 2xx, if successful grab elements I want
    # otherwise grab the error and use as in input into the returned dict
    try:
        
        # request page and create a crawlable tree    
        page = session.get(link, timeout=5)
        tree = etree.parse(StringIO.StringIO(page.text), parser)        
        
        # raise status
        page.raise_for_status()
        
        num_review = tree.xpath(num_review_xpath)[0]
        rank = tree.xpath(rank_xpath)[0]
        votes = tree.xpath(votes_xpath)[0]
                
    except requests.HTTPError as e: # seems to be most common error
       
        error_message = e.response.status_code
        error_message = ["Error: %s" % error_message] * 3
        num_review, rank, votes = error_message 
        
    except requests.ConnectionError as e: # just in case
        
        error_message = e.response.status_code
        error_message = ["Error: %s" % error_message] * 3
        num_review, rank, votes = error_message 
        
    except requests.URLRequired as e: # just in case
        
        error_message = e.response.status_code
        error_message = ["Error: %s" % error_message] * 3
        num_review, rank, votes = error_message
        
    except requests.Timeout as e: # just in case
        
        error_message = e.response.status_code
        error_message = ["Error: %s" % error_message] * 3
        num_review, rank, votes = error_message
        
    except requests.exceptions.RetryError as e:
        
        error_message = e.args
        error_message = str(error_message[0])
        
        if "too many 503" in error_message:
            error_message = "Too many Retries: 503"
        else:
            error_message = "Unknown error"
            
        error_message = ["Error: %s" % error_message] * 3
        num_review, rank, votes = error_message
        
    except IndexError:
        
        error_message_1 = ["Hmm"] * 3
        num_review, rank, votes = error_message_1
    
    # grab only the reviewer ID from the URL (link)
    repl_str = "http://www.amazon.com/gp/cdp/member-reviews/"    
    reviewer = link.replace(repl_str, "")
    
    # create dict which will be used to create a DataFrame later
    review_page_info = {'reviewer': reviewer,
                        'rank': rank,
                        'votes': votes,
                        'num_reviews': num_review}
    
    # return the dict                    
    return review_page_info
    

#%%
test_lst = [scrape_review_page(link, session, htmlparser, num) 
            for num, link in enumerate(review_links['reviews_link'])]



#%%
df = pd.DataFrame(test_lst)
    

#%%
def clean_text(string):
    string = re.sub(u'\xa0', u' ', string)
    string = string.strip()
    return string


#%%
df = df.applymap(clean_text)


#%%
file_name = "scraped_pages_%s_%s.csv" % (start_row, end_row)
df.to_csv(file_name, index=True) 