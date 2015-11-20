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


# Reviews -------------------------------------------------------------------
# review text
.get_review_text <- function(html) {
  
  # grab the text
  text <- html %>% 
    html_nodes(xpath = "//div[@class = 'reviewText']") %>% 
    html_text()
  
  
  # return text
  return(text)
}


# review rating
.get_review_rating <- function(html){
  
  # grab rating
  rating <- html %>% 
    html_nodes(xpath = "//img[contains(@title, 'out of')]") %>% 
    html_attr("title")
  
  
  # return the review rating
  return(rating)
}


# review Date
.get_review_date <- function(html){
  
  # get the date of review
  date <- html %>% 
    html_nodes("nobr") %>% 
    html_text()
  
  
  # return the review rating
  return(date)
}


# review price
.get_review_price <- function(html){
  
  # grab the product price as listed in the review
  price <- html %>% 
    html_nodes(xpath = "//span[@class='price']/b") %>% 
    html_text()
  
  
  # return the product price
  return(price)
} 


# review product id
.get_review_pid <- function(html){
  
  # defin the xpath: where is the information located ...
  # ... in the htlm doc?
  xpath <- "'padding-top: 10px; clear: both; width: 100%;'" %>% 
    str_c("//div[@style=", ., "]/a[1]", sep = "")

  
  # get the product id as listed in the review
  p_id <- html %>% 
    html_nodes(xpath = xpath) %>% 
    html_attr("href")
  
  
  # return the product id
  return(p_id)
}


# picture: Y/N
# not worth the effort
  

# video: Y/N
# will use text to detect


# Gather the product information with these functions -----------------------
# product ID div id="averageCustomerReviews" data-asin' is the key here


# product hierarchy


# product name


# product price


# product discount


# primary function ----------------------------------------------------------
get_page <- function(link , user){
  
  # parse get the html doc from the link provided
  try({
    html_z <- read_html(links)
  }, 
  silent = T)
  
}