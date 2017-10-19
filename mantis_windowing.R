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

tdf1 = read_csv("FastTrackEight_wl_slow.csv")
tdf2 = read_csv("FastTrackEight_wol_slow.csv")
tdfsum = bind_rows(tdf1,tdf2)

tdfsum %>%
  colwise(na.locf)() %>%
  summary()
summary(colwise(na.locf)(tdfsum))


tdf = ddply(tdf, .(fx_code), function(x) replace(x, TRUE, lapply(x, na.locf0, TRUE)))
summary(tdf)
tdf = mutate(tdf,time = hms(time))
head(tdf$time)
max(tdf$time)
min(tdf$time)
tail(tdf$time)
names(tdfsum)
ggplot(tdf1,aes(x = as.numeric(time),y = Pressure_Hydraulic_main_mast_bar)) + geom_point(alpha = 0.8, shape = 21, size = 1.5)

#weight search
tdfsum = mutate(tdfsum,is.weight = rollapply(Pressure_Hydraulic_main_mast_bar,width = 10, mean) > 50)
