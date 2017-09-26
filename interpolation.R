#interpolation

# separete time related values from physical values
# correct first, and last NA if any in each column in each df
# merge the two data frames
# no.approx

library(R.matlab)
library(dplyr)
library(purrr)
library(plyr)
library(lubridate)
library(zoo)

#glimpse(df_test)
#summary(df_test)
#print(class(na.approx(df_test)))
#look up first and last value for the interpolation
df_test = as.data.frame(read.csv("/home/vasy/RStudioProjects/still_github/cleaned_files/first_filtered_boxshort.csv"))
glimpse(df_test)
for(col in names(df_test))
{
  df_test[[col]][1] = df_test[[col]][min(which(!is.na(df_test[[col]])))]
  df_test[[col]][length(df_test[[col]])] = df_test[[col]][max(which(!is.na(df_test[[col]])))]
}
glimpse(df_test)

#switch remaining NA-s to inperpolated values
df_test_no_na = as.data.frame(na.approx(df_test))
glimpse(df_test)

#rounding?

df_test = as.data.frame(read.csv("/home/vasy/RStudioProjects/still_github/cleaned_files/first_filtered_boxshort.csv"))
glimpse(df_test)
for(col in names(df_test))
{
  df_test[[col]][1] = df_test[[col]][min(which(!is.na(df_test[[col]])))]
  df_test[[col]][length(df_test[[col]])] = df_test[[col]][max(which(!is.na(df_test[[col]])))]
}
glimpse(df_test)


df_no_na = as.data.frame(read.csv("/home/vasy/RStudioProjects/still_github/cleaned_files/first_filtered_boxshort.csv"))
glimpse(df_no_na)

df_no_na = as.data.frame(read.csv("/home/vasy/RStudioProjects/still_github/cleaned_files/first_filtered_boxshort.csv")) %>%
  mutate(
    ~{
      .[1] = .[min(which(!is.na(.)))]
      .[-1] = .[max(which(!is.na(.)))]
    }) %>%
  #na.approx() %>%
  as.data.frame()

glimpse(df_no_na)

df_no_na = as.data.frame(read.csv("/home/vasy/RStudioProjects/still_github/cleaned_files/first_filtered_boxshort.csv")) %>%
  map(
    function(.){
    print(.[-1])
    }) %>%
  as.data.frame(na.approx())

glimpse(df_no_na)





