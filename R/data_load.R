library(DBI)
library(readr)
library(RSQLite)
library(ggplot2)
library(sqldf)
#library(tidyverse)
#library(tidytext)
#library(gridExtra)
library(dplyr)
library(RColorBrewer)
#install.packages("gganimate")
#library(gganimate)
#install.packages('transformr')
#library(transformr)



my_connection <- dbConnect(RSQLite::SQLite(), "database.db")

append_csv_to_table <- function(file_path, connection) {
  file_name <- basename(file_path)
  table_name <- tolower(sub("([A-Za-z]+)[_\\.].*", "\\1", file_name))
  
  data <- read_csv(file_path, show_col_types = FALSE)
  
  tryCatch({
    if(!dbExistsTable(connection, table_name)) {
      stop(paste("Table does not exist and schema creation is required:", table_name))
    }
    dbWriteTable(connection, table_name, data, append = TRUE, row.names = FALSE)
    message(paste("Successfully appended", file_name, "to the", table_name, "table."))
  }, error = function(e) {
    message(paste("Failed to append", file_name, "to the", table_name, "table:", e$message))
  })
}


all_files <- list.files(path = "data_upload", pattern = "\\.csv$", full.names = TRUE)
lapply(all_files, append_csv_to_table, my_connection)



# Count for all tables
display_table_counts <- function(connection) {
  # Retrieve table names
  tables_query <- "SELECT name FROM sqlite_master WHERE type='table';"
  tables <- dbGetQuery(connection, tables_query)$name
  
  if(length(tables) > 0) {
    for (table_name in tables) {
      count_query <- paste0("SELECT COUNT(*) AS count FROM ", table_name, ";")
      count <- dbGetQuery(connection, count_query)$count
      cat(table_name, ": ", count, "\n", sep = "")
    }
  } else {
    cat("No tables found in the database.\n")
  }
}

# Display table counts
display_table_counts(my_connection)



# VALIDATION CODE
customers_path <- "data_upload/customers.csv"
shipment_path <- "data_upload/shipment.csv"
transactiondetails_path  <- "data_upload/transactiondetails.csv"
reviews_path <- "data_upload/reviews.csv"
suppliers_path <- "data_upload/suppliers.csv"
categories_path <- "data_upload/categories.csv"
products_path <- "data_upload/products.csv"
categories_data <- read_csv(categories_path, show_col_types = FALSE)
products_data <- read_csv(products_path, show_col_types = FALSE)
transactiondetails_data <- read_csv(transactiondetails_path, show_col_types = FALSE)
reviews_data <- read_csv(reviews_path, show_col_types = FALSE)
suppliers_data <- read_csv(suppliers_path, show_col_types = FALSE)
customers_data <- read_csv(customers_path, show_col_types = FALSE)
shipment_data <- read_csv(shipment_path, show_col_types = FALSE)

# List of all data frames
data_frames <- list(categories_data, products_data, transactiondetails_data, reviews_data, suppliers_data, customers_data, shipment_data)

# Names of all data frames
data_frame_names <- c("categories_data", "products_data", "transactiondetails_data", "reviews_data", "suppliers_data", "customers_data", "shipment_data")


 #Security Checks
 # Function to check for SQL injection
 check_sql_injection <- function(input_data) {
   # Define a list of forbidden SQL keywords
   forbidden_keywords <- c("SELECT", "INSERT", "UPDATE", "DELETE", "DROP", "ALTER", "CREATE", "TRUNCATE", "UNION", "JOIN", "FROM", "WHERE")

   # Check if input contains any forbidden keywords
   if (any(sapply(forbidden_keywords, function(x) grepl(paste0("\\b", x, "\\b"), tolower(input_data), perl = TRUE)))) {
     return(FALSE) # SQL injection detected
   } else {
     return(TRUE) # No SQL injection detected
   }
 }

 #Loop through each data frame
 for (i in seq_along(data_frames)) {
   # Perform security checks on each column
   for (col in colnames(data_frames[[i]])) {
     # Check for SQL injection
     if (!all(sapply(data_frames[[i]][[col]], check_sql_injection))) {
       cat("SQL injection detected in column:", col, "of", data_frame_names[i], "\n")
     }

   }
}






#Data Integrity Checks
#Duplicate and NA value check
# Loop through each data frame
for (i in seq_along(data_frames)) {
  # Check for duplicate rows
  if (anyDuplicated(data_frames[[i]])) {
    stop(paste("DUPLICATE ROWS DETECTED in", data_frame_names[i]))
  }
  
  # Check for NA values
  if (any(is.na(data_frames[[i]]))) {
    stop(paste("NA VALUES DETECTED in", data_frame_names[i]))
  }
  
  # If no issues found
  message(paste("VALIDATION SUCCESSFUL:", data_frame_names[i], "checked."))
}

if(file.exists(categories_path) && file.exists(products_path)) {
  
  
  # Using SQL query with sqldf
  missing_product_ids <- sqldf("SELECT c.product_id
                                FROM categories_data c
                                LEFT JOIN products_data p ON c.product_id = p.product_id
                                WHERE p.product_id IS NULL")
  
  error_block <- if(nrow(missing_product_ids) > 0) {
    stop(paste("There are product IDs in 'categories' that don't exist in 'products'. Data insertion halted."))
  }
  else {
    message("VALIDATION SUCCESSFUL!!!: All product IDs in 'categories' exist in 'products'")
    
  }
}

# Check for unique customer IDs
if (length(unique(customers_data$customer_id)) != nrow(customers_data)) {
  stop(paste("Customer IDs are not unique."))
} else {
  message("VALIDATION SUCCESSFUL: Customer IDs are unique")
}


# Check for unique product IDs
if (length(unique(products_data$product_id)) != nrow(products_data)) {
  stop(paste("Product IDs are not unique."))
} else {
  message("VALIDATION SUCCESSFUL: Product_IDs are unique")
}


# Check for unique product IDs in category table
if (length(unique(categories_data$product_id)) != nrow(categories_data)) {
  stop(paste("Product IDs are not unique in category table"))
} else {
  message("VALIDATION SUCCESSFUL: Product_IDs are unique in category table")
}

# Check for shipment primary Key
if (length(unique(shipment_data$transaction_id)) != nrow(shipment_data)) {
  stop(paste("Shipment data primary key not unique"))
} else {
  message("VALIDATION SUCCESSFUL: Shipment data primary key is unique")
}

# Check for Supplier Primary Key
if (length(unique(paste(suppliers_data$supplier_id, suppliers_data$product_id))) != nrow(suppliers_data)) {
  stop(paste("Supplier data primary key not unique"))
} else {
  message("VALIDATION SUCCESSFUL: Supplier data primary key is unique")
}

# Check for unique Review IDs
if (length(unique(reviews_data$review_id)) != nrow(reviews_data)) {
  stop(paste("Review IDs are not unique"))
} else {
  message("VALIDATION SUCCESSFUL: Review IDs are unique")
}

# Check for Transactiondetail Primary Key
if (length(unique(paste(transactiondetails_data$transaction_id, transactiondetails_data$customer_id, transactiondetails_data$product_id))) != nrow(transactiondetails_data)) {
  stop(paste("Transaction data primary key not unique"))
} else {
  message("VALIDATION SUCCESSFUL: Transaction data primary key is unique")
}

#Referential Checks
# Referential Integrity Check: Customer Existence in Transaction Detail
if (any(!transactiondetails_data$customer_id %in% customers_data$customer_id)) {
  stop("Invalid customer IDs in transaction_detail table!")
} else {
  message("Referential Integrity Checked: Customer Existence in Transaction Detail")
}

# Referential Integrity Check: Product Existence in Transaction Detail
if (any(!transactiondetails_data$product_id %in% products_data$product_id)) {
  stop("Invalid product IDs in transaction_detail table!")
} else {
  message("Referential Integrity Checked: Product Existence in Transaction Detail")
}

# Referential Integrity Check: Product Existence in Reviews
if (any(!reviews_data$product_id %in% products_data$product_id)) {
  stop("Invalid product IDs in reviews table!")
} else {
  message("Referential Integrity Checked: Product Existence in Reviews")
}

# Referential Integrity Check: Customer Existence in Reviews
if (any(!reviews_data$customer_id %in% customers_data$customer_id)) {
  stop("Invalid customer IDs in reviews table!")
} else {
  message("Referential Integrity Checked: Customer Existence in Reviews")
}

# Referential Integrity Check: Product Existence in Categories
if (any(!categories_data$product_id %in% products_data$product_id)) {
  stop("Invalid product IDs in categories table!")
} else {
  message("Referential Integrity Checked: Product Existence in Categories")
}

# Group by category_id and summarise the number of unique parent_category_id
category_parent <- categories_data %>%
  group_by(category_id) %>%
  summarise(n_unique_parent = n_distinct(parent_category_id))

# Check if any category_id has more than one unique parent_category_id
if (any(category_parent$n_unique_parent > 1)) {
  stop("Some categories correspond to more than one parent category!")
} else {
  message("Referential Integrity Checked: Category_id having more than one unique parent_category_id")
}


# Referential Integrity Check: Product Existence in Suppliers
if (any(!suppliers_data$product_id %in% products_data$product_id)) {
  stop("Invalid product IDs in suppliers table!")
} else {
  message("Referential Integrity Checked: Product Existence in Suppliers")
}


# Referential Integrity Check: Transaction Existence in Shipment
if (any(!shipment_data$transaction_id %in% transactiondetails_data$transaction_id)) {
  stop("Invalid transaction IDs in shipment table!")
} else {
  message("Referential Integrity Checked: Transaction Existence in Shipment")
}


# Field-Level Validations

# Check email format
if (!all(grepl("^\\S+@\\S+\\.\\S+$", customers_data$cx_email)) | 
    any(grepl("@.*[0-9]", customers_data$cx_email))) {
  stop("Invalid email format in customer data.")
} else {
  message("VALIDATION SUCCESSFUL: Customer emails checked.")
}

if (!all(grepl("^\\S+@\\S+\\.\\S+$", suppliers_data$supplier_email)) | 
    any(grepl("@.*[0-9]", suppliers_data$supplier_email))) {
  stop("Invalid email format in supplier data.")
} else {
  message("VALIDATION SUCCESSFUL: Supplier emails checked.")
}

# Check phone number format
if (!all(grepl("^\\d{3}-\\d{3}-\\d{4}$", customers_data$cx_phone_number))) {
  stop("Invalid phone number format in customer data.")
} else {
  message("VALIDATION SUCCESSFUL: Customer numbers checked.")
}


# Check date formats
if (!all(is.na(as.Date(customers_data$last_login_date, "%mm/%dd/%YYYY")))) {
  stop("Invalid last login date format.")
} else {
  message("VALIDATION SUCCESSFUL: Last login date checked.")
}

if (!all(is.na(as.Date(customers_data$date_of_birth, "%mm/%dd/%YYYY")))) {
  stop("Invalid birth date format.")
} else {
  message("VALIDATION SUCCESSFUL: Customer birth_dates checked.")
}

if (!all(is.na(as.Date(shipment_data$shipment_date, "%mm/%dd/%YYYY")))) {
  stop("Invalid shipment date format.")
} else {
  message("VALIDATION SUCCESSFUL: Shipment dates checked.")
}

if (!all(is.na(as.Date(reviews_data$review_date, "%mm/%dd/%YYYY")))) {
  stop("Invalid review date format.")
} else {
  message("VALIDATION SUCCESSFUL: Review dates checked.")
}

if (!all(is.na(as.Date(transactiondetails_data$transaction_date, "%mm/%dd/%YYYY")))) {
  stop("Invalid review date format.")
} else {
  message("VALIDATION SUCCESSFUL: Transaction dates checked.")
}



#Check for currency format
if (!all(nchar(as.character(transactiondetails_data$currency)) == 3 & grepl("^[A-Z]{3}$", transactiondetails_data$currency))) {
  stop("Invalid currency format.")
} else {
  message("VALIDATION SUCCESSFUL: Currency codes checked.")
}


#Business Rule Checks
#Check for positive integer in transaction quantity
if (!all(grepl("^\\d+$", transactiondetails_data$quantity))) {
  stop("Invalid quantity format in transaction details.")
} else {
  message("VALIDATION SUCCESSFUL: Quantity numbers checked.")
}

#Check for positive weight in product data
if (any(products_data$weight < 0)) {
  stop("Invalid weight values in product data.")
} else {
  message("VALIDATION SUCCESSFUL: Product weights checked.")
}

#Checking for review dates in the future
current_date <- Sys.Date()
# Check if review_date is in the future
if (any(as.Date(reviews_data$review_date, "%m/%d/%Y") >= current_date)) {
  stop("Invalid dates: Review date is in the future.")
} else {
  message("VALIDATION SUCCESSFUL: Review dates checked.")
}
                  
#Checking for transaction dates in the future
current_date <- Sys.Date()
if (any(as.Date(transactiondetails_data$transaction_date, "%m/%d/%Y") >= current_date)) {
  stop("Invalid dates: Transaction date is in the future.")
} else {
  message("VALIDATION SUCCESSFUL: Transaction dates checked.")
}

#Checking for shipment dates in the future
current_date <- Sys.Date()
if (any(as.Date(shipment_data$shipment_date, "%m/%d/%Y") >= current_date)) {
  stop("Invalid dates: Shipment date is in the future.")
} else {
  message("VALIDATION SUCCESSFUL: Shipment dates checked.")
}

#Checking for customer date of birth in the future
current_date <- Sys.Date()
if (any(as.Date(customers_data$date_of_birth, "%m/%d/%Y") >= current_date)) {
  stop("Invalid dates: Customer date of birth is in the future.")
} else {
  message("VALIDATION SUCCESSFUL: Customer dates of birth checked.")
}   
                  
#Checking for customer last_login_date in the future
current_date <- Sys.Date()
if (any(as.Date(customers_data$last_login_date, "%m/%d/%Y") >= current_date)) {
  stop("Invalid dates: Customer last_login_date is in the future.")
} else {
  message("VALIDATION SUCCESSFUL: Customer last_login_date checked.")
}                  
                  
                  
                  


# Check if price is non-negative in product data
if (any(products_data$price < 0)) {
  stop("Invalid price values in product data.")
} else {
  message("VALIDATION SUCCESSFUL: Product prices checked.")
}

#Check for non-negative total_price in transaction data
if (any(transactiondetails_data$total_price < 0)) {
  stop("Invalid price values in transaction data.")
} else {
  message("VALIDATION SUCCESSFUL: Transaction prices checked.")
}
# Check if discount is non-negative in transaction data
if (any(transactiondetails_data$discount < 0)) {
  stop("Invalid discount values in product data.")
} else {
  message("VALIDATION SUCCESSFUL: Product prices checked.")
}


#Disconnecting database connection
dbDisconnect(my_connection)

