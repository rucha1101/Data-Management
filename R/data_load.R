library(readr)
library(RSQLite)
library(dplyr)

#connect to the SQLite database
my_connection <- RSQLite::dbConnect(RSQLite::SQLite(),"database.db")


# Physical Schema
tables <- RSQLite::dbListTables(my_connection)

# Part 1.2 - SQL Database Schema Creation 

# drop all tables
for (table in tables) {
  query <- paste("DROP TABLE IF EXISTS", table)
  RSQLite::dbExecute(my_connection, query)
}

RSQLite::dbExecute(my_connection,"
  CREATE TABLE 'customers' (
    'customer_id' text PRIMARY KEY,
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

RSQLite::dbExecute(my_connection,"
  CREATE TABLE 'products' (
	'product_id' text primary key,
    'product_name' text not null,
    'description' text,
    'price' real,
    'weight' real,
    'color' text  
    );
")
RSQLite::dbExecute(my_connection,"
create table shipment (
    'shipment_id' text not null,
    'transaction_id' text primary key,
    'shipment_date' date not null,
    'shipment_phone_number' text not null,
    'shipment_address' text not null,
    'shipment_city' text not null,
    'shipment_state' text,
    'shipment_zip_code' text,
    'shipment_country' text
);
")

RSQLite::dbExecute(my_connection,"
create table suppliers (
    'supplier_id' text not null,
    'product_id' text not null,
    'contact_name' text,
    'supplier_address' text,
    'supplier_phone_number' text,
    'supplier_email' text,
	primary key (supplier_id,product_id)
    foreign key (product_id) references products(product_id)
);
")

RSQLite::dbExecute(my_connection,"
create table categories (
    'category_id' text not null,
    'category_name' text,
    'category_description' text,
    'parent_category_id' text,
	  'product_id' text primary key
);
")

RSQLite::dbExecute(my_connection,"
create table reviews (
    'review_id' text primary key,
    'product_id' text not null,
    'customer_id' text not null,
    'rating' integer,
    'review_text' text,
    'review_date' date,
    foreign key (product_id) references products(product_id),
    foreign key (customer_id) references customers(customer_id)
);
")


RSQLite::dbExecute(my_connection,"
create table transactiondetails (
    'transaction_id' text not null,
    'customer_id' text not null,
    'transaction_date' date,
    'payment_method' text,
    'currency' text,
    'payment_processor' text,
    'product_id' text not null,
    'quantity' integer,
    'discount' real,
    'total_price' real,
    	primary key(transaction_id,customer_id,product_id),
    foreign key (product_id) references products(product_id),
    foreign key (customer_id) references customers(customer_id)
);
")

# Check if the tables are created

dbGetQuery(my_connection, 
           sprintf("SELECT name FROM sqlite_master WHERE type='table';")
)

dbDisconnect(my_connection)
