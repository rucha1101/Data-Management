library(DBI)
library(readr)
library(RSQLite)
library(ggplot2)
library(sqldf)


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



if(file.exists(categories_path) && file.exists(products_path)) {
  # categories_data <- read_csv(categories_path, show_col_types = FALSE)
  # products_data <- read_csv(products_path, show_col_types = FALSE)
  
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

# Data Integrity Checks
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

# Check for Shipment Transaction IDs
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

# Check for Shipment Transaction IDs
if (length(unique(reviews_data$review_id)) != nrow(reviews_data)) {
  stop(paste("Review IDs are not unique"))
} else {
  message("VALIDATION SUCCESSFUL: Review IDs are unique")
}

# Check for Transactiondetail Primary Key
if (length(unique(paste(transactiondetails_data$transaction_id, transactiondetails_data$customer_id, transactiondetails_data$product_id))) != nrow(transactiondetails_data)) {
  stop(paste("Transaction data primary key not unique"))
} else {
  message("VALIDATION SUCCESSFUL: Transaction data primary key is unique")
}


dbDisconnect(my_connection)