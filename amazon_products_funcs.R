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

# get the signature for authentication ------------------------------------------------