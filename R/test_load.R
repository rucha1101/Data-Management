library(readr)
library(RSQLite)
library(dplyr)

my_connection <- RSQLite::dbConnect(RSQLite::SQLite(),"database.db")

 this_filepath <- ("data_upload/Customers.csv") 
  
  this_file_contents <- read_csv(this_filepath) 
  
  table_name <- "Customers" 
  
dbWriteTable(my_connection, table_name, this_file_contents, overwrite = TRUE)
