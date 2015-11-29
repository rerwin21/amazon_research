# load packages -------------------------------------------------------------
library(plyr)
library(dplyr)
library(lubridate)
library(tm)
library(SnowballC)
library(stringr)
library(snow)
library(parallel)
library(qdap)


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


# get string length
start <- Sys.time()
total_reviews$review_length <- total_reviews$text %>% 
  lapply(str_length) %>% 
  unlist()
(end <- Sys.time() - start)


# get word count using parallel computing
cl <- makeSOCKcluster(rep("localhost", 8))
start <- Sys.time()
wc_par <- parSapply(cl, total_reviews$text, word_count)
(end <- Sys.time() - start)


# add word count to total reviews
total_reviews$wc_review <- wc_par


# remove cluster, clear garbage and console
rm(cl, wc_par);gc();cat("\014")


# plot review length
# histogram of reviews


# avg review length over time


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



# stem and clean
start <- Sys.time()
rows <- sample(nrow(df), 2)
text <- laply(review_text[rows], sen_tok) %>% 
  unlist()
(end <- Sys.time() - start)
