# load packages -------------------------------------------------------------
library(plyr)
library(dplyr)
library(lubridate)
library(tm)
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


# define function for stemming and cleaning
