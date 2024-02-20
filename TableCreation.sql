-- Creating table 'Address'
CREATE TABLE Address (
    Address_ID INTEGER PRIMARY KEY,
    Address_Label TEXT,
    Country TEXT,
    Postcode TEXT,
    City TEXT,
    Shipping_Address TEXT,
    Billing_Address TEXT
);

-- Creating table 'Customers'
CREATE TABLE Customers (
    Customer_ID INTEGER PRIMARY KEY,
    Email TEXT,
    Phone_Number TEXT,
    Address_ID INTEGER,
    LoginName TEXT,
    Password TEXT,
    LoyaltyPoints INTEGER,
    PreferredPaymentMethod TEXT,
    BirthDate DATE,
    Gender TEXT,
    FOREIGN KEY (Address_ID) REFERENCES Address(Address_ID)
);

-- Creating table 'Shippers'
CREATE TABLE Shippers (
    Shipper_ID INTEGER PRIMARY KEY,
    Company_Name TEXT,
    Phone_Number TEXT
);

-- Creating table 'Suppliers'
CREATE TABLE Suppliers (
    Supplier_ID INTEGER PRIMARY KEY,
    Company_Name TEXT,
    Contact_Name TEXT,
    Address TEXT,
    Phone TEXT,
    Email TEXT,
    Website TEXT
);

-- Creating table 'Categories'
CREATE TABLE Categories (
    Category_ID INTEGER PRIMARY KEY,
    Category_Name TEXT,
    Description TEXT,
    Parent_Category_ID INTEGER,
    FOREIGN KEY (Parent_Category_ID) REFERENCES Categories(Category_ID)
);

-- Creating table 'Products'
CREATE TABLE Products (
    Product_ID INTEGER PRIMARY KEY,
    Name TEXT,
    Description TEXT,
    Price REAL,
    Category_ID INTEGER,
    Weight REAL,
    Color TEXT,
    Material TEXT,
    Dimensions TEXT,
    Supplier_ID INTEGER,
    FOREIGN KEY (Category_ID) REFERENCES Categories(Category_ID),
    FOREIGN KEY (Supplier_ID) REFERENCES Suppliers(Supplier_ID)
);

-- Creating table 'Inventory'
CREATE TABLE Inventory (
    Product_ID INTEGER PRIMARY KEY,
    Quantity_OnHand INTEGER,
    FOREIGN KEY (Product_ID) REFERENCES Products(Product_ID)
);

-- Creating table 'Ads'
CREATE TABLE Ads (
    Ad_ID INTEGER PRIMARY KEY,
    Title TEXT,
    Description TEXT,
    Start_Date DATE,
    End_Date DATE,
    Category_ID INTEGER,
    Product_ID INTEGER,
    FOREIGN KEY (Category_ID) REFERENCES Categories(Category_ID),
    FOREIGN KEY (Product_ID) REFERENCES Products(Product_ID)
);

-- Creating table 'Reviews'
CREATE TABLE Reviews (
    Review_ID INTEGER PRIMARY KEY,
    Product_ID INTEGER,
    Customer_ID INTEGER,
    Rating INTEGER,
    Review_Text TEXT,
    Review_Date DATE,
    FOREIGN KEY (Product_ID) REFERENCES Products(Product_ID),
    FOREIGN KEY (Customer_ID) REFERENCES Customers(Customer_ID)
);

-- Creating table 'Orders'
CREATE TABLE Orders (
    Order_ID INTEGER PRIMARY KEY,
    Customer_ID INTEGER,
    Order_Date DATE,
    Shipped_Date DATE,
    Shipper_ID INTEGER,
    Billing_Address TEXT,
    Shipping_Address TEXT,
    Payment_Method TEXT,
    Status TEXT,
    Tracking_Number TEXT,
    FOREIGN KEY (Customer_ID) REFERENCES Customers(Customer_ID),
    FOREIGN KEY (Shipper_ID) REFERENCES Shippers(Shipper_ID)
);

-- Creating table 'Order_Detail'
CREATE TABLE Order_Detail (
    OrderDetail_ID INTEGER PRIMARY KEY,
    Order_ID INTEGER,
    Product_ID INTEGER,
    Quantity INTEGER,
    Unit_Price REAL,
    Discount REAL,
    Total_Price REAL,
    FOREIGN KEY (Order_ID) REFERENCES Orders(Order_ID),
    FOREIGN KEY (Product_ID) REFERENCES Products(Product_ID)
);

-- Creating table 'Transactions'
CREATE TABLE Transactions (
    Transaction_ID INTEGER PRIMARY KEY,
    OrderDetail_ID INTEGER,
    Customer_ID INTEGER,
    Transaction_Date DATE,
    Payment_Method TEXT,
    Amount REAL,
    Payment_Processor TEXT,
    Currency TEXT,
    FOREIGN KEY (OrderDetail_ID) REFERENCES Order_Detail(OrderDetail_ID),
    FOREIGN KEY (Customer_ID) REFERENCES Customers(Customer_ID)
);
