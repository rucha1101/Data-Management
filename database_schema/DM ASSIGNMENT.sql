-- creating table 'customers'
CREATE TABLE customers
(
  customer_id TEXT PRIMARY KEY,
  cx_name TEXT,
  cx_email TEXT NOT NULL,
  gender TEXT,
  cx_address TEXT NOT NULL,
  sign_up_date    DATE,
  last_login_date DATE,
  date_of_birth   DATE,
  cx_phone_number TEXT NOT NULL
);

-- creating table 'shipment'
CREATE TABLE shipment
(
  shipment_id TEXT PRIMARY KEY,
  transaction_id TEXT NOT NULL,
  shipment_date DATE NOT NULL,
  shipment_phone_number TEXT NOT NULL,
  shipment_address TEXT NOT NULL,
  shipment_city TEXT NOT NULL,
  shipment_state TEXT,
  shipment_zip_code TEXT,
  shipment_country TEXT,
  FOREIGN KEY (transaction_id) REFERENCES transaction_detail(transaction_id)
);

-- creating table 'suppliers'
CREATE TABLE suppliers
(
  supplier_id TEXT PRIMARY KEY,
  product_id TEXT NOT NULL,
  company_name TEXT,
  contact_name TEXT,
  supplier_address TEXT,
  supplier_phone_number TEXT,
  supplier_email TEXT,
  website TEXT,
  FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- creating table 'categories'
CREATE TABLE categories
(
  category_id TEXT PRIMARY KEY,
  category_name TEXT,
  category_description TEXT,
  parent_category_id TEXT,
  product_id TEXT NOT NULL,
  FOREIGN KEY (parent_category_id) REFERENCES categories(category_id) FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- creating table 'products'
CREATE TABLE products
(
  product_id TEXT PRIMARY KEY,
  product_name TEXT NOT NULL,
  description TEXT,
  price  REAL,
  weight REAL,
  color TEXT,
  material TEXT
);

-- creating table 'reviews'
CREATE TABLE reviews
(
  review_id TEXT PRIMARY KEY,
  product_id TEXT NOT NULL,
  customer_id TEXT NOT NULL,
  rating INTEGER,
  review_text TEXT,
  review_date DATE,
  FOREIGN KEY (product_id) REFERENCES products(product_id),
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- creating table 'transaction_detail'
CREATE TABLE transaction_detail (
    transaction_id TEXT PRIMARY KEY,
    customer_id TEXT NOT NULL,
    product_id TEXT NOT NULL,
    quantity INTEGER,
    discount REAL,
    total_price REAL,
	transaction_date DATE,
    payment_method TEXT,
    currency TEXT,
    payment_processor TEXT,
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);
