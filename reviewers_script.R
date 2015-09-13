# get functions
setwd("C:/Users/Ryan/Dropbox/RACHEL_RYAN/3_Code/R")
source("reviewers.R")

# load the required packages
amazon_packages()


# time the process: takes around 8.4 minutes on my machine
start <- Sys.time()


# where do we want to start
pages <- "http://www.amazon.com/review/top-reviewers/ref=cm_cr_tr_link_2?ie=UTF8&page="


# grab Reviewer's review metrics
pages <- review_pages(pages, 1000)


# bind each data frame together: output should have 10,000 distinct url_names
pages <- bind_rows(pages)
  

# finish timer
end <- Sys.time() - start



# Convert numeric ---------------------------------
pages$Reviews <- pages$Reviews %>% 
  str_replace_all(",", "") %>% 
  as.numeric()


pages$Helpful_votes <- pages$Helpful_votes %>% 
  str_replace_all(",", "") %>% 
  as.numeric()


pages$X._helpful <- pages$X._helpful %>% 
  str_replace_all("%","") %>% 
  as.numeric() %>% 
  .[1]/100


# get the last page of reviews (estimated)
last_page <- last_page(pages$Reviews)
last_page <- data.frame(last_page = last_page)

# bind with pages
pages <- bind_cols(pages, last_page)
