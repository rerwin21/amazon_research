# -*- coding: utf-8 -*-
"""
@author: rerwin21
"""
"http://www.amazon.com/gp/cdp/member-reviews/A2HQ992IKSD8OM?ie=UTF8&display=public&page=1&sort_by=MostRecentReview"
#%% create links for all pages
# fastest   
def compr_list(revs):
    '''
    ids = reviewer id's
    revs = number of reviews for each reviewer id
    
    This function will use the number of reviews to create the links to each
    page of reviews for each reviewer. There are ten reviews per page (max).
    So, if a reviewer has 8 reviews, then they'll have one page to scrape. If
    they have 16, then they'll have two pages, so on....
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


#%% start a session


#%% set up HTML parser


#%%
# this function accepts the session and HTML parser as arguments and returns an
# etree. This function will create page and etree (see get_num_reviews_aws.py) and
# do the request error handling (try and excepts)


#%% accepts etree
# generate the links to scrape, each link has at most 10 reviews


#%% accepts etree
# function to get review text


#%% accepts etree
# function to get review rating


#%% accepts etree
# function to get price


#%% accepts etree
# function to get product ID


#%% accepts etree
# function to get review ID


#%% accepts etree
# function to get reviewer ID


#%% accepts etree
# bring it all together where 