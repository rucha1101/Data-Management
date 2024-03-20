library(DBI)
library(readr)
library(RSQLite)
library(ggplot2)
library(sqldf)
#library(tidyverse)
#library(tidytext)
#library(gridExtra)
library(dplyr)
library(RColorBrewer)
#install.packages("gganimate")
#library(gganimate)
#install.packages('transformr')
#library(transformr)



my_connection <- dbConnect(RSQLite::SQLite(), "database.db")

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
rypm <-
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
 
  
  # Create a filename with the plot name and the current date
  plot_name <- "rypm "
date_string <- format(Sys.Date(), "%Y%m%d")
filename <- paste0("figures/", plot_name, "_", date_string, ".jpg")

# Save the plot as a jpg file
ggsave(filename = filename, plot = rypm, device = "jpeg")

### Top 10 Products with Highest Average Discounts

# tran_prod <- left_join(x=transactions, y=products, by=join_by(product_id == product_id))

tran_prod<- merge(transactions,products, by = "product_id", all.x=TRUE, all.y = FALSE)


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
avg_disct <-
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
plot_name <- "avg_disct"
date_string <- format(Sys.Date(), "%Y%m%d")
filename <- paste0("figures/", plot_name, "_", date_string, ".jpg")

# Save the plot as a jpg file
ggsave(filename = filename, plot = avg_disct, device = "jpeg")


### Top 10 Performing Cities by Shipment

# Count shipments per city
shipment_counts <- shipment %>%
  group_by(shipment_city) %>%
  summarise(shipments = n()) %>%
  arrange(desc(shipments))

# Select top 10 performing cities
top_10_cities <- head(shipment_counts, 10)

top_10_performing_cities <- ggplot(top_10_cities, aes(x = shipment_city, y = shipments, fill = shipment_city)) +
  geom_bar(stat = "identity") +
  labs(title = "Top 10 Performing Cities by Shipment", x = "Shipment City", y = "Number of Shipments") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
plot_name <- "top_10_performing_cities"
date_string <- format(Sys.Date(), "%Y%m%d")
filename <- paste0("figures/", plot_name, "_", date_string, ".jpg")

# Save the plot as a jpg file
ggsave(filename = filename, plot = top_10_performing_cities, device = "jpeg")


### Sales Performance by State

#tran_ship <- left_join(x=transactions, y=shipment, by=join_by(transaction_id == transaction_id))

tran_ship<- merge(x=transactions,y=shipment, by = "transaction_id", all.x=TRUE, all.y = FALSE)

### Analyzing performance by shipment state

# Assuming a 'shipment_state' field
state_sales <- tran_ship %>%
  group_by(shipment_state) %>%
  summarise(total_sales = sum(total_price),
            num_transactions = n())

shipment_state <- ggplot(state_sales, aes(x = shipment_state, y = total_sales, color = num_transactions)) +
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
plot_name <- "shipment_state"
date_string <- format(Sys.Date(), "%Y%m%d")
filename <- paste0("figures/", plot_name, "_", date_string, ".jpg")

# Save the plot as a jpg file
ggsave(filename = filename, plot = shipment_state, device = "jpeg")


### Revenue by Payment Processor and Currency
transactions_grouped <- transactions %>%
  group_by(currency, payment_processor) %>%
  summarise(total_revenue = sum(total_price))

ryppc <- ggplot(transactions_grouped, aes(x = payment_processor, y = total_revenue, fill = currency)) +
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
plot_name <- "ryppc"
date_string <- format(Sys.Date(), "%Y%m%d")
filename <- paste0("figures/", plot_name, "_", date_string, ".jpg")

# Save the plot as a jpg file
ggsave(filename = filename, plot = ryppc, device = "jpeg")


### Top Products by Revenue


# Calculate total revenue per product
product_revenue <- tran_prod %>%
  group_by(product_name) %>%
  summarise(total_revenue = sum(price * quantity))

# Select top 10 products
top_10_products <- product_revenue %>%
  arrange(desc(total_revenue)) %>%
  head(10)  # Adjust 10 to show desired number of products

top_10_p <- ggplot(top_10_products, aes(x = reorder(product_name, total_revenue), y = total_revenue)) +
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
plot_name <- "top_10_p"
date_string <- format(Sys.Date(), "%Y%m%d")
filename <- paste0("figures/", plot_name, "_", date_string, ".jpg")

# Save the plot as a jpg file
ggsave(filename = filename, plot = top_10_p, device = "jpeg")
### Top 15 Products by Reviews

# Create tables to join existing ones
top_rated_products<- left_join(x=products,y=reviews, by = join_by(product_id == product_id))
top_rated_products<- top_rated_products%>%
  group_by(product_name)%>%
  summarize(average_rating = mean(rating))%>%
  arrange(desc(average_rating))%>%
  top_n(15)


top_15_pbyr = ggplot(top_rated_products, aes(x = reorder(product_name, average_rating), y = average_rating, fill = average_rating)) +
  geom_col() +
  coord_flip() +  # Horizontal bars for better readability
  labs(title = "Top 15 Rated Products", x = "Product Name", y = "Average Rating", fill = "Average Rating") +
  scale_fill_viridis_c() +
  theme_minimal()
plot_name <- "top_15_pbyr"
date_string <- format(Sys.Date(), "%Y%m%d")
filename <- paste0("figures/", plot_name, "_", date_string, ".jpg")

# Save the plot as a jpg file
ggsave(filename = filename, plot = top_15_pbyr, device = "jpeg")
### Top 15 Products by Reviews

#scale_fill_viridis_c(option = "magma")

### Revenue and Products Purchased Per Day

# Join tables
tran_prod<- left_join(transactions, products, by = join_by(product_id == product_id))

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
rev_prod_day <- ggplot(tran_prod, aes(quantity, total_price, size = discount, color = product_id, alpha = 0.5)) +
  geom_point(show.legend = FALSE) +
  scale_x_log10() +
  theme_bw() +
  # gganimate specific bits:
  labs(title = 'Revenue and Number of Products Purchased per day', x = '# Products purchased per day', y = 'Revenue generated per day')

plot_name <- "rev_prod_day"
date_string <- format(Sys.Date(), "%Y%m%d")
filename <- paste0("figures/", plot_name, "_", date_string, ".jpg")

# Save the plot as a jpg file
ggsave(filename = filename, plot = rev_prod_day, device = "jpeg")
### Top 15 Products by Reviews
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


ship_by_date <- ggplot(shipment_info, aes(x = month, y = num_shipments)) +
  geom_bar(stat = "identity",fill = "lightblue") +
  labs(title = paste("Shipments by Period"), x = "Month", y = "Number (#) of Shipments") +
  theme_minimal()+ scale_x_continuous(breaks=seq(1,12,by=1))
plot_name <- "ship_by_date"
date_string <- format(Sys.Date(), "%Y%m%d")
filename <- paste0("figures/", plot_name, "_", date_string, ".jpg")

# Save the plot as a jpg file
ggsave(filename = filename, plot = ship_by_date, device = "jpeg")
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

cat_gender <- ggplot(combo_graph, aes(x=parent_cat_desc, y = num_transactions, fill = gender)) +
  geom_bar(stat="identity", position = "dodge") +
  labs(title="Main Categories Purchased by Gender", fill = "Gender")+ labs(title = 'Most Purchased Categories by Gender', x = 'Main Category', y = 'Number (#) of Transactions')+
  scale_fill_brewer(palette = "Set3")
plot_name <- "cat_gender"
date_string <- format(Sys.Date(), "%Y%m%d")
filename <- paste0("figures/", plot_name, "_", date_string, ".jpg")

# Save the plot as a jpg file
ggsave(filename = filename, plot = cat_gender, device = "jpeg")
# For reference: 
# pcid1200	Electronics
# pcid1300	Clothing
# pcid1500	Home & Garden
# pcid1600	Telephony
# pcid1700	Furniture
#Disconnecting database connection
dbDisconnect(my_connection)
