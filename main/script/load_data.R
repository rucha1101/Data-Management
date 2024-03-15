# install.packages("readr")
# install.packages("RSQLite")
# install.packages("dplyr")
# install.packages("readxl")
# install.packages("openxlsx")
library(readr)
library(RSQLite)
library(dplyr)
library(readxl)
library(openxlsx)

data <- readr::read_csv("main/data/csv/Categories.csv")

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
    'customer_id' integer primary key,
    'cx_email' text not null,
    'sign_up_date' date,
    'cx_phone_number' text not null,
    'cx_address' text not null,
    'cx_name' text,
    'last_login' timestamp,
    'birth_date' date,
    'gender' text
    );
")

# Save the workbook
#openxlsx::saveWorkbook(wb, "/cloud/project/main/script/analysis_results.xlsx", overwrite = TRUE)
