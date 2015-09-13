# Amazon Research
Repo for Amazon's Top Reviewer prediction project

## Overview
This project will entail web scraping, text mining, and predictive models with the objective of predicting "Review" (y/n) and/or the rating (number of stars). This approach seeks to help sellers target the reviewers most likely to review their product with a high rating, which will also be seen as helpful to other shoppers.

### Data
The information to be analyzed must be scraped from Amazon.com's list of Top Reviewers. For example, we'll need to identify the top reviewers then gather reviews. For each review, we'll want the review text, rating, percent and absolute value of helpful votes, product, product metadata, and any user (Reviewer) information available.

### Method
As a first approximation, we'll apply the random forest algorithm (RF). I choose RF initially for out-of-box performance and relative ease of application. As the modeling progresses, the modelling approach will certainly evolve. The vast majority of programming will take place within the R language. 

### Storage and Computing
The ideal solution would involve the procurment of all reviews from all Top Reviewers. If this is achieved, the data set will become very large with respect to R's in-memory paradigm. Moreover, the nature of the data could pose a challenge to required design of traditional RDBMS's. As a result, MongoDB on a cloud service, such as AWS might be a potential solution. 

In addition, processing a data set of this size locally will strain computing resources. Thus, using a service like AWS EC2 could provide efficieny gains. Pricing will be a contraint as well as skill-set (configuring an AMI).

### Final Product
A score of each reviewer for a particular product that will represent the probability of a highly rated, helpful review. 
