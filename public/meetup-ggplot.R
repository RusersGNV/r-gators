# Install the package 'tidyverse' if you haven't already
install.packages("tidyverse")

# Load the package into your library
library(tidyverse)

# Download the data file we're using today
download.file("http://r-gators.com/weather.csv", "weather.csv")

# Temperature and Precipitation of Gainesville from 1984 - 2017
# organized according to season
weather <- read.csv("weather.csv")

# ggplot
# Season vs Temp
ggplot(weather, aes(x=SEASON, y=TEMP)) +
  geom_boxplot()

boxplot(TEMP ~ SEASON, data = weather) # base R plot example

ggplot(weather, aes(x=PRECIP)) +
  geom_histogram()

# Points and lines graph
# Year vs Temp/Precip
ggplot(weather, aes(x=YEAR, y=TEMP)) +
  geom_point()

ggplot(weather, aes(x=YEAR, y=TEMP)) +
  geom_point() +
  geom_line()

ggplot(weather, aes(x=YEAR, y=TEMP, col=SEASON, pch=SEASON, lty=SEASON)) +
  geom_point() +
  geom_line()

# Season-specific temperature trend
weather %>%
  filter(SEASON == "Summer")
filter(weather, SEASON == "Summer")

weather %>%
  filter(SEASON == "Summer") %>%
  ggplot(aes(x=YEAR, y=TEMP)) +
  geom_line()

# Plot trendline
weather %>%
  filter(SEASON == "Summer") %>%
  ggplot(aes(x=YEAR, y=TEMP)) +
  geom_line() +
  geom_smooth(method = "lm")

weather %>%
  filter(SEASON == "Summer") %>%
  ggplot(aes(x=YEAR, y=TEMP)) +
  geom_line() +
  geom_smooth(method = "loess")

weather %>%
  filter(SEASON == "Summer") %>%
  ggplot(aes(x=YEAR, y=PRECIP)) +
  geom_line() +
  geom_smooth(method = "loess")

# Annual temperature & precipitation
weatherYear <- weather %>%
  group_by(YEAR) %>%
  summarise(TEMP = mean(TEMP), PRECIP = sum(PRECIP))

# Anomaly = Temperature of each year - mean(Temperature) over 33 years
aveTemp <- mean(weatherYear$TEMP)
weatherYear <- weatherYear %>%
  mutate(TEMPANOM=TEMP-aveTemp)
ggplot(weatherYear, aes(x=YEAR, y=TEMPANOM)) +
  geom_point() +
  geom_line() +
  geom_smooth(se=F)

# Redo season specific trend
weather %>%
  filter(SEASON == "Summer") %>%
  ggplot(aes(x=YEAR, y=TEMP)) +
  geom_line()

weather %>%
  filter(SEASON == "Spring") %>%
  ggplot(aes(x=YEAR, y=TEMP)) +
  geom_line()

# Facetting
# What if I want four season graphs side by side?
ggplot(weather, aes(x=YEAR, y=TEMP)) +
  geom_line() +
  facet_wrap(~ SEASON, scales = "free_y") +
  xlab("Year") +
  ylab("Temperature") +
  ggtitle("ABC123") +
  theme_bw()
