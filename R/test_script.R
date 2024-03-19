library(readr)
library(RSQLite)
library(dplyr)
library(wordcloud) 
#connect to the SQLite database
my_connection <- RSQLite::dbConnect(RSQLite::SQLite(),"database.db")



# Define minimum word frequency for inclusion
min_freq <- 5

# Create separate word clouds for positive, negative, and neutral reviews
positive_cloud <- wordcloud(words = reviews[reviews$rating >= 4, "review_text"] %>%
                              unlist(), scale = c(3, 0.5), colors = brewer.pal(8, "Blues"))



negative_cloud <- wordcloud(words = reviews[reviews$rating <= 2, "review_text"] %>%
                              unlist(), scale = c(3, 0.5), colors = brewer.pal(8, "Reds"))

neutral_cloud <- wordcloud(words = reviews[reviews$rating == 3, "review_text"] %>%
                             unlist(), scale = c(3, 0.5), colors = brewer.pal(8, "Greys"))

# Arrange the word clouds in a grid layout
grid.arrange(positive_cloud, negative_cloud, neutral_cloud, nrow = 1)


dbDisconnect(my_connection)