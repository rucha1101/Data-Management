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
Customers_path <- "data_upload/Customers.csv"
shipment_path <- "data_upload/shipment.csv"
transactiondetails_path  <- "data_upload/transactiondetails.csv"
reviews_path <- "data_upload/reviews.csv"
suppliers_path <- "data_upload/suppliers.csv"
categories_path <- "data_upload/categories.csv"
products_path <- "data_upload/products.csv"

if(file.exists(categories_path) && file.exists(products_path)) {
  categories_data <- read_csv(categories_path, show_col_types = FALSE)
  products_data <- read_csv(products_path, show_col_types = FALSE)
  
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



dbDisconnect(my_connection)