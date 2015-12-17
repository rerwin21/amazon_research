# load the required packages ------------------------------------------------
library(httr)
library(jsonlite)
library(lubridate)
library(plyr)
library(dplyr)
library(digest)
library(stringr)
library(RCurl)
library(data.table)
library(XML)


# where is my data
setwd("C:/Users/Ryan/Dropbox/RACHEL_RYAN/2_Data")

products_reviewed <- read.csv("products_reviewed.csv",
                              stringsAsFactors = F)

# remove string that protects leading zeros
products_reviewed$product_id <- products_reviewed$product_id %>% 
  str_replace_all("remove after loading", "")

# test product
test_prod <- products_reviewed$product_id[1]


access_key <- "AWS Access Key here"
secret_key <- "Secret Key here"
associate_tag <- "Associate ID here"
time_stamp <- as.POSIXlt(Sys.time(), tz = "UTC") %>% 
  as.character() %>% 
  str_replace(" ", "T") %>% 
  str_c("Z")


# end point
endpoint <- "http://ecs.amazonaws.com/onca/xml?"



nvp <- list(                                
  "Service" = "AWSECommerceService",
  "AssociateTag" = associate_tag,
  "Operation" = "ItemLookup",
  "Timestamp" = time_stamp,
  "AWSAccessKeyId" = access_key,
  "ItemID" = "B00008OE6I",
  "IdType" = "ASIN",
  "ResponseGroup" = "ItemAttributes"
)


bytes <- function(chr){
  as.data.frame(t(as.numeric(charToRaw(chr))))
}


b <- lapply(names(nvp), bytes)
b <- data.table::rbindlist(b, fill=TRUE)


nvp <- nvp[do.call(order, as.list(b))]
nvp <- sapply(nvp, URLencode, reserved = T)
nvp <- paste0(names(unlist(nvp)), "=",unlist(nvp))
nvp <- str_c(nvp, collapse = "&") %>% URLencode()

sign_begin <- "GET\necs.amazonaws.com\n/onca/xml"

query <- str_c(sign_begin, nvp, sep = "\n")

signature_api <- hmac(secret_key, query, "sha256")

url <- str_c(endpoint, nvp, "&Signature=", signature_api)

get_test <- GET(url)

get_test$content %>% rawToChar()

content_raw <- rawToChar(get_test$content)

content_clean <- xmlTreeParse(content_raw)



# https://associates-amazon.s3.amazonaws.com/signed-requests/helper/index.html
# this is the input
# http://ecs.amazonaws.com/onca/xml?Service=AWSECommerceService
# &AssociateTag=prodreview04c-20
# &Operation=ItemLookup
# &Timestamp=2015-12-02T23:53:43Z
# &AWSAccessKeyId=[acces_key]
# &ItemId=B00008OE6I
# &IdType=ASIN
# &ResponseGroup=ItemAttributes



# use this to make sure I can get the same signature
curlEscape(
  base64(hmac(enc2utf8((secret_key)), 
                       enc2utf8(string_to_sign), 
                       algo = 'sha256', 
                       serialize = FALSE,  
                       raw = TRUE))
  )
