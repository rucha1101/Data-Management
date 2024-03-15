library(readr)
library(RSQLite)

# Load the datasets
customer <- readr::read_csv("data_upload/Customers.csv")

# Connect to the database
my_connection <- RSQLite::dbConnect(RSQLite::SQLite(), "database/group_33.db")

# Append each data frame to its respective table in the database
# Adjust the table names as needed
RSQLite::dbWriteTable(my_connection, "customer", customer, append = TRUE)

# Close the database connection
RSQLite::dbDisconnect(my_connection)
