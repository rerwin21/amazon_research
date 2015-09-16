# Does Rvest outperform RCurl?

fun_rvest <- function(page) {
  
  start <- Sys.time()
  html <- html(page)   
  end <- Sys.time() - start
  
  review_links <- html %>% 
    html_nodes(xpath = "//tr[contains(@id, 'reviewer')]/*/div/a") %>% 
    html_attr("href") %>% 
    as.data.frame.character(stringsAsFactors = F) 

  return(list(review_links, end))
  
}


fun_RCurl <- function(page, handle) {
  
  start <- Sys.time()
  html <- getURL(url = page, curl = handle)
  html <- htmlParse(html)
  end <- Sys.time() - start
  
  time <- getCurlInfo(handle)
  time <- time$pretransfer.time
  
  review_links <- html %>% 
    html_nodes(xpath = "//tr[contains(@id, 'reviewer')]/*/div/a") %>% 
    html_attr("href") %>% 
    as.data.frame.character(stringsAsFactors = F) 
  
  return(list(review_links, end, time))
}



# url base
pages <- "http://www.amazon.com/review/top-reviewers/ref=cm_cr_tr_link_2?ie=UTF8&page="

# append the additional pages
pages <- paste(pages, seq_len(5), sep = "")

# get handler to be used for each request
handle <- getCurlHandle()

# Time both: rvest wins every time
system.time(rvest_fun <- lapply(pages, fun_rvest))
system.time(RCurl_fun <- lapply(pages, fun_RCurl, handle))

# check that each works
sapply(rvest_fun, `[[`, 2)
sapply(RCurl_fun, `[`, 2:3) %>% # actually what I want
  t() %>% 
  as.data.frame.matrix() %>% 
  setNames(c("Total_time", "Pretransfer_time"))
