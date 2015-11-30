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
library(ggplot2)


# load the data and review length: wc and char count ------------------------
setwd("C:/Users/Ryan/Dropbox/RACHEL_RYAN/2_Data")

start <- Sys.time()
# load
total_reviews <- read.csv("total_reviews_aws.csv", 
                          stringsAsFactors = F,
                          nrows = 10)


# get classes to use when loading
review_col_classes <- sapply(total_reviews, class)


# reload
total_reviews <- read.csv("total_reviews_aws.csv", 
                          stringsAsFactors = F,
                          colClasses = review_col_classes)


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
wc_par <- parSapply(cl, total_reviews$text, word_count)
(end <- Sys.time() - start)


# add word count to total reviews
total_reviews$wc_review <- wc_par


# remove cluster, clear garbage and console
rm(cl, wc_par);gc();cat("\014")


# define function for stemming and cleaning ---------------------------------
sen_tok <- function(sen){
  # load packages for parallel processing
  library(plyr)
  library(dplyr)
  library(lubridate)
  library(tm)
  library(SnowballC)
  library(stringr)
  library(snow)
  library(parallel)
  library(qdap)
  
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
  x_samp <- sample(100, 1)
  if(x_samp < 11) invisible(gc())
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
# get word count using parallel computing
cl <- makeSOCKcluster(rep("localhost", 8))
start <- Sys.time()
review_text_test <- parLapply(cl, review_text, sen_tok) %>% 
  unlist()
(end1 <- Sys.time() - start)

rm(cl, review_text);gc()


# reload all columns except for text ----------------------------------------
total_reviews <- read.csv("total_reviews_aws.csv",
                          stringsAsFactors = F,
                          nrows = 10)

# get the classes
col_classes <- sapply(total_reviews, class)
col_classes[1] <- "NULL"


# skip text field because I'm going to replace with it with the cleaned ...
# ... stemmed text field
total_reviews <- read.csv("total_reviews_aws.csv",
                          stringsAsFactors = F,
                          colClasses = col_classes)


# add the stemmed text and save to disk
total_reviews$text <- review_text_test


# rerrange for consistency
total_reviews <- total_reviews %>% 
  select(text, rating:review_length)


# plots of word count -------------------------------------------------------
# reload
setwd("C:/Users/Ryan/Dropbox/RACHEL_RYAN/2_Data")
total_reviews <- read.csv("total_reviews_stem.csv",
                          stringsAsFactors = F,
                          nrows = 10)


# get the classes
col_classes <- sapply(total_reviews, class)


# use classes to load
total_reviews <- read.csv("total_reviews_stem.csv",
                          stringsAsFactors = F,
                          colClasses = col_classes)


# convert date
total_reviews$review_date <- as.Date(ymd(total_reviews$review_date))


# histogram
ggplot(total_reviews, aes(x = wc_review)) +
  scale_x_log10() +
  geom_histogram(alpha = .9, 
                 binwidth = 0.05, 
                 fill = "tomato") +
  theme(panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(), 
        panel.background = element_blank(), 
        axis.line = element_line(colour = "black"),
        legend.position = "none") +
  labs(
    x = "Word Count", 
    y = "Total Reviews"
  ) +
  theme(text = element_text(size = 18))


# get average word count by day
wc_by_day <- total_reviews %>% 
  group_by(review_date) %>% 
  summarise(
    avg_wc = mean(wc_review, na.rm = T),
    avg_wc = round(avg_wc, 2)
  ) %>% 
  ungroup()


# timeseries
ggplot(wc_by_day, aes(review_date, avg_wc)) + 
  geom_line(size = 2, colour = "firebrick2") +
  geom_line(size = 0.01, colour = "snow1", alpha = 0.7) +
  xlab("") + 
  ylab("Avg_wc") +
  theme(panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(), 
        panel.background = element_blank(), 
        axis.line = element_line(colour = "black"),
        legend.position = "none") +
  theme(text = element_text(size = 18))


# review length and rating related? -----------------------------------------
# inputs in model
total_reviews <- total_reviews %>% 
  mutate(
    year = as.factor(year(review_date)),
    vid = as.factor(vid)
  )


# build model
rating_model <- lm(rating ~ wc_review + vid + year, 
                   data = total_reviews)


# get summary
mod_summary <- summary(rating_model)
