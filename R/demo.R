# library(DBI)
# library(readr)
# library(RSQLite)
# 
# # Establish connection to your SQLite database
# my_connection <- dbConnect(RSQLite::SQLite(), "database.db")
# 
# # Function to append CSV file contents to the appropriate table
# append_csv_to_table <- function(file_path, connection) {
#   # Determine the table name based on the file name prefix
#   file_name <- basename(file_path)
#   table_name <- tolower(sub("([A-Za-z]+)[_\\.].*", "\\1", file_name))
#   
#   # Read the CSV file
#   data <- read_csv(file_path, show_col_types = FALSE)
#   
#   # Directly append the data to the table, assuming table exists or can be created to match data frame
#   if(!dbExistsTable(connection, table_name)) {
#     dbWriteTable(connection, table_name, data.frame(), row.names = FALSE) # Initial table creation if needed
#   }
#   dbWriteTable(connection, table_name, data, append = TRUE, row.names = FALSE)
#   
#   message(paste("Successfully appended", file_name, "to the", table_name, "table."))
# }
# 
# # List all CSV files in the data_upload directory
# all_files <- list.files(path = "data_upload", pattern = "\\.csv$", full.names = TRUE)
# 
# # Apply the function to each file
# lapply(all_files, append_csv_to_table, my_connection)
# 
# # Disconnect from the database when done
# # dbDisconnect(my_connection)








library(DBI)
library(readr)
library(RSQLite)
library(ggplot2)


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




# 1. Top 10 Products

sql_query <- "
SELECT p.product_name, AVG(r.rating) AS average_rating
FROM reviews r
JOIN products p ON r.product_id = p.product_id
GROUP BY p.product_id
ORDER BY average_rating DESC
LIMIT 10
"

top_rated_products <- dbGetQuery(my_connection, sql_query)

# visualising
ggplot(top_rated_products, aes(x = reorder(product_name, average_rating), y = average_rating, fill = average_rating)) +
  geom_col() +
  coord_flip() +  # Horizontal bars for better readability
  labs(title = "Top 10 Rated Products", x = "Product Name", y = "Average Rating") +
  scale_fill_viridis_c() +  # Use a nice color scale for the fill
  theme_minimal()


