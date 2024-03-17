library(DBI)
library(readr)
library(RSQLite)

# Establish connection to your SQLite database
my_connection <- RSQLite::dbConnect(RSQLite::SQLite(), "database.db")

# Function to append CSV file contents to the appropriate table
append_csv_to_table <- function(file_path, connection) {
  # Determine the table name based on the file name prefix before the first underscore or dot
  # Example: "Customers_2023.csv" or "Customers.csv" will both target the "Customers" table
  file_name <- basename(file_path)
  table_name <- tolower(sub("([A-Za-z]+)[_\\.].*", "\\1", file_name))
  
  # Read the CSV file without showing column types message
  data <- read_csv(file_path, show_col_types = FALSE)
  
  # Check if the table exists, create it if it doesn't
  if (!dbExistsTable(connection, table_name)) {
    dbWriteTable(connection, table_name, data.frame(), row.names = FALSE)
  }
  
  # Append the data to the table
  dbWriteTable(connection, table_name, data, append = TRUE, row.names = FALSE)
  
  # Print a success message
  message(paste("Successfully appended", file_name, "to the", table_name, "table."))
}

# List all CSV files in the data_upload directory
all_files <- list.files(path = "data_upload", pattern = "\\.csv$", full.names = TRUE)

# Apply the function to each file, passing the database connection as an argument
lapply(all_files, append_csv_to_table, my_connection)

# Optionally, disconnect from the database if you're done
# dbDisconnect(my_connection)
