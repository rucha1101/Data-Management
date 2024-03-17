library(DBI)
library(readr)
library(RSQLite)

# Establish connection to your SQLite database
my_connection <- dbConnect(RSQLite::SQLite(), "database.db")

# Function to append CSV file contents to the appropriate table
append_csv_to_table <- function(file_path, connection) {
  # Determine the table name based on the file name prefix
  file_name <- basename(file_path)
  table_name <- tolower(sub("([A-Za-z]+)[_\\.].*", "\\1", file_name))
  
  # Read the CSV file
  data <- read_csv(file_path, show_col_types = FALSE)
  
  # Directly append the data to the table, assuming table exists or can be created to match data frame
  if(!dbExistsTable(connection, table_name)) {
    dbWriteTable(connection, table_name, data.frame(), row.names = FALSE) # Initial table creation if needed
  }
  dbWriteTable(connection, table_name, data, append = TRUE, row.names = FALSE)
  
  message(paste("Successfully appended", file_name, "to the", table_name, "table."))
}

# List all CSV files in the data_upload directory
all_files <- list.files(path = "data_upload", pattern = "\\.csv$", full.names = TRUE)

# Apply the function to each file
lapply(all_files, append_csv_to_table, my_connection)

# Disconnect from the database when done
# dbDisconnect(my_connection)
