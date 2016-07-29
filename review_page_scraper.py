# -*- coding: utf-8 -*-
"""
@author: rerwin21
"""


# -----------------------------------------------------------------------------
#%% this section won't be in final version, just for testing
import re, os # needed for part that WILL be in final script
import pandas as pd
import numpy as np
import math # needed for part that WILL be in final script
from lxml import etree
import requests
import StringIO
from time import sleep
from requests.packages.urllib3.util.retry import Retry
from requests.adapters import HTTPAdapter


#%% change directory
#os.chdir("/home/rerwin21/amazon_proj/")


#%% load data, clean numbers, change index, and save num_reviews
#df = pd.read_csv("reviewer_info_total.csv")
#df.index = df.reviewer
#df = df[df["num_reviews"] != "Hmm"]


#%% clean text function
def clean_text(string):
    string = re.sub(":", "", string)
    string = string.strip()
    string = float(string)
    return string
    

#%% clean the num_reviews using function above
#df.loc[:, "num_reviews"] = df.loc[:, "num_reviews"].apply(clean_text)
#df.loc[:, "num_pages"] = df.loc[:, "num_reviews"].apply(lambda x: math.ceil(x / 10.)) # 10 reviews per page
#
#
##%% save num reviews as series (reviewer id is the index)
#revs = df.num_pages


#------------------------------------------------------------------------------
#%% create links for all pages
# fastest   
def compr_list(revs):
    '''
    ids = reviewer id's
    revs = number of reviews for each reviewer id
    
    This function will use the number of reviews to create the links to each
    page of reviews for each reviewer. There are ten reviews per page (max).
    So, if a reviewer has 8 reviews, then they'll have one page to scrape. If
    they have 16 reviews, then they'll have two pages, and so on....
    '''
    
    # use to build complete url
    url_1 = "http://www.amazon.com/gp/cdp/member-reviews/"
    url_2 = "?ie=UTF8&display=public&page="
    url_3 = "&sort_by=MostRecentReview"
    
    # list comprehension that loops though id, then creates another iterable
    # sequence using the number of reviews
    urls_compr = [url_1 + id_r + url_2 + str(x) + url_3
                  for id_r, page in revs.iteritems()
                  for x in xrange(1, int(page) + 1)]
    return urls_compr  


#%% creat function that takes number of servers and lenght of url list to create
# the list of tuples to be passed to the script on AWS
def start_finish_tuple(url_list, num_aws_inst):
    '''
    This function builds a list of tuples (start, end) which are passed to AWS
    instances. A file of urls is passed to the instance as well, and the tuple serves
    to filter the file to a subset. For example, (0, 11) will slice the first ten rows
    of the DataFrame, and only those url's will be scraped on that machine.
    
    url_list = list of urls to be scraped later
    
    num_aws_inst = number of AWS instances dedicated to the scraping job
    '''
    
    len_links = len(url_list)
    interval = float(len_links / num_aws_inst)
    interval = math.ceil(interval)
    interval = int(interval)
    inc = []
    for i in range(0, int(len_links), interval):
        start = i
        end = i + interval
        if end > len_links + 1:
            end = int(len_links + 1)
        inc.append((start, end))
    return inc


#%% won't be in final version -------------------------------------------------
#url_list = compr_list(revs)


#%% start a session
def start_session():
    '''
    This function starts a session, which is used to reuse connections, making future
    requests faster. Also, we can add an addapter with the mount call.
    '''
    
    session = requests.Session()
    retries = Retry(total=5, backoff_factor=1, status_forcelist=[502, 503, 504])
    session.mount('http://www.amazon.com', HTTPAdapter(max_retries=retries))
    return session


#%% set up HTML parser
def html_parser(encoding="utf-8"):
    '''
    This function tells etree which method and encoding to use when parsing the 
    requested HTML page.
    '''
    
    htmlparser = etree.HTMLParser(encoding=encoding)
    return htmlparser


#%%
# this function accepts the session and HTML parser as arguments and returns an
# etree. This function will create page and etree (see get_num_reviews_aws.py) and
# do the request error handling (try and excepts)
def scrape_review_page(link, session, parser, enumerated=None):
    
    '''
    This function takes in a link (to a page of reviews), a session, parser, and
    requests the page. Then, create an etree object to be traversed using loops
    and XPATH. Aside from the HTTP error handling, the primary reason for this 
    function is to call other functions, which take the etree as an argument and
    specific XPATH arguments for desired parts of the review page.
    
    link = url for a page of reviews (10 max)
    session = session used to maintain a connection between requests
    parser = let's etree know how to parse HTML
    enumerated = used to print progress of function; taken from the first item of
                 the output from enumerate(x)
    '''
    
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
    
    
    # check for status other than 2xx, if successful grab elements I want
    # otherwise grab the error and use as in input into the returned dict
    try:
        
        # request page and create a crawlable tree    
        page = session.get(link, timeout=5)
        tree = etree.parse(StringIO.StringIO(page.text), parser)        
        
        # raise status
        page.raise_for_status()
        
        # get review components
        ids = _get_review_id(tree)
        text = _get_review_text(tree)
        rating = _get_review_rating(tree) 
        dates = _get_review_date(tree)
        # call price function(etree, ids) consider dropping doens't look consistent
        # call product_id function(etree, ids)
                
    except requests.HTTPError as e: # seems to be most common error
       
        error_message = e.response.status_code
        error_message = ["Error: %s" % error_message] * 5
        review_id, text, rating, date, prod_id = error_message 
        
    except requests.ConnectionError as e: # just in case
        
        error_message = e.response.status_code
        error_message = ["Error: %s" % error_message] * 5
        review_id, text, rating, date, prod_id = error_message  
        
    except requests.URLRequired as e: # just in case
        
        error_message = e.response.status_code
        error_message = ["Error: %s" % error_message] * 5
        review_id, text, rating, date, prod_id = error_message 
        
    except requests.Timeout as e: # just in case
        
        error_message = e.response.status_code
        error_message = ["Error: %s" % error_message] * 5
        review_id, text, rating, date, prod_id = error_message 
        
    except requests.exceptions.RetryError as e:
        
        error_message = e.args
        error_message = str(error_message[0])
        
        if "too many 503" in error_message:
            error_message = "Too many Retries: 503"
        else:
            error_message = "Unknown error"
            
        error_message = ["Error: %s" % error_message] * 5
        review_id, text, rating, date, prod_id = error_message 
    
    
    # create dict which will be used to create a DataFrame later
    review_page_info = {'review_id': ids, 
                        'text': text, 
                        'rating': rating, 
                        'date': dates,
                        'prod_id': '',
                        'link': '', # might need to multiply how many based on num of review ids
                        } #
    
    # return the dict                    
    return review_page_info


#%% accepts etree
# function to get review ID
def _get_review_id(tree):
    '''
    The function takes an etree and will loop through the tree and find all (hopefully)
    review ID's on the given page, which the etree was created from. Returns a list of 
    review ID's.
    
    tree = etree.parse() object
    '''
    
    # the review ids are the value of the name attributes for 'a' tags
    ids = tree.xpath("//a[@name]/@name")
    
    if len(ids) == 0:
        ids = ["Page Failed"]
    
    return ids


#%% accepts etree
# function to get review text
def _get_review_text(tree):
    '''
    Grabs the most important part of the exercise, the review text.
    
    tree = etree.parse() object
    '''
    
    # review text appears in the div tags, where the class attribute is 'reviewText'    
    text = tree.xpath("//div[@class='reviewText']/text()")
    
    return text


#%% accepts etree
# function to get review rating
def _get_review_rating(tree):
    '''
    Grabs the review rating, which is based on a scale of 1-5. 1 is the lowest
    rating and 5 is the highest (best).
    
    tree = etree.parse() object
    '''
    
    # get the rating, which located in the title of an image
    rating = tree.xpath("//img[contains(@title, 'out of 5 stars')]/@title")
    
    if len(rating) != 0:
        rating = [re.sub(" out of 5 stars", "", rate) for rate in rating] # remove the text, keep rating
        rating = [float(rate) for rate in rating] # convert the ratings to float
    
    return rating


#%% accepts etree
# function to get date
def _get_review_date(tree):
    '''
    Grab the review date, which is located in the nobr tag
    
    tree = etree.parse() object
    '''
    
    dates = tree.xpath("//nobr/text()")
    
    return dates


#%% accepts etree
# function to get product ID
def _get_product_id(tree):
    '''
    Grabs the product id, asin, which we'll need to get the product attributes
    via API calls. The asin id is bundled in a URL that we'll need to get first,
    then use Regex patterns to get the id from the text
    
    tree = etree.parse() object
    '''
    
    # build the 
    style = 'padding-top: 10px; clear: both; width: 100%;'
    xpath = "//div[@style='%s']" % style
    xpath += "/a[1]/@href"
    prod_id = tree.xpath(xpath)
    
    if len(prod_id) != 0:
        pattern = re.compile("(?<=ASIN\=).*(?=\#wasThisHelpful)")
        prod_id = [pattern.match(url) for url in prod_id]



#%% accepts etree
# function to get reviewer ID




#%% accepts etree
# bring it all together where 



