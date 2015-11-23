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
files <- dir(getwd(), pattern = "\\.csv")


# read them in, return as data.frame
review_large <- suppressWarnings(ldply(files, 
                                     read.csv, 
                                     stringsAsFactors = F)
                                 )


# filter down before saving back to disk
review_large_correct <- review_large %>% 
  filter(trouble == "correct")


# where to save the total list
setwd("C:/Users/Ryan/Dropbox/RACHEL_RYAN/2_Data")


# write to disk
write.csv(review_large_correct, 
          "total_reviews.csv", 
          row.names = F)
