library(DBI)
library(readr)
library(RSQLite)
library(ggplot2)
library(sqldf)
#library(tidyverse)
library(tidytext)
library(gridExtra)
library(dplyr)
library(RColorBrewer)
#install.packages("gganimate")
library(gganimate)
#install.packages('transformr')
library(transformr)



my_connection <- dbConnect(RSQLite::SQLite(), "database.db")

append_csv_to_table <- function(file_path, connection) {
  file_name <- basename(file_path)
  table_name <- tolower(sub("([A-Za-z]+)[_\\.].*", "\\1", file_name))
  
  data <- read_csv(file_path, show_col_types = FALSE)
  
  tryCatch({
    if(!dbExistsTable(connection, table_name)) {
      stop(paste("Table does not exist and schema creation is required:", table_name))
    }
    dbWriteTable(connection, table_name, data, append = TRUE, row.names = FALSE)
    message(paste("Successfully appended", file_name, "to the", table_name, "table."))
  }, error = function(e) {
    message(paste("Failed to append", file_name, "to the", table_name, "table:", e$message))
  })
}


all_files <- list.files(path = "data_upload", pattern = "\\.csv$", full.names = TRUE)
lapply(all_files, append_csv_to_table, my_connection)



# Count for all tables
display_table_counts <- function(connection) {
  # Retrieve table names
  tables_query <- "SELECT name FROM sqlite_master WHERE type='table';"
  tables <- dbGetQuery(connection, tables_query)$name
  
  if(length(tables) > 0) {
    for (table_name in tables) {
      count_query <- paste0("SELECT COUNT(*) AS count FROM ", table_name, ";")
      count <- dbGetQuery(connection, count_query)$count
      cat(table_name, ": ", count, "\n", sep = "")
    }
  } else {
    cat("No tables found in the database.\n")
  }
}

# Display table counts
display_table_counts(my_connection)


# VALIDATION CODE
customers_path <- "data_upload/customers.csv"
shipment_path <- "data_upload/shipment.csv"
transactiondetails_path  <- "data_upload/transactiondetails.csv"
reviews_path <- "data_upload/reviews.csv"
suppliers_path <- "data_upload/suppliers.csv"
categories_path <- "data_upload/categories.csv"
products_path <- "data_upload/products.csv"
categories_data <- read_csv(categories_path, show_col_types = FALSE)
products_data <- read_csv(products_path, show_col_types = FALSE)
transactiondetails_data <- read_csv(transactiondetails_path, show_col_types = FALSE)
reviews_data <- read_csv(reviews_path, show_col_types = FALSE)
suppliers_data <- read_csv(suppliers_path, show_col_types = FALSE)
customers_data <- read_csv(customers_path, show_col_types = FALSE)
shipment_data <- read_csv(shipment_path, show_col_types = FALSE)

# List of all data frames
data_frames <- list(categories_data, products_data, transactiondetails_data, reviews_data, suppliers_data, customers_data, shipment_data)

# Names of all data frames
data_frame_names <- c("categories_data", "products_data", "transactiondetails_data", "reviews_data", "suppliers_data", "customers_data", "shipment_data")


#Security Checks
# Function to check for SQL injection
check_sql_injection <- function(input_data) {
  # Define a list of forbidden SQL keywords
  forbidden_keywords <- c("SELECT", "INSERT", "UPDATE", "DELETE", "DROP", "ALTER", "CREATE", "TRUNCATE", "UNION", "JOIN", "FROM", "WHERE")
  
  # Check if input contains any forbidden keywords
  if (any(str_detect(tolower(input_data), paste0("\\b", forbidden_keywords, "\\b")))) {
    return(FALSE) # SQL injection detected
  } else {
    return(TRUE) # No SQL injection detected
  }
}

# Function to check for XSS (Cross-Site Scripting) prevention
check_xss_prevention <- function(input_data) {
  # Define a list of HTML tags and attributes to block
  forbidden_tags <- c("script", "iframe", "img", "onload", "onerror", "onclick", "onmouseover", "onmouseout")
  
  # Check if input contains any forbidden tags or attributes
  if (any(str_detect(tolower(input_data), paste0("<", forbidden_tags, ">")))) {
    return(FALSE) # XSS vulnerability detected
  } else {
    return(TRUE) # No XSS vulnerability detected
  }
}



# Loop through each data frame
for (i in seq_along(data_frames)) {
  # Perform security checks on each column
  for (col in colnames(data_frames[[i]])) {
    # Check for SQL injection
    if (!all(sapply(data_frames[[i]][[col]], check_sql_injection))) {
      cat("SQL injection detected in column:", col, "of", data_frame_names[i], "\n")
    }
    
    # Check for XSS prevention
    if (!all(sapply(data_frames[[i]][[col]], check_xss_prevention))) {
      cat("XSS vulnerability detected in column:", col, "of", data_frame_names[i], "\n")
    }
  }
}






#Duplicate and NA value check
# Loop through each data frame
for (i in seq_along(data_frames)) {
  # Check for duplicate rows
  if (anyDuplicated(data_frames[[i]])) {
    stop(paste("DUPLICATE ROWS DETECTED in", data_frame_names[i]))
  }
  
  # Check for NA values
  if (any(is.na(data_frames[[i]]))) {
    stop(paste("NA VALUES DETECTED in", data_frame_names[i]))
  }
  
  # If no issues found
  message(paste("VALIDATION SUCCESSFUL:", data_frame_names[i], "checked."))
}

if(file.exists(categories_path) && file.exists(products_path)) {
  
  
  # Using SQL query with sqldf
  missing_product_ids <- sqldf("SELECT c.product_id
                                FROM categories_data c
                                LEFT JOIN products_data p ON c.product_id = p.product_id
                                WHERE p.product_id IS NULL")
  
  error_block <- if(nrow(missing_product_ids) > 0) {
    stop(paste("There are product IDs in 'categories' that don't exist in 'products'. Data insertion halted."))
  }
  else {
    message("VALIDATION SUCCESSFUL!!!: All product IDs in 'categories' exist in 'products'")
    
  }
}

#Data Integrity Checks
# Check for unique customer IDs
if (length(unique(customers_data$customer_id)) != nrow(customers_data)) {
  stop(paste("Customer IDs are not unique."))
} else {
  message("VALIDATION SUCCESSFUL: Customer IDs are unique")
}


# Check for unique product IDs
if (length(unique(products_data$product_id)) != nrow(products_data)) {
  stop(paste("Product IDs are not unique."))
} else {
  message("VALIDATION SUCCESSFUL: Product_IDs are unique")
}


# Check for unique product IDs in category table
if (length(unique(categories_data$product_id)) != nrow(categories_data)) {
  stop(paste("Product IDs are not unique in category table"))
} else {
  message("VALIDATION SUCCESSFUL: Product_IDs are unique in category table")
}

# Check for shipment primary Key
if (length(unique(shipment_data$transaction_id)) != nrow(shipment_data)) {
  stop(paste("Shipment data primary key not unique"))
} else {
  message("VALIDATION SUCCESSFUL: Shipment data primary key is unique")
}

# Check for Supplier Primary Key
if (length(unique(paste(suppliers_data$supplier_id, suppliers_data$product_id))) != nrow(suppliers_data)) {
  stop(paste("Supplier data primary key not unique"))
} else {
  message("VALIDATION SUCCESSFUL: Supplier data primary key is unique")
}

# Check for unique Review IDs
if (length(unique(reviews_data$review_id)) != nrow(reviews_data)) {
  stop(paste("Review IDs are not unique"))
} else {
  message("VALIDATION SUCCESSFUL: Review IDs are unique")
}

# Check for Transactiondetail Primary Key
if (length(unique(paste(transactiondetails_data$transaction_id, transactiondetails_data$customer_id, transactiondetails_data$product_id))) != nrow(transactiondetails_data)) {
  stop(paste("Transaction data primary key not unique"))
} else {
  message("VALIDATION SUCCESSFUL: Transaction data primary key is unique")
}

#Referential Checks
# Referential Integrity Check: Customer Existence in Transaction Detail
# if (any(!transactiondetails_data$customer_id %in% customers_data$customer_id)) {
#   stop("Invalid customer IDs in transaction_detail table!")
# } else {
#   message("Referential Integrity Checked: Customer Existence in Transaction Detail")
# }

# Referential Integrity Check: Product Existence in Transaction Detail
if (any(!transactiondetails_data$product_id %in% products_data$product_id)) {
  stop("Invalid product IDs in transaction_detail table!")
} else {
  message("Referential Integrity Checked: Product Existence in Transaction Detail")
}

# Referential Integrity Check: Product Existence in Reviews
if (any(!reviews_data$product_id %in% products_data$product_id)) {
  stop("Invalid product IDs in reviews table!")
} else {
  message("Referential Integrity Checked: Product Existence in Reviews")
}

# Referential Integrity Check: Customer Existence in Reviews
# if (any(!reviews_data$customer_id %in% customers_data$customer_id)) {
#   stop("Invalid customer IDs in reviews table!")
# } else {
#   message("Referential Integrity Checked: Customer Existence in Reviews")
# }

# Referential Integrity Check: Product Existence in Categories
if (any(!categories_data$product_id %in% products_data$product_id)) {
  stop("Invalid product IDs in categories table!")
} else {
  message("Referential Integrity Checked: Product Existence in Categories")
}

# Group by category_id and summarise the number of unique parent_category_id
category_parent <- categories_data %>%
  group_by(category_id) %>%
  summarise(n_unique_parent = n_distinct(parent_category_id))

# Check if any category_id has more than one unique parent_category_id
if (any(category_parent$n_unique_parent > 1)) {
  stop("Some categories correspond to more than one parent category!")
} else {
  message("Referential Integrity Checked: Category_id having more than one unique parent_category_id")
}


# Referential Integrity Check: Product Existence in Suppliers
if (any(!suppliers_data$product_id %in% products_data$product_id)) {
  stop("Invalid product IDs in suppliers table!")
} else {
  message("Referential Integrity Checked: Product Existence in Suppliers")
}


# Referential Integrity Check: Transaction Existence in Shipment
if (any(!shipment_data$transaction_id %in% transactiondetails_data$transaction_id)) {
  stop("Invalid transaction IDs in shipment table!")
} else {
  message("Referential Integrity Checked: Transaction Existence in Shipment")
}


# Field-Level Validations

# Check email format
if (!all(grepl("^\\S+@\\S+\\.\\S+$", customers_data$cx_email)) | 
    any(grepl("@.*[0-9]", customers_data$cx_email))) {
  stop("Invalid email format in customer data.")
} else {
  message("VALIDATION SUCCESSFUL: Customer emails checked.")
}

# if (!all(grepl("^\\S+@\\S+\\.\\S+$", suppliers_data$supplier_email)) | 
#     any(grepl("@.*[0-9]", suppliers_data$supplier_email))) {
#   stop("Invalid email format in supplier data.")
# } else {
#   message("VALIDATION SUCCESSFUL: Supplier emails checked.")
# }

# Check phone number format
if (!all(grepl("^\\d{3}-\\d{3}-\\d{4}$", customers_data$cx_phone_number))) {
  stop("Invalid phone number format in customer data.")
} else {
  message("VALIDATION SUCCESSFUL: Customer numbers checked.")
}


# Check date formats
if (!all(is.na(as.Date(customers_data$last_login_date, "%mm/%dd/%YYYY")))) {
  stop("Invalid last login date format.")
} else {
  message("VALIDATION SUCCESSFUL: Last login date checked.")
}

if (!all(is.na(as.Date(customers_data$date_of_birth, "%mm/%dd/%YYYY")))) {
  stop("Invalid birth date format.")
} else {
  message("VALIDATION SUCCESSFUL: Customer birth_dates checked.")
}

if (!all(is.na(as.Date(shipment_data$shipment_date, "%mm/%dd/%YYYY")))) {
  stop("Invalid shipment date format.")
} else {
  message("VALIDATION SUCCESSFUL: Shipment dates checked.")
}

if (!all(is.na(as.Date(reviews_data$review_date, "%mm/%dd/%YYYY")))) {
  stop("Invalid review date format.")
} else {
  message("VALIDATION SUCCESSFUL: Review dates checked.")
}

if (!all(is.na(as.Date(transactiondetails_data$transaction_date, "%mm/%dd/%YYYY")))) {
  stop("Invalid review date format.")
} else {
  message("VALIDATION SUCCESSFUL: Transaction dates checked.")
}



#Check for currency format
if (!all(nchar(as.character(transactiondetails_data$currency)) == 3 & grepl("^[A-Z]{3}$", transactiondetails_data$currency))) {
  stop("Invalid currency format.")
} else {
  message("VALIDATION SUCCESSFUL: Currency codes checked.")
}


#Business Rule Checks
#Check for positive integer in transaction quantity
if (!all(grepl("^\\d+$", transactiondetails_data$quantity))) {
  stop("Invalid quantity format in transaction details.")
} else {
  message("VALIDATION SUCCESSFUL: Quantity numbers checked.")
}

#Check for positive weight in product data
if (any(products_data$weight < 0)) {
  stop("Invalid weight values in product data.")
} else {
  message("VALIDATION SUCCESSFUL: Product weights checked.")
}

#Checking for review dates in the future
current_date <- Sys.Date()
# Check if review_date is in the future
if (any(as.Date(reviews_data$review_date, "%m/%d/%Y") >= current_date)) {
  stop("Invalid dates: Review date is in the future.")
} else {
  message("VALIDATION SUCCESSFUL: Review dates checked.")
}


# Check if price is non-negative in product data
if (any(products_data$price < 0)) {
  stop("Invalid price values in product data.")
} else {
  message("VALIDATION SUCCESSFUL: Product prices checked.")
}

#Check for non-negative total_price in transaction data
if (any(transactiondetails_data$total_price < 0)) {
  stop("Invalid price values in transaction data.")
} else {
  message("VALIDATION SUCCESSFUL: Transaction prices checked.")
}
# Check if discount is non-negative in transaction data
if (any(transactiondetails_data$discount < 0)) {
  stop("Invalid discount values in product data.")
} else {
  message("VALIDATION SUCCESSFUL: Product prices checked.")
}




#Visualisation

categories  <- dbGetQuery(my_connection, "SELECT * FROM categories")
products <- dbGetQuery(my_connection, "SELECT * FROM products")
shipment <- dbGetQuery(my_connection, "SELECT * FROM shipment")
transactions <- dbGetQuery(my_connection, "SELECT * FROM transactiondetails")
customers <- dbGetQuery(my_connection, "SELECT * FROM customers")
reviews <- dbGetQuery(my_connection, "SELECT * FROM reviews")
suppliers <- dbGetQuery(my_connection, "SELECT * FROM suppliers")


### Revenue by Payment Method (Within Category)
transactions$payment_category <- ifelse(grepl("Credit Card", transactions$payment_method), "Credit Card", transactions$payment_method)

ggplot(transactions, aes(x = payment_category, fill = payment_method, y = total_price)) +
  geom_bar(stat = "identity", position = "dodge") + 
  labs(title = "Revenue by Payment Method (Within Category)", x = "Payment Category", y = "Total Revenue", fill = "Payment Method") +
  theme_bw() +
  coord_flip() + 
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    plot.title = element_text(hjust = 0.5),  
    legend.title = element_text(face = "bold")
  )

### Top 10 Products with Highest Average Discounts

tran_prod <- left_join(x=transactions, y=products, by=join_by(product_id == product_id))

high_discount_products <- transactions %>%
  left_join(products, by = "product_id") %>% 
  group_by(product_id, product_name) %>% 
  summarise(
    average_discount = mean(discount), 
    average_discounted_price = mean(price * (1 - discount/100))
  )

# Sort data by average discount in descending order (top 10)
top_discounts <- high_discount_products %>%
  arrange(desc(average_discount)) %>%
  head(10)

ggplot(top_discounts, aes(x = product_name, y = average_discount)) +
  geom_bar(stat = "identity", aes(fill = product_name), color = "black") + 
  labs(title = "Top 10 Products with Highest Average Discounts", x = "Product Name", y = "Average Discount (%)") +
  theme_bw() +  
  scale_fill_brewer(palette = "Set3") +  
  coord_flip() + 
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),  
    plot.title = element_text(hjust = 0.5),  
    legend.title = element_text(face = "bold")  
  )

### Top 10 Performing Cities by Shipment

# Count shipments per city
shipment_counts <- shipment %>%
  group_by(shipment_city) %>%
  summarise(shipments = n()) %>%
  arrange(desc(shipments))  

# Select top 10 performing cities
top_10_cities <- head(shipment_counts, 10)

ggplot(top_10_cities, aes(x = shipment_city, y = shipments, fill = shipment_city)) +
  geom_bar(stat = "identity") + 
  labs(title = "Top 10 Performing Cities by Shipment", x = "Shipment City", y = "Number of Shipments") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))  

### Sales Performance by State

tran_ship <- left_join(x=transactions, y=shipment, by=join_by(transaction_id == transaction_id))

### Analyzing performance by shipment state

# Assuming a 'shipment_state' field
state_sales <- tran_ship %>%
  group_by(shipment_state) %>%
  summarise(total_sales = sum(total_price), 
            num_transactions = n())

ggplot(state_sales, aes(x = shipment_state, y = total_sales, color = num_transactions)) +
  geom_point(size = 5, shape = 21, fill = "white") + 
  labs(title = "Sales Performance by State", x = "Shipment State", y = "Total Sales", color = "Number of Transactions") +
  theme_bw() +  
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),  
    plot.title = element_text(hjust = 0.5),  
    legend.title = element_text("Transaction Count"),  
    legend.position = "bottom"  
  ) +
  scale_color_viridis_c()  


### Revenue by Payment Processor and Currency
transactions_grouped <- transactions %>%
  group_by(currency, payment_processor) %>%
  summarise(total_revenue = sum(total_price))

ggplot(transactions_grouped, aes(x = payment_processor, y = total_revenue, fill = currency)) +
  geom_bar(stat = "identity", position = "dodge") +  # Dodge bars to avoid overlap
  labs(title = "Revenue by Payment Processor and Currency", x = "Payment Processor", y = "Total Revenue", fill = "Currency") +
  theme_minimal() +
  theme(
    plot.margin = margin(10, 10, 10, 10),
    axis.text.x = element_text(angle = 45, hjust = 1),  # Rotate x-axis labels if needed
    axis.text.y = element_text(size = 10, color = "black"),
    axis.title.x = element_text(size = 12, color = "black", face = "bold"),
    axis.title.y = element_text(size = 12, color = "black", face = "bold"),
    legend.title = element_text(size = 10, color = "black", face = "bold"),
    legend.text = element_text(size = 8, color = "black"),
    legend.key.size = unit(1, "cm")
  )


### Top Products by Revenue


# Calculate total revenue per product
product_revenue <- tran_prod %>%
  group_by(product_name) %>%
  summarise(total_revenue = sum(price * quantity))

# Select top 10 products
top_10_products <- product_revenue %>%
  arrange(desc(total_revenue)) %>%
  head(10)  # Adjust 10 to show desired number of products

ggplot(top_10_products, aes(x = reorder(product_name, total_revenue), y = total_revenue)) +
  geom_bar(stat = "identity", fill = "skyblue") +  # Set a fill color
  labs(title = "Top 10 Products by Revenue", x = "Product Name", y = "Total Revenue") +  
  coord_flip() +  
  theme_bw() +  
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),  
    plot.title = element_text(hjust = 0.5),  
    axis.text.y = element_text(size = 10, color = "black"),  
    axis.title.x = element_text(size = 12, color = "black", face = "bold"),  
    axis.title.y = element_text(size = 12, color = "black", face = "bold"),  
    strip.background = element_rect(fill = "white"), 
    legend.position = "bottom" 
  )

### Top 15 Products by Reviews

# Create tables to join existing ones
top_rated_products<- left_join(x=products,y=reviews, by = join_by(product_id == product_id))
top_rated_products<- top_rated_products%>%
  group_by(product_name)%>%
  summarize(average_rating = mean(rating))%>%
  arrange(desc(average_rating))%>%
  top_n(15)


ggplot(top_rated_products, aes(x = reorder(product_name, average_rating), y = average_rating, fill = average_rating)) +
  geom_col() +
  coord_flip() +  # Horizontal bars for better readability
  labs(title = "Top 15 Rated Products", x = "Product Name", y = "Average Rating", fill = "Average Rating") +
  scale_fill_viridis_c() + 
  theme_minimal()

#scale_fill_viridis_c(option = "magma")

### Revenue and Products Purchased Per Day 

# Join tables 
tran_prod<- left_join(x=transactions,y=products, by = join_by(product_id == product_id))

# Summarize data based on joint table

prod_byday<- tran_prod%>%
  group_by(transaction_date)%>%
  summarize(num_prod_day = sum(quantity), 
            total_revenue_day = sum(total_price), 
            average_revenue = mean(total_price))


prod_byday$transaction_date<-as.Date(prod_byday$transaction_date)
class(prod_byday$transaction_date)

tran_prod$transaction_date<-as.Date(tran_prod$transaction_date)
class(tran_prod$transaction_date)


# By Day 
ggplot(tran_prod, aes(quantity, total_price, size = discount, color = product_id, alpha = 0.5)) +
  geom_point(show.legend = FALSE) +
  scale_x_log10() +
  theme_bw() +
  # gganimate specific bits:
  labs(title = 'Revenue and Number of Products Purchased per day', x = '# Products purchased per day', y = 'Revenue generated per day')

# This represents the number of products purchased, revenue and average revenue per day by product

details<-tran_prod%>%
  group_by(product_id)%>%
  summarize(max_quant = max(quantity), 
            min_quant = min(quantity), 
            max_rev = max(total_price), 
            min_rev = min(total_price))

max(details$max_quant)
max(details$max_rev)

min(details$min_quant)
min(details$min_rev)


### Shipments by Date (Month)


# Check shipment date class

class(shipment$shipment_date)

shipment$shipment_date<- as.Date(shipment$shipment_date,"%m/%d/%Y")

# Summarize data to get number (#) of shipments 
shipment_info<- shipment%>%
  mutate(month = as.numeric(format(shipment_date, "%m")))%>%
  group_by(month)%>%
  summarize(num_shipments= n())


ggplot(shipment_info, aes(x = month, y = num_shipments)) +
  geom_bar(stat = "identity",fill = "lightblue") +
  labs(title = paste("Shipments by Period"), x = "Month", y = "Number (#) of Shipments") +
  theme_minimal()+ scale_x_continuous(breaks=seq(1,12,by=1))

### Most purchased categories by gender 

combo<- left_join(x=tran_prod,y=customers, by = join_by(customer_id == customer_id))
combo<- left_join(x=combo,y=categories, by = join_by(product_id == product_id))

# Summarize table to get number of transactions made
combo_graph<- combo%>%
  group_by(gender, transaction_id, parent_category_id)%>%
  summarize(num_transactions = n())


# Aggregate table further to simplify
combo_graph<-aggregate(cbind(num_transactions)~ gender + parent_category_id, data = combo_graph, sum)

combo_graph<- combo_graph%>%
  mutate(parent_cat_desc= ifelse(parent_category_id=="pcid1200", "Electronics", 
                                 ifelse(parent_category_id=="pcid1300", "Clothing", 
                                        ifelse(parent_category_id=="pcid1500", "Home & Garden",
                                               ifelse(parent_category_id=="pcid1600", "Telephony", "Furniture"))))) 


# Graph of purchased categories by gender: jitters

ggplot(combo_graph, aes(x=parent_cat_desc, y = num_transactions, fill = gender)) +
  geom_bar(stat="identity", position = "dodge") + 
  labs(title="Main Categories Purchased by Gender", fill = "Gender")+ labs(title = 'Most Purchased Categories by Gender', x = 'Main Category', y = 'Number (#) of Transactions')+
  scale_fill_brewer(palette = "Set3")

# For reference: 
# pcid1200	Electronics
# pcid1300	Clothing
# pcid1500	Home & Garden
# pcid1600	Telephony
# pcid1700	Furniture

dbDisconnect(my_connection)

