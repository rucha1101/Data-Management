# Load required libraries
library(dplyr)

setwd("/cloud/project/data_upload/")
# Load CSV files into data frames
customers <- read.csv("Customers.csv")
shipment <- read.csv("shipment.csv")
suppliers <- read.csv("suppliers.csv")
categories <- read.csv("categories.csv")
products <- read.csv("products.csv")
reviews <- read.csv("reviews.csv")
transaction_detail <- read.csv("transactiondetails.csv")

# Cross-Table Consistency Checks

# 1. Validate that product IDs referenced in the categories table exist in the products table
invalid_product_ids <- categories %>%
  filter(!product_id %in% products$product_id) %>%
  select(product_id)

if (nrow(invalid_product_ids) > 0) {
  cat("Invalid Product IDs in Categories Table:", unique(invalid_product_ids$product_id), "\n")
} else {
  cat("All Product IDs in Categories Table are Valid.\n")
}

