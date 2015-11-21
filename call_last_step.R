# where are my functions
setwd("C:/Users/Ryan/Dropbox/RACHEL_RYAN/2_Data/new_data")

indices <- seq(1, 20, by = 10)

for(i in indices){
  
  Sys.sleep(rexp(1, 5))
  
  index_df <- seq(from = i, 
                  to = i + 9)
  
  links <- review_links$URLs[index_df]
  users <- review_links$reviewer[index_df]
  
  
  test2 <- Map(get_page, 
               as.list(links), 
               as.list(users))
  
  
  test2 <- bind_rows(test2)
  
  file_name <- str_c(i,".csv")
  
  write.csv(test2, file_name, row.names = F)
}
  








