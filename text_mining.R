# load packages -------------------------------------------------------------
library(plyr)
library(dplyr)
library(lubridate)
library(tm)
library(SnowballC)
library(stringr)


# load the data -------------------------------------------------------------
setwd("C:/Users/Ryan/Dropbox/RACHEL_RYAN/2_Data")


# load
total_reviews <- read.csv("total_reviews_aws.csv", 
                          stringsAsFactors = F,
                          nrows = 10)


# get classes to use when loading
review_col_classes <- sapply(total_reviews, class)


# reload
start <- Sys.time()
total_reviews <- read.csv("total_reviews_aws.csv", 
                          stringsAsFactors = F,
                          colClasses = review_col_classes)
(end <- Sys.time() - start)

# change date
total_reviews$review_date <- ymd(total_reviews$review_date)


# define function for stemming and cleaning ---------------------------------
sen_tok <- function(sen){
  
  tok <- sen %>% 
    str_to_lower() %>% 
    removeWords(stopwords("en")) %>% 
    removePunctuation() %>% 
    str_to_lower() %>% 
    removeWords(stopwords("en")) %>% 
    str_split(" ") %>% 
    lapply(wordStem) %>% 
    lapply(function(x) str_c(x, collapse = " ")) %>% 
    unlist() %>% 
    removeWords(stopwords("en"))
  
  return(tok)
}


# get the reviews and remove the data frame due to memory constraints -------
review_text <- total_reviews$text
names(review_text) <- total_reviews$review_id # in case I need the review id

# remove anything except sentok function and review_text
rm(list = setdiff(ls(), c("review_text", "sen_tok")))


# garbage collection and clear console
gc();cat("\014")


# apply the function to the review text -------------------------------------
start <- Sys.time()
text <- lapply(review_text, sen_tok) %>% 
  unlist()
(end <- Sys.time() - start)