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
#glimpse(df_test)

#switch remaining NA-s to inperpolated values
df_test_no_na = as.data.frame(na.approx(df_test))

#glimpse(df_test)

#correct time related values (no value after decimal needed)
df_test_no_na = mutate(df_test_no_na,Second[s] = floor(Second[s]),Minute[m] = floor(Minute[m]),Hour[h] = floor(Hour[h]),Day[d] = floor(Day[d]),Month[mo] = floor(Month[mo]),Year[y] = floor(Year[y]))

format(round(1.20, 5), nsmall = 0)

format(1.23,nsmall = 0)
format(1.83,nsmall = 0)


df_test_no_na = mutate(df_test_no_na,date = ymd(paste(A0.Jahr........................................................,A1.Monat.......................................................,A2.Tag.........................................................)))


df_test_no_na = mutate(df_test_no_na,factor_test = factor("asd"))


