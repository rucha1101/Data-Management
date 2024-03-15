-- creating table 'customers'
create table customers (
    customer_id VARCHAR(4) PRIMARY KEY,
	cx_name text,
	cx_email text not null,
	gender text,
	cx_address text not null,
	sign_up_date date,
	last_login_date timestamp,
	date_of_birth date,
	cx_phone_number text not null   
    );

-- creating table 'shipment'
create table shipment (
    shipment_id text primary key,
    transaction_id text not null,
    shipment_date date not null,
    shipment_phone_number text not null,
    shipment_address text not null,
    shipment_city text not null,
    shipment_state text,
    shipment_zip_code text,
    shipment_country text,
    foreign key (transaction_id) references transaction_detail(transaction_id)
);

-- creating table 'suppliers'
create table suppliers (
    supplier_id integer primary key,
    product_id text not null,
    company_name text,
    contact_name text,
    supplier_address text,
    supplier_phone_number text,
    supplier_email text,
    website text,
    foreign key (product_id) references products(product_id)
);

-- creating table 'categories'
create table categories (
    category_id integer primary key,
    category_name text,
    catergory_description text,
    parent_category_id integer,
	product_id text not null,
    foreign key (parent_category_id) references categories(category_id)
	foreign key (product_id) references products(product_id)
);

-- creating table 'products'
create table products (
    product_id integer primary key,
    name text not null,
    description text,
    price real,
    weight real,
    color text,
    material text
);

-- creating table 'reviews'
create table reviews (
    review_id integer primary key,
    product_id text not null,
    customer_id text not null,
    rating integer,
    review_text text,
    review_date date,
    foreign key (product_id) references products(product_id),
    foreign key (customer_id) references customers(customer_id)
);

-- creating table 'transaction_detail'
create table transaction_detail (
    transaction_id integer primary key,
    customer_id integer not null,
    product_id integer not null,
    quantity integer,
    discount real,
    total_price real,
	transaction_date date,
    payment_method text,
    currency text,
    payment_processor text,
    foreign key (product_id) references products(product_id),
    foreign key (customer_id) references customers(customer_id)
);
