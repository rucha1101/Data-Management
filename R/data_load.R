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

RSQLite::dbExecute(my_connection,"
  CREATE TABLE 'products' (
	'product_id' text primary key,
    'product_name' text not null,
    'description' text,
    'price' real,
    'weight' real,
    'color' text,
    'material' text  
    );
")
RSQLite::dbExecute(my_connection,"
create table shipment (
    'shipment_id' text primary key,
    'transaction_id' text not null,
    'shipment_date' date not null,
    'shipment_phone_number' text not null,
    'shipment_address' text not null,
    'shipment_city' text not null,
    'shipment_state' text,
    'shipment_zip_code' text,
    'shipment_country' text,
    foreign key (transaction_id) references transaction_detail(transaction_id)
);
")

RSQLite::dbExecute(my_connection,"
create table suppliers (
    'supplier_id' text primary key,
    'product_id' text not null,
    'company_name' text,
    'contact_name' text,
    'supplier_address' text,
    'supplier_phone_number' text,
    'supplier_email' text,
    'website' text,
    foreign key (product_id) references products(product_id)
);
")

RSQLite::dbExecute(my_connection,"
create table categories (
    'category_id' text primary key,
    'category_name' text,
    'category_description' text,
    'parent_category_id' text,
	'product_id' text not null,
    foreign key (parent_category_id) references categories(category_id)
	foreign key (product_id) references products(product_id)
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
    'transaction_id' text primary key,
    'customer_id' text not null,
    'product_id' text not null,
    'quantity' integer,
    'discount' real,
    'total_price' real,
	'transaction_date' date,
    'payment_method' text,
    'currency' text,
    'payment_processor' text,
    foreign key (product_id) references products(product_id),
    foreign key (customer_id) references customers(customer_id)
);
")

# Check if the tables are created

dbGetQuery(my_connection, 
           sprintf("SELECT name FROM sqlite_master WHERE type='table';")
)

dbDisconnect(my_connection)

