library(tidyverse)
library(jsonlite)

# Load the dataset
movies <- read_csv("C:/Users/jetpa/Downloads/archive/movies_metadata.csv")

# Basic cleaning: remove missing values and low-quality entries
movies_clean <- movies %>%
  filter(!is.na(vote_average),
         !is.na(genres),
         !is.na(release_date),
         vote_average > 0,
         vote_count >= 50) %>%
  mutate(year = as.numeric(substr(release_date, 1, 4)))

# The genres column is in JSON format, so convert it to readable names
movies_genres <- movies_clean %>%
  mutate(genres = gsub("'", '"', genres)) %>%
  rowwise() %>%
  mutate(genre = list(fromJSON(genres)$name)) %>%
  unnest(genre) %>%
  ungroup()

# Calculate average rating for each genre
genre_avg <- movies_genres %>%
  group_by(genre) %>%
  summarize(
    avg_rating = mean(vote_average, na.rm = TRUE),
    count = n()
  ) %>%
  filter(count >= 50) %>%
  arrange(desc(avg_rating))

print(genre_avg)

# Bar chart showing average ratings
ggplot(genre_avg, aes(x = reorder(genre, avg_rating), y = avg_rating, fill = genre)) +
  geom_col() +
  coord_flip() +
  scale_fill_brewer(palette = "Set2") +
  labs(title = "Average Rating by Genre",
       x = "Genre",
       y = "Average Rating") +
  theme_minimal() +
  theme(legend.position = "none")

# Boxplot to show how ratings vary within each genre
ggplot(movies_genres %>% filter(genre %in% genre_avg$genre),
       aes(x = reorder(genre, vote_average), y = vote_average, fill = genre)) +
  geom_boxplot() +
  coord_flip() +
  scale_fill_brewer(palette = "Set3") +
  labs(title = "Rating Distribution by Genre",
       x = "Genre",
       y = "Rating") +
  theme_minimal() +
  theme(legend.position = "none")

# Count how many highly rated movies (7.5+) each genre has
high_rated <- movies_genres %>%
  filter(vote_average >= 7.5) %>%
  group_by(genre) %>%
  summarize(count = n()) %>%
  arrange(desc(count))

print(high_rated)

# Bar chart for highly rated movies
ggplot(high_rated, aes(x = reorder(genre, count), y = count, fill = genre)) +
  geom_col() +
  coord_flip() +
  scale_fill_brewer(palette = "Set1") +
  labs(title = "Genres with Most Highly Rated Movies",
       x = "Genre",
       y = "Number of Movies") +
  theme_minimal() +
  theme(legend.position = "none")

# Look at rating trends over time for the most common genres
top_genres <- genre_avg %>%
  slice_max(count, n = 6) %>%
  pull(genre)

ratings_time <- movies_genres %>%
  filter(!is.na(year),
         year >= 1980,
         genre %in% top_genres) %>%
  group_by(year, genre) %>%
  summarize(avg_rating = mean(vote_average, na.rm = TRUE),
            .groups = "drop")

print(ratings_time)

# Line chart showing how ratings changed over time
ggplot(ratings_time, aes(x = year, y = avg_rating, color = genre)) +
  geom_line(linewidth = 1) +
  labs(title = "Average Ratings Over Time for Major Genres",
       x = "Year",
       y = "Average Rating",
       color = "Genre") +
  theme_minimal()

