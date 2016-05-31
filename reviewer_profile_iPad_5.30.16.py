# -*- coding: utf-8 -*-
"""
Get Reviews from this product, B00746W9F2
"""

#%%
from bs4 import BeautifulSoup
from time import sleep
import requests

   
#%% get urls
url_1 = "http://www.amazon.com/Apple-MD531LL-Wi-Fi-White-Silver/product-reviews/B00746W9F2/ref=cm_cr_getr_d_paging_btm_?"
url_2 = "ie=UTF8&linkCode=xm2&showViewpoints=1&sortBy=recent&tag=awsprojectfin-20&pageNumber="
urls = [url_1 + str(x) + url_2 + str(x) for x in xrange(1, 493)]


#%%
links = []
for url in urls:
    sleep(2)
    page = requests.get(url)
    page = page.text
    soup = BeautifulSoup(page, "lxml")
    lst = [link.get("href") for link in soup.find_all("a")]
    links.extend(lst)
    
     
#%%
for x in links:
   if x is not None and x.startswith("/gp/pdp/profile/"):
       print "www.amazon.com" + x
   else:
       pass    
   
   
#%%   
reviewer_links = ["www.amazon.com" + x
                  for x in links 
                  if x is not None and x.startswith("/gp/pdp/profile/")]
                  
                  
#%%
data_file = 'reviewer_profiles.txt'                  
with open(data_file, 'aw') as outfile:
    for link in reviewer_links:
        outfile.write("%s\n" % link)