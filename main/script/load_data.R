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

data <- readr::read_csv("/main/data/csv/Customers.csv")

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
    'cx_name' text,
    'cx_email' text not null,
    'gender' text,
    'cx_address' text not null,
    'sign_up_date' date,
    'last_login_date' timestamp,
    'date_of_birth' date,
    'cx_phone_number' text not null
    );
")

# Save the workbook
#openxlsx::saveWorkbook(wb, "/cloud/project/main/script/analysis_results.xlsx", overwrite = TRUE)
