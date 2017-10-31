library(readr)
library(R.matlab)
library(dplyr)
library(purrr)
library(plyr)
library(lubridate)
library(zoo)

  setwd("/home/vasy/RStudioProjects/still_github/rds_files/")



df = read_rds("WorkCycle_slow_att.rds")

glimpse(df)
tail(df)
head(df$date_time,100)
min(diff(df$abs_trav_distance_dt))
min(df$abs_trav_distance_dt)
max(df$abs_trav_distance_dt)
head(df$abs_trav_distance_dt,100)
