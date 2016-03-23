# load packages -----------------------------------------------------------------------
aws_products_packages <- function() {
  suppressPackageStartupMessages({
    if(!(require(aws.signature))) {install.packages("aws.signature")
      library(aws.signature)}
    
    if(!(require(data.table))) {install.packages("data.table")
      library(data.table)}
    
    if(!(require(plyr))) {install.packages("plyr")
      library(plyr)}
    
    if(!(require(dplyr))) {install.packages("dplyr")
      library(dplyr)}
    
    if(!(require(stringr))) {install.packages("stringr")
      library(stringr)} 
    
    if(!(require(httr))) {install.packages("httr")
      library(httr)} 
    
    if(!(require(digest))) {install.packages("digest")
      library(digest)}
    
    if(!(require(RCurl))) {install.packages("RCurl")
      library(RCurl)}
    
    if(!(require(XML))) {install.packages("XML")
      library(XML)}
    
    if(!(require(jsonlite))) {install.packages("jsonlite")
      library(jsonlite)}
  })
}

# load the data -----------------------------------------------------------------------
load_products <- function(directory = getwd()) {
  
  # where is the data?
  if(directory == getwd()){
    path <- "products.csv"
  } else {
    path <- str_c(directory, "products.csv", sep = "/")
  }
  
  # use data.table's fread function (much quicker than base R)
  # do you have the right path specified
  tryCatch({
    products <- fread(path)
    return(products)
  },
  error = function(cond){
    mess <- message("You need to specify the path where the 'products.csv' file is located: \n
                    \t The default directory is the current working directory")
    cat(mess)
  })
}

# place holder for setting AWS credentials as environment variables -------------------
# No need to do this, a one time step I had to take
# Sys.setenv(acess_key = something,
#            secret_key = something_else,
#            default_region = south)

# clean the data ----------------------------------------------------------------------


# create a request string -------------------------------------------------------------
test_prod <- "B00THKEKEQ"


access_key <- "AKIAJHEL46A77AZQTR2A"
secret_key <- "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"
associate_tag <- "prodreview04c-20"
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
  "ItemId" = test_prod,
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

signature <- curlEscape(
  base64(
    hmac(enc2utf8((secret_key)), 
         enc2utf8(query), 
         algo = 'sha256', 
         serialize = FALSE,  
         raw = TRUE)
    )
  )


url <- str_c(endpoint, nvp, "&Signature=", signature)



get_test <- GET(url)

content_raw <- rawToChar(get_test$content)

content_clean <- xmlTreeParse(content_raw)

content_parsed <- xmlParse(content_raw)
content_df <- xmlToDataFrame(content_parsed)
content_list <- xmlToList(content_parsed)
content_json <- toJSON(content_list, simplifyVector = F)
json_pretty <- prettify(content_json)


# unsigned string ---------------------------------------------------------------------
# http://ecs.amazonaws.com/onca/xml?Service=AWSECommerceService
# &Version=2011-08-01
# &AssociateTag=prodreview04c-20
# &Operation=ItemLookup
# &ItemId=B00THKEKEQ
# &IdType=ASIN
# &ResponseGroup=ItemAttributes,SalesRank,RelatedItems
# &RelationshipType=AuthorityTitle,NewerVersion

# name value pairs --------------------------------------------------------------------
# Service=AWSECommerceService
# Version=2011-08-01
# AssociateTag=prodreview04c-20
# Operation=ItemLookup
# ItemId=B00THKEKEQ
# IdType=ASIN
# ResponseGroup=ItemAttributes,SalesRank,RelatedItems
# RelationshipType=AuthorityTitle,NewerVersion
# Timestamp=2016-03-22T20:16:53.000Z
# AWSAccessKeyId=AKIAJHEL46A77AZQTR2A