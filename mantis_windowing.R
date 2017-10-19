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

tdf = read_csv("WorkCycle_slow.csv")

tdf = ddply(tdf, .(fx_code), function(x) replace(x, TRUE, lapply(x, na.locf0, TRUE)))
summary(tdf)
tdf = mutate(tdf,time = hms(time))
head(tdf$time)
max(tdf$time)
min(tdf$time)
tail(tdf$time)
names(tdf)
ggplot(tdf,aes(x = as.numeric(time),y = Lever_position_lifting_mV_base_4000mV)) + geom_point(alpha = 0.1, shape = 21, size = 1.5)
