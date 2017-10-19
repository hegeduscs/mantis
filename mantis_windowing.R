#still mantis windowing
library(readr)
library(R.matlab)
library(dplyr)
library(purrr)
library(plyr)
library(lubridate)
library(zoo)
library(ggplot2)
library(stringr)
library(GGally)

#PC
setwd("/home/vasy/RStudioProjects/still_github/cleaned_files/cleaned_files/")
export_location="/home/vasy/RStudioProjects/still_github/exploratory_files/"

for(file_name_i in list.files())
{
  test_df= read_csv(file_name_i)
  test_df2 = na.locf(test_df,fromLast = TRUE)
  print(file_name_i)
  print(summary(test_df))
  print(summary(test_df2))
}



