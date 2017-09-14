#file length test
library(R.matlab)
library(dplyr)
library(purrr)
library(plyr)

setwd("/home/vasy/RStudioProjects/still_github/RStudio_wd_Can_fp/")

for(file_name_i in list.files()){
  print(file_name_i)
  temp_file = readMat(file_name_i)
  #print(head(temp_file$Druck.Hubwerk..................................................))
  #print(tail(temp_file$Druck.Hubwerk..................................................))
  # print((round(
  #   max(
  #     temp_file$Druck.Hubwerk..................................................[,1]
  #   )
  #   ,digits = 2
  # )+1)*100)
  print(round(
    min(
      temp_file$Druck.Hubwerk..................................................[,1]
    )
    ,digits = 2
  )
  )
}
