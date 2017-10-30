#group_by summarise test
library(R.matlab)
library(dplyr)
library(purrr)
library(plyr)
library(lubridate)
library(zoo)
library(readr)
library(ggplot2)
library(stringr)
library(RcppRoll)

Ramp_wl_fast <- read_csv("~/RStudioProjects/still_github/cleaned_files/cleaned_files/Shunt_fast.csv")

df = as.tbl(as.data.frame(Ramp_wl_fast))



df_sum_mean = df %>%
  mutate(date_time = as.POSIXct(ymd_hms(paste(date,hms(time),sep = ",") ))) %>%
  select(-X1,-time_ID_s,-date,-time) %>%
  group_by(date_time) %>%
  summarise_all(mean,na.rm = TRUE) %>%
  mutate(fingerprint_type = file_name_i)


glimpse(df_sum_mean)
summary(df_sum_mean)
head(df_sum_mean)

summary(df)
