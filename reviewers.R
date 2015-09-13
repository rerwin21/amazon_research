# load required packages
amazon_packages <- function() {
 
  # dplyr for data frame manipulation
  if(require(dplyr) == F) {install.packages("dplyr")
    library(dplyr)}
  
  # for string manipulation and regex
  if(require(stringr) == F) {install.packages("stringr")
    library(stringr)}
  
  # html gathering and node selection
  if(require(rvest) == F) {install.packages("rvest")
    library(rvest)}
  
  if(require(RCurl) == F) {install.packages("RCurl")
    library(RCurl)}
  
  if(require(httr) == F) {install.packages("httr")
    library(httr)}
}


# grab html values: links, text, and attributes
review_href <- function(page, pause = .1) {
  
  # grab html
  html <- html(page)
                                           
  
  # get the href value
  review_links <- html %>% 
    html_nodes(xpath = "//tr[contains(@id, 'reviewer')]/*/div/a") %>% 
    html_attr("href") %>% 
    as.data.frame.character(stringsAsFactors = F)
  
  
  # name used for url building
  url_name <- html %>% 
    html_nodes(xpath = "//tr[contains(@id, 'reviewer')]/td[2]/a[2]") %>% 
    html_attr("name") %>% 
    as.data.frame.character(stringsAsFactors = F)
  
  
  # user name
  user_name <- html %>% 
    html_nodes(xpath = "//tr[contains(@id, 'reviewer')]/td[3]/a/b") %>% 
    html_text() %>% 
    as.data.frame.character(stringsAsFactors = F)
  
  
  # get number of reviews, votes, and % helpful
  metrics <- html %>% 
    html_nodes(xpath = "//tr[contains(@id, 'reviewer')]/td[contains(@class, 'crNum')]") %>% 
    html_text() %>% 
    matrix(nrow = 10, byrow = T) %>% 
    as.data.frame.matrix(stringsAsFactors = F)
  
  
  # rename the columns to meanful names
  colnames(metrics) <- c("Rank", "Reviews", "Helpful_votes", "%_helpful")
  
  
  # create a larger dataframe of all the values scraped
  # need to rename the columns first
  cols <- list(url_name = url_name,
               user_name = user_name,
               review_links = review_links)
  
  
  # rename the columns and bind them together
  cols <- Map(setNames, cols, names(cols)) %>% bind_cols()
  
  
  # bind everything now
  review_links <- bind_cols(cols, metrics)
  
  # pause
  Sys.sleep(pause)
  
  
  return(review_links)
}


# run through number of pages
review_pages <- function(url, pages) {
  
  # initialize list
  links <- vector(mode = "list", length = pages)
  
  
  # get the urls
  pages <- paste(url, 1:pages, sep = "")
  
  
  # grab the links
  links <- lapply(pages, review_href)
  
  
  return(links)
}


# create url for the review page
get_review_url <- function(user, page_num){
  
  url <- paste("http://www.amazon.com/gp/cdp/member-reviews/",
                user,
                "?ie=UTF8&display=public&page=",
                page_num,
                "&sort_by=MostRecentReview",
                sep = "")
  return(url)
}


# create all initial last page url's: estimation
last_page <- function(reviews){
  
  # starting page number
  page_num <- mapply(floor, reviews/10)

  return(page_num)
}

  
### Deprecated --------------------------------------------------------------
# get last page of reviews
# get_last_page <- function(end) {
# 
#   # grab the html
#   last_html <- html(end)
#     
#   
#   # find the last listed page number, and we'll use that  
#   last_page <- last_html %>% 
#     html_node(xpath = "//b[contains(text(),'Page:')]/a[last()]") %>% 
#     html_text() %>% 
#     as.numeric() %>% 
#     
#   
#   
#   return(last_page)
# }