# where are my functions ----------------------------------------------------
setwd("C:/Users/Ryan/Dropbox/RACHEL_RYAN/3_Code/R")
source("data_last_step.R")


# load reviews list ---------------------------------------------------------
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


# create the review links
review_links <- .create_links(reviewers$url_name,
                             reviewers$page_num)


# call and store the results ------------------------------------------------
setwd("C:/Users/Ryan/Dropbox/RACHEL_RYAN/2_Data/new_data")

start <- Sys.time()
indices <- seq(40001, 45000, by = 500)
times <- c(1:length(indices))
j <- 0

for(i in indices){
  start_loop <- Sys.time()
  Sys.sleep(rexp(1, 5))
  
  index_df <- seq(from = i, 
                  to = i + 499)
  
  links <- review_links$URLs[index_df]
  users <- review_links$reviewer[index_df]
  
  
  test2 <- Map(get_page, 
               as.list(links), 
               as.list(users))
  
  
  test2 <- bind_rows(test2)
  
  file_name <- str_c(i,".csv")
  
  write.csv(test2, file_name, row.names = F)
  rm(test2)
  
  end_loop <- Sys.time() - start_loop
  j <- j + 1
  times[j] <- end_loop
}
  
end <- Sys.time() - start


# load one master file and save ---------------------------------------------
# list the files
setwd("C:/Users/Ryan/Dropbox/RACHEL_RYAN/2_Data/data_aws")
files <- dir(getwd(), pattern = "\\.csv")

start <- Sys.time()
# read them in, return as data.frame
review_large <- suppressWarnings(ldply(files, 
                                     read.csv, 
                                     stringsAsFactors = F)
                                 )


# filter down before saving back to disk
review_large_correct <- review_large %>% 
  filter(trouble == "correct")


# look at review distribution
cust_rev <- review_large_correct %>% 
  group_by(reviewer) %>% 
  summarise(
    count = n()
  )


# rename
total_reviews <- review_large_correct


# rm everything except total reviews, just in case, clear garbage ...
# ... clear console, and get time
rm(list = setdiff(ls(), c("total_reviews", "start")))
gc()
cat("\014")
(end <- Sys.time() - start)


# ratings
total_reviews <- total_reviews %>% 
  mutate(
    rating = str_extract(rating, "\\d{1}\\.?\\d{1}"),
    rating = as.numeric(rating)
  )


# product ID
total_reviews <- total_reviews %>% 
  mutate(
    product_id = str_extract(product_id, 
                             "(?<=ASIN\\=).*(?=\\#wasThisHelpful)"),
    product_id = str_c(product_id, "remove after loading")
  )


# date
total_reviews <- total_reviews %>% 
  mutate(
    review_date = guess_formats(review_date, "Bdy") %>% 
      as.Date(review_date, format = .)
  )


# take only the unique reviews
total_reviews <- total_reviews %>% 
  distinct(review_id)


# take a quick look at a sample
total_reviews_sample <- total_reviews %>% 
  sample_n(100)


# unique products
unique_products <- unique(total_reviews$product_id)


# look at how many reviews over time of the top reviewers
reviews_by_date <- total_reviews %>% 
  group_by(review_date) %>% 
  summarise(
    review_count = n()
  )


# plot the results
plot(review_count ~ review_date, 
     reviews_by_date,
     pch = 20,
     col = rgb(red = 0.2, 
               green = 0.2, 
               blue = 0.5, 
               alpha = 0.5)
     )


# look at april 5, 2013
april_5_13 <- total_reviews %>% 
  filter(review_date == "2013-04-05")


# what product was most reviewed on this date
april_5_13_prod <- april_5_13 %>% 
  group_by(product_id) %>% 
  summarise(
    review_count = n(),
    reviewers = n_distinct(reviewer),
    avg_rating = mean(rating, na.rm = T) %>% 
      round(2)
  )


# load review list and see how many of the top reviewers were accounted for
setwd("C:/Users/Ryan/Dropbox/RACHEL_RYAN/2_Data")


# read file
reviewers <- read.csv("reviewers_list.csv", stringsAsFactors = F)


# grab the url for each person I'm assigned
reviewers <- reviewers %>% 
  filter(Reviews > 0)


# how many made the cut
reviewers_retrieved <- intersect(reviewers$url_name, total_reviews$reviewer) %>% 
  length()/nrow(reviewers)
reviewers_retrieved <- round(reviewers_retrieved, 2)


# who had the most reviews on any single day
most_reviews <- total_reviews %>% 
  group_by(reviewer, review_date) %>% 
  summarise(
    review_count = n()
  ) %>% 
  ungroup() %>% 
  filter(review_count == max(review_count))


# get the daily review statistics
most_reviews_daily <- total_reviews %>% 
  group_by(reviewer, review_date) %>% 
  summarise(
    review_count = n()
  ) %>% 
  ungroup()


# plot the results of daily review stats
ggplot(most_reviews_daily, aes(x = review_count)) +
  scale_x_log10() +
  geom_histogram(alpha = .8, 
                 binwidth = 0.075, 
                 fill = "slateblue") +
  geom_vline(data = most_reviews_daily, 
             aes(xintercept = mean(review_count)), 
             colour = "orange") +
  theme(panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(), 
        panel.background = element_blank(), 
        axis.line = element_line(colour = "black"),
        legend.position = "none") +
  labs(
    x = "Daily Review Count", 
    y = "Total Reviewers"
  ) +
  theme(text = element_text(size = 18))


# time series of daily reviews
ggplot(most_reviews_daily, aes(as.Date(review_date), review_count)) + 
  geom_line(aes(group = reviewer), alpha = 0.5) + 
  geom_smooth(aes(group = 1), 
              size = 1.5) +
  xlab("") + 
  ylab("Daily Reviews") +
  theme(panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(), 
        panel.background = element_blank(), 
        axis.line = element_line(colour = "black"),
        legend.position = "none") +
  theme(text = element_text(size = 18))


# get the total reviews for each reviewer
reviews_per_reviewer <- total_reviews %>% 
  group_by(reviewer) %>% 
  summarise(
    review_count = n()
  )


# join this with the number of reviews listed on the site
reviews_per_reviewer <- left_join(reviews_per_reviewer,
                                  reviewers[c("url_name", "Reviews")],
                                  by = c("reviewer" = "url_name"))


# create % scraped
reviews_per_reviewer <- reviews_per_reviewer %>% 
  mutate(
    perc_retrieved = review_count / Reviews,
    perc_retrieved = round(perc_retrieved, 2)
  )


# histogram for reviews per review
ggplot(reviews_per_reviewer, aes(x = review_count)) +
  scale_x_log10() +
  geom_histogram(alpha = .8, 
                 binwidth = 0.015, 
                 fill = "olivedrab3") +
  geom_vline(data = reviews_per_reviewer, 
             aes(xintercept = mean(review_count)), 
             colour = "orange") +
  theme(panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(), 
        panel.background = element_blank(), 
        axis.line = element_line(colour = "black"),
        legend.position = "none") +
  labs(
    x = "Review Count", 
    y = "Total Reviewers"
  ) +
  theme(text = element_text(size = 24))


# Clean text field ----------------------------------------------------------
# does the text field contain javascript
total_reviews <- total_reviews %>% 
  mutate(
    javascript = str_detect(text, "amznJQ.onReady")
  )


# take a quick look at a sample
total_reviews_sample <- total_reviews %>% 
  sample_n(100)


# filter only the those that contain javascript
total_reviews_javascript <- total_reviews %>% 
  filter(javascript) %>% 
  mutate(
    text = str_replace_all(text, ".*(?=\\}\\}\\)\\;\\}\\)\\;)", "") %>% 
      str_replace_all("(\\}\\}\\)\\;\\}\\)\\;)", "")
  )


# I want cleaned javascript text binded with rest of reviews
total_reviews <- total_reviews %>% 
  filter(!javascript) %>% 
  bind_rows(total_reviews_javascript)


# video, yes or no
start <- Sys.time()
total_reviews$vid <- sapply(total_reviews$text, 
                            str_detect, 
                            "\\d{1,2}:\\d{1,2}\\s?Mins")
(end <- Sys.time() - start)


# load again to do some plotting --------------------------------------------
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


# get the daily review statistics
most_reviews_daily <- total_reviews %>% 
  group_by(reviewer, review_date) %>% 
  summarise(
    review_count = n()
  ) %>% 
  ungroup()


# plot the results of daily review stats
ggplot(most_reviews_daily, aes(x = review_count)) +
  scale_x_log10() +
  geom_histogram(alpha = .8, 
                 binwidth = 0.075, 
                 fill = "slateblue") +
  geom_vline(data = most_reviews_daily, 
             aes(xintercept = mean(review_count)), 
             colour = "orange") +
  theme(panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(), 
        panel.background = element_blank(), 
        axis.line = element_line(colour = "black"),
        legend.position = "none") +
  labs(
    x = "Daily Review Count", 
    y = "Total Reviewers"
  ) +
  theme(text = element_text(size = 18))


# time series of daily reviews
p <- ggplot(most_reviews_daily, aes(as.Date(review_date), review_count)) + 
  geom_line(aes(group = reviewer), alpha = 0.1) + 
  xlab("") + 
  ylab("Daily Reviews") +
  theme(panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(), 
        panel.background = element_blank(), 
        axis.line = element_line(colour = "black"),
        legend.position = "none") +
  theme(text = element_text(size = 18))


# plot time series
p + stat_summary(fun.y = mean, geom = "line", colour = "red")


# get the monthly review statistics
most_reviews_month <- total_reviews %>% 
  mutate(
   year = year(review_date),
   month = month(review_date)
  ) %>% 
  group_by(reviewer, year, month) %>% 
  summarise(
    review_count = n()
  ) %>% 
  ungroup() %>% 
  mutate(
    yr_mo = paste(year, month, sep = "-")
  )


# time series of monthly reviews
p <- ggplot(most_reviews_month, aes(yr_mo, review_count)) + 
  geom_line(aes(group = reviewer), alpha = 0.1) + 
  xlab("") + 
  ylab("Monthly Reviews") +
  theme(panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(), 
        panel.background = element_blank(), 
        axis.line = element_line(colour = "black"),
        legend.position = "none") +
  theme(text = element_text(size = 18))


# plot time series
p + stat_summary(fun.y = mean, geom = "line", colour = "red")


# get the total reviews for each reviewer
reviews_per_reviewer <- total_reviews %>% 
  group_by(reviewer) %>% 
  summarise(
    review_count = n()
  )


# join this with the number of reviews listed on the site
reviews_per_reviewer <- left_join(reviews_per_reviewer,
                                  reviewers[c("url_name", "Reviews")],
                                  by = c("reviewer" = "url_name"))


# create % scraped
reviews_per_reviewer <- reviews_per_reviewer %>% 
  mutate(
    perc_retrieved = review_count / Reviews,
    perc_retrieved = round(perc_retrieved, 2)
  )


# histogram for reviews per review
ggplot(reviews_per_reviewer, aes(x = review_count)) +
  scale_x_log10() +
  geom_histogram(alpha = .8, 
                 binwidth = 0.015, 
                 fill = "olivedrab3") +
  geom_vline(data = reviews_per_reviewer, 
             aes(xintercept = mean(review_count)), 
             colour = "orange") +
  theme(panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(), 
        panel.background = element_blank(), 
        axis.line = element_line(colour = "black"),
        legend.position = "none") +
  labs(
    x = "Review Count", 
    y = "Total Reviewers"
  ) +
  theme(text = element_text(size = 24))


# get the unique products and save them to disk
products_reviewed <- total_reviews %>% 
  select(product_id) %>% 
  distinct()

