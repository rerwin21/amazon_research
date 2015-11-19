# load packages -------------------------------------------------------------
library(stringr)
library(lubridate)
library(plyr)
library(dplyr)
library(rvest)
library(httr)


# setwd ---------------------------------------------------------------------
setwd("C:/Users/Ryan/Dropbox/RACHEL_RYAN/2_Data")


# load the list of top reviewers --------------------------------------------
reviewers <- read.csv("reviewers_list.csv", stringsAsFactors = F)


# what page to scrape to for reviews
reviewers <- reviewers %>% 
  mutate(
    page_num = ceiling(Reviews/10),
    page_num = ifelse(page_num <= 10, page_num, 10)
  )


# grab the url for each person I'm assigned
reviewers <- reviewers %>% 
  filter(page_num > 0)


# grab the links and last page of each reviewer -----------------------------
# from the number above, decide the last page to peruse of reviews ...
# ... either 10 or floor(num reviews/10)
create_link <- function(user, page){
  
  pages <- seq.int(page)
  base_url <- "http://www.amazon.com/gp/cdp/member-reviews/"
  base_url <- str_c(base_url, user)
  base_url <- str_c(base_url, "?ie=UTF8&display=public&page=")
  base_url <- paste(base_url, pages, sep = "")
  base_url <- paste(base_url, "&sort_by=MostRecentReview", sep = "")
  
  return(base_url)
}


# using the page number and link function above, perform for all users
create_links <- function(users, pages) {
  
  # create list of pages to scrape for each person
  links <- Map(function(x, y) create_link(x, y),
               x = users,
               y = pages) %>% 
    unlist()
  
  # get the url names
  url_name <- Map(rep, users, pages) %>% 
    unlist()
  
  
  # create a data.frame
  links <- data.frame(URLs = links,
                      reviewer = url_name,
                      stringsAsFactors = F,
                      row.names = NULL)
  
  # return the data.frame
  return(links)
}


# create the review links
review_links <- create_links(reviewers$url_name,
                             reviewers$page_num)


# Review Text ---------------------------------------------------------------
review_text <- function(link) {
  
  # pause to mitigate rate limit
  pause <- runif(1, 0, 1.5)
  
  
  # sleep
  Sys.sleep(pause)

  
  # read html
  # html <- read_html(httr::GET(link, use_proxy("218.200.66.196", 8080)))
  html <- read_html(link)
  
  # grab the text
  text <- html %>% 
    html_nodes(xpath = "//div[@class = 'reviewText']") %>% 
    html_text()
  
  
  # clean up the text if it contains javascript
  
  
  
  # return text
  return(text)
}


# grab the html doc and parse the text
text_reviews_1000 <- lapply(review_links$URLs[4001:4100], 
                            review_text)


# unlist the reviews
text_reviews_1000 <- unlist(text_reviews_1000)


# create data frame for storage
text_reviews_1000 <- data.frame(reviews = text_reviews_100,
                                stringsAsFactors = F,
                                row.names = NULL)


# write to disk
write.csv(text_reviews_1000, 
          "review_4100.csv", 
          row.names = F)


# Review Rating


# review Date


# review price


# review product id


# picture: Y/N


# video: Y/N


# Gather the product information with these functions -----------------------
# product ID div id="averageCustomerReviews" data-asin' is the key here


# product hierarchy


# product name


# product price


# product discount