# load packages -------------------------------------------------------------
library(stringr)
library(lubridate)
library(plyr)
library(dplyr)
library(rvest)
library(httr)
library(ggplot2)


# grab the links and last page of each reviewer -----------------------------
# from the number above, decide the last page to peruse of reviews ...
# ... either 10 or floor(num reviews/10)
.create_link <- function(user, page){
  
  pages <- seq.int(page)
  base_url <- "http://www.amazon.com/gp/cdp/member-reviews/"
  base_url <- str_c(base_url, user)
  base_url <- str_c(base_url, "?ie=UTF8&display=public&page=")
  base_url <- paste(base_url, pages, sep = "")
  base_url <- paste(base_url, "&sort_by=MostRecentReview", sep = "")
  
  return(base_url)
}


# using the page number and link function above, perform for all users
.create_links <- function(users, pages) {
  
  # create list of pages to scrape for each person
  links <- Map(function(x, y) .create_link(x, y),
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


# Reviews -------------------------------------------------------------------
# review text
.get_review_text <- function(html) {
  
  # grab the text
  text <- html %>% 
    html_nodes(xpath = "//div[@class = 'reviewText']") %>% 
    html_text()
  
  
  # video javascript garbage?
  JS <- str_detect(text, "amznJQ.onReady")
  
  
  # have the Length:: element?
  v_length <- str_detect(text, "Length::")
  
  
  # js text with length
  js_text <- text[JS & v_length] %>% 
    str_replace_all("\\n", "") %>% 
    str_split("Length::") %>% 
    sapply(`[[`, 2)
  
  
  # js text with no length
  text <- str_replace_all(text, 
                          "\\n",
                          "")
  
  
  # piec text back together
  clean_text <- ifelse(JS & v_length, js_text, text)
  
  
  # return text
  return(clean_text)
}


# review rating
.get_review_rating <- function(html){
  
  # create xpaths
  xpath <- "//span[@style='margin-left: -5px;']/img"
  
  
  # grab rating
  rating <- html %>% 
    html_nodes(xpath = xpath) %>% 
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


# review id
.get_review_id <- function(html){
  
  # define xpath
  xpath <- "//td[@colspan='7' and @align='left' and @class='small']" %>% 
    str_c("/a[1]")
  
  
  # get the review id
  review_id <- html %>% 
    html_nodes(xpath = xpath) %>% 
    html_attr("name")
  
  
  # return the review id
  return(review_id)
}


# Gather the product information with these functions -----------------------
# product ID div id="averageCustomerReviews" data-asin' is the key here


# product hierarchy


# product name


# product price


# product discount


# primary function for review page ------------------------------------------
get_page <- function(link , user){
  
  # rate throttle timer
  pause <- runif(1, 0, .75)
  
  
  # sleep system
  Sys.sleep(pause)
  
  
  # parse get the html doc from the link provided
  try({
    html <- read_html(link)
  }, 
  silent = T)
  
  
  
  # create list of review components
  review_components <- tryCatch(
    {
      text <- .get_review_text(html)
      rating <- .get_review_rating(html)
      date <- .get_review_date(html)
      p_id <- .get_review_pid(html)
      id <- .get_review_id(html)
      
      comps <- list(text = text, 
                    rating = rating, 
                    date = date, 
                    p_id = p_id,
                    id = id)
    }, 
    error = function(cond){
      
      text <- character(0)
      rating <- character(0)
      date <- character(0)
      p_id <- character(0)
      id <- character(0)
      
      comps <- list(text = text, 
                    rating = rating, 
                    date = date, 
                    p_id = p_id,
                    id = id)
      
      return(comps)
    },
    warning = function(cond){
      
    }
  )
  
  
  # get length of each component
  i_length <- sapply(review_components, length)
  
  
  # how many reviews should I have
  n_reviews <- i_length  %>% 
    max()
  
  
  # are they all the same length?
  complete_reviews <- i_length %>% 
    all(. == n_reviews)
  
  
  # are we banned, indicated by empty components
  banned <- length(i_length[i_length == 0]) > 1
  
  text <- review_components$text
  rating <- review_components$rating
  date <- review_components$date
  p_id <- review_components$p_id
  id <- review_components$id
  
  
  # create the data frame we'll use later
  tryCatch(
    {
      df <- data.frame(text = text,
                       rating = rating,
                       review_date = date,
                       product_id = p_id,
                       review_id = id,
                       reviewer = user,
                       review_page = link,
                       trouble = "correct",
                       stringsAsFactors = F
      )
      
      
      # return the succesful data frame
      return(df)
    },
    error = function(cond) {
      
      # why did we get the error
      if(banned){
        banned <- "banned"
      } else {
        banned <- "diff_length"
      }
      
      
      # create the contents of failed data frame
      e_rror <- c(i_length["text"],
                  i_length["rating"],
                  i_length["date"],
                  i_length["p_id"],
                  i_length["id"],
                  user, 
                  link, 
                  banned)
      
      
      # convert contents to dataframe
      df <- data.frame(t(e_rror),
                       stringsAsFactors = F)
      
      
      # rename to same names as succesful data frame
      colnames(df) <- c("text", 
                        "rating", 
                        "review_date", 
                        "product_id", 
                        "review_id", 
                        "reviewer", 
                        "review_page",
                        "trouble")
      
      
      # return unsuccessful data and appropriate error: ...
      # ... either banned or lengths of the attempted components
      return(df)
    },
    warning = function(cond) {
      message(paste("URL caused a warning:", link))
      
    }
  )  
}