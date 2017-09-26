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

df_test = as.data.frame(read.csv("/home/vasy/RStudioProjects/still_github/cleaned_files/first_filtered_boxshort.csv"))
glimpse(df_test)
summary(df_test)
print(class(na.approx(df_test)))
#look up first and last value for the interpolation

#

# NonNAindex <- which(!is.na(z))
# firstNonNA <- min(NonNAindex)

# map(function(x) t.test(x ~ Affairs$gender)$p.value)

df_test = map(df_test)


#switch remaining NA-s to inperpolated values
df_test_no_na = as.data.frame(na.approx(df_test))

#rounding?
glimpse(df_test_no_na)

df_no_na = as.data.frame(read.csv("/home/vasy/RStudioProjects/still_github/cleaned_files/first_filtered_boxshort.csv")) %>%
  map(
    function(x){
      x[1] = x[min(which(!is.na(x)))]
      x[length(x)] = x[max(which(!is.na(x)))]
    }) %>%
  as.data.frame(na.approx())

glimpse(df_no_na)



