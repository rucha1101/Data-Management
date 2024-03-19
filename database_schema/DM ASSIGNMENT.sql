-- Customers table: stores basic information about customers.
CREATE TABLE 'customers' (
    'customer_id' text PRIMARY KEY,
	'cx_name' text,
	'cx_email' text not null,
	'gender' text,
	'cx_address' text not null,
	'sign_up_date' date,
	'last_login_date' date,
	'date_of_birth' date,
	'cx_phone_number' text not nulls
);

-- Products table: contains details of the products.
CREATE TABLE 'products' (
	'product_id' text PRIMARY KEY,
    'product_name' text not null,
    'description' text,
    'price' real,
    'weight' real,
    'color' text
);

-- Shipment table: records shipment details for transactions.
CREATE TABLE shipment (
    'shipment_id' text not null,
    'transaction_id' text PRIMARY KEY,
    'shipment_date' date not null,
    'shipment_phone_number' text not null,
    'shipment_address' text not null,
    'shipment_city' text not null,
    'shipment_state' text,
    'shipment_zip_code' text,
    'shipment_country' text
);

-- Suppliers table: links suppliers with the products they supply.
CREATE TABLE suppliers (
    'supplier_id' text not null,
    'product_id' text not null,
    'contact_name' text,
    'supplier_address' text,
    'supplier_phone_number' text,
    'supplier_email' text,
    PRIMARY KEY (supplier_id, product_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Categories table: categorizes products.
CREATE TABLE categories (
    'category_id' text not null,
    'category_name' text,
    'category_description' text,
    'parent_category_id' text,
    'product_id' text PRIMARY KEY
);

-- Reviews table: stores customer reviews for products.
CREATE TABLE reviews (
    'review_id' text PRIMARY KEY,
    'product_id' text not null,
    'customer_id' text not null,
    'rating' integer,
    'review_text' text,
    'review_date' date,
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- TransactionDetails table: details of transactions made by customers.
CREATE TABLE transactiondetails (
    'transaction_id' text not null,
    'customer_id' text not null,
    'transaction_date' date,
    'payment_method' text,
    'currency' text,
    'payment_processor' text,
    'product_id' text not null,
    'quantity' integer,
    'discount' real,
    'total_price' real,
    PRIMARY KEY (transaction_id, customer_id, product_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);
