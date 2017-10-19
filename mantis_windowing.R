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
library(RcppRoll)

#PC
setwd("/home/vasy/RStudioProjects/still_github/cleaned_files/cleaned_files/")
export_location="/home/vasy/RStudioProjects/still_github/exploratory_files/"

tdf1 = read_csv("FastTrackEight_wl_slow.csv")
tdf2 = read_csv("FastTrackEight_wol_slow.csv")
tdfsum = bind_rows(tdf1,tdf2)

tdfsum = tdfsum %>%
  colwise(na.locf)() 

summary(colwise(na.locf)(tdfsum))


summary(tdfsum)
tdf = mutate(tdf,time = hms(time))
head(tdf$time)
max(tdf$time)
min(tdf$time)
tail(tdf$time)
names(tdfsum)
ggplot(tdf1,aes(x = as.numeric(time),y = Pressure_Hydraulic_main_mast_bar)) + geom_point(alpha = 0.8, shape = 21, size = 1.5)

#windowing search

#window width
w_width = 10
if(w_width%%2!=0)
  print("Must be even!")

tdfsum = mutate(
  tdfsum,
  weight_mean = c(rep(0,w_width/2),
                  roll_mean(Pressure_Hydraulic_main_mast_bar,w_width,fill = numeric(0),align = "center"),
                  rep(0,w_width/2-1)
                  )
                )

length(tdfsum$Pressure_Hydraulic_main_mast_bar)
length(roll_mean(tdfsum$Pressure_Hydraulic_main_mast_bar,10,fill = numeric(0),align = "center"))
#coerce nulls

