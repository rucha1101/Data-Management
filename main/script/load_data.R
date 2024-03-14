library(readr)
library(RSQLite)
library(dplyr)
library(readxl)
library(openxlsx)



my_connection <- RSQLite::dbConnect(RSQLite::SQLite(),"database.db")


# Physical Schema
tables <- RSQLite::dbListTables(my_connection)

# drop all tables
for (table in tables) {
  query <- paste("DROP TABLE IF EXISTS", table)
  RSQLite::dbExecute(my_connection, query)
}


RSQLite::dbExecute(my_connection,"
  CREATE TABLE 'Customers' (
    'customer_id' VARCHAR(4) PRIMARY KEY,
    );
")

RSQLite::dbExecute(my_connection," 
  CREATE TABLE '' ();
")

RSQLite::dbExecute(my_connection,"
  CREATE TABLE 'Suppliers' ();
")

RSQLite::dbExecute(my_connection,"
  CREATE TABLE 'Categories' ();
")

RSQLite::dbExecute(my_connection," 
  CREATE TABLE ''();
")


# Save the workbook
openxlsx::saveWorkbook(wb, "analysis_result/analysis_results.xlsx", overwrite = TRUE)