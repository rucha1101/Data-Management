library(readr)
library(RSQLite)
library(dplyr)

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

dbDisconnect(my_connection)

