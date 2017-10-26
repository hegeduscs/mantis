#new_still_files_explore_201710
library(R.matlab)
library(dplyr)
library(purrr)
library(plyr)
library(lubridate)
library(zoo)

setwd("/home/vasy/RStudioProjects/still_github/new_still_files_201710/tobatman_newstill/")

list.files()

file.info("Part 03 Imperial_D_00125_MultiTimeChannel.mat")$size

x = readMat("Part 03 Imperial_D_00125_MultiTimeChannel.mat",maxLength =file.info("Part 03 Imperial_D_00125_MultiTimeChannel.mat")$size/100)

file.info("Part 03 Imperial_D_00125_MultiTimeChannel.mat")$size/10

