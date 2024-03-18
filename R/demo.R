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


###########
# Execute the query to find invalid product IDs in the categories table
invalid_product_ids <- dbGetQuery(my_connection, "
  SELECT c.product_id 
  FROM categories c 
  LEFT JOIN products p ON c.product_id = p.product_id
  WHERE p.product_id IS NULL
")

# Check if there are any invalid product IDs
if (nrow(invalid_product_ids) > 0) {
  print("Invalid Product IDs found in Categories Table:")
  print(invalid_product_ids$product_id)
} else {
  print("All Product IDs in Categories Table are valid.")
}
