#ramping event
library(readr)
library(R.matlab)
library(dplyr)
library(purrr)
library(plyr)
library(lubridate)
library(zoo)
library(ggplot2)
library(stringr)
library(RcppRoll)

#PC
setwd("/home/vasy/RStudioProjects/still_github/cleaned_files/cleaned_files/")
export_location="/home/vasy/RStudioProjects/still_github/exploratory_files/"

tdf1 = read_csv("Ramp_wl_fast.csv")
tdf2 = read_csv("Ramp_wol_fast.csv")
tdf3 = read_csv("Ramp_wl_slow.csv")
tdf4 = read_csv("Ramp_wol_slow.csv")

tdfsum = bind_rows(tdf1,tdf2,tdf3,tdf4)

tdfsum = tdfsum %>%
  colwise(na.locf)() 

summary(tdfsum)
tdfsum = tdfsum%>%
mutate(fast.slow = factor(str_detect(fingerprint_type,"fast"))) %>%
  mutate(wl.wol = factor(str_detect(fingerprint_type,"_wl_"))) %>%
  mutate(time = hms(time)) %>%
  mutate(fingerprint_type = factor(fingerprint_type))
glimpse(tdfsum)

ggplot(tdfsum,aes(x=time_ID_s,y=Crash_Z_0.01g,color = fast.slow,fill = wl.wol)) + geom_point(alpha = 0.5, shape = 21, size = 1.5) + facet_wrap(~fingerprint_type)
