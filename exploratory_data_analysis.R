library(readr)
library(R.matlab)
library(dplyr)
library(purrr)
library(plyr)
library(lubridate)
library(zoo)
library(reshape2)
library(ggplot2)

#PC
setwd("/home/vasy/RStudioProjects/still_github/cleaned_files/cleaned_files/")
export_location="/home/vasy/RStudioProjects/still_github/exploratory_files/"

df_container = data_frame()
first = 1

for(file_name_i in list.files())
{
  if(first)
  {
    df_container = read_csv(file_name_i)
    first = 0 
  } 
  else 
  {
    df_container = bind_rows(df_container,read_csv(file_name_i))
  }
}

glimpse(df_container)
df_container$fingerprint_type = factor(df_container$fingerprint_type)
levels(df_container$fingerprint_type)

df_container$time = hms(df_container$time)

hist(df_container$Speed_Steering_wheel_U.min)
#Steering_angle_angle
hist(df_container$Steering_angle_angle)

ggplot(df_container,aes())+geom_density() + facet_wrap(~variable, scales = 'free_x')
