#interpolation
library(R.matlab)
library(dplyr)
library(purrr)
library(plyr)
library(lubridate)

temp_list = readMat("/home/vasy/RStudioProjects/still_github/RStudio_wd_Can_fp/800hTestDrive_fast.mat",sep="")
names(temp_list)

fp_df = select(temp_list,
               -starts_with("Crash_Flag"),
               -starts_with("Crash_WD"),
               -starts_with("Thermo_01_K"))