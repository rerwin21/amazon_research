# -*- coding: utf-8 -*-
"""
@author: rerwin21
"""
#%%
import re
import numpy as np
import math 
from lxml import etree
import requests
import StringIO
from time import sleep
from requests.packages.urllib3.util.retry import Retry
from requests.adapters import HTTPAdapter

    
#%%
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


#%%
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


#%%
def start_session():
    '''
    This function starts a session, which is used to reuse connections, making future
    requests faster. Also, we can add an addapter with the mount call.
    '''
    
    session = requests.Session()
    retries = Retry(total=5, backoff_factor=1, status_forcelist=[502, 503, 504])
    session.mount('http://www.amazon.com', HTTPAdapter(max_retries=retries))
    return session


#%%
def html_parser(encoding="utf-8"):
    '''
    This function tells etree which method and encoding to use when parsing the 
    requested HTML page.
    '''
    
    htmlparser = etree.HTMLParser(encoding=encoding)
    return htmlparser


#%%
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
    
    # links, updated later if needed
    links = [link]
    
    # check for status other than 2xx, if successful grab elements I want
    # otherwise grab the error and use as in input into the returned dict
    try:
        
        # request page and create a crawlable tree    
        page = session.get(link, timeout=5)
        tree = etree.parse(StringIO.StringIO(page.text), parser)        
        
        # raise status
        page.raise_for_status()
        
        # get review components
        review_id = _get_review_id(tree)
        
        if "Page Failed" not in review_id:
            text = _get_review_text(tree)
            rating = _get_review_rating(tree) 
            date = _get_review_date(tree)
            review_url, prod_id = _get_product_id(tree)
        else:
            review_id, text, rating, date, prod_id, review_url = ["Page Failed"] * 6
            
        # to keep track of what came from where
        links = [link] * len(review_id)
    
    except requests.HTTPError as e: # seems to be most common error
       
        error_message = e.response.status_code
        error_message = ["Error: %s" % error_message] * 6
        review_id, text, rating, date, prod_id, review_url = error_message 
        
    except requests.ConnectionError as e: # just in case
        
        error_message = e.response.status_code
        error_message = ["Error: %s" % error_message] * 6
        review_id, text, rating, date, prod_id, review_url = error_message   
        
    except requests.URLRequired as e: # just in case
        
        error_message = e.response.status_code
        error_message = ["Error: %s" % error_message] * 6
        review_id, text, rating, date, prod_id, review_url = error_message  
        
    except requests.Timeout as e: # just in case
        
        error_message = e.response.status_code
        error_message = ["Error: %s" % error_message] * 6
        review_id, text, rating, date, prod_id, review_url = error_message  
        
    except requests.exceptions.RetryError as e:
        
        error_message = e.args
        error_message = str(error_message[0])
        
        if "too many 503" in error_message:
            error_message = "Too many Retries: 503"
        else:
            error_message = "Unknown error"
            
        error_message = ["Error: %s" % error_message] * 6
        review_id, text, rating, date, prod_id, review_url = error_message 
    
    
    # create dict which will be used to create a DataFrame later
    review_page_info = {'review_id': review_id, 
                        'text': text, 
                        'rating': rating, 
                        'date': date,
                        'prod_id': prod_id,
                        'prod_url': review_url,
                        'link': links, 
                        } 
                        
    return review_page_info


#%%
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


#%%
def _get_review_text(tree):
    '''
    Grabs the most important part of the exercise, the review text.
    
    tree = etree.parse() object
    '''
    
    # review text appears in the div tags, where the class attribute is 'reviewText'    
    text = tree.xpath("//div[@class='reviewText']/text()")
    return text


#%%
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


#%%
def _get_review_date(tree):
    '''
    Grab the review date, which is located in the nobr tag
    
    tree = etree.parse() object
    '''
    dates = tree.xpath("//nobr/text()")
    return dates


#%%
def _get_product_id(tree):
    '''
    Grabs the product id, asin, which we'll need to get the product attributes
    via API calls. The asin id is bundled in a URL that we'll need to get first,
    then use Regex patterns to get the id from the text
    
    tree = etree.parse() object
    '''
    
    # located at the end of the first
    xpath = "//span[@class='h3color tiny']//following-sibling::a[1]/@href"
    ids = tree.xpath(xpath)
    
    if len(ids) != 0:
        pattern = re.compile("(?<=/dp/)(\w+)")
        prod_ids = [pattern.findall(url)[0] for url in ids]
    else:
        prod_ids = []
    return ids, prod_ids