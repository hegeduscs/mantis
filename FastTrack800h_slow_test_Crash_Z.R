library(R.matlab)
library(dplyr)
library(purrr)
library(plyr)
library(lubridate)
library(zoo)

setwd("/home/vasy/RStudioProjects/still_github/")
temp_list = readMat("Part 01  STILL Versand MultiTimeChannel.mat",sep="")


fp_df = data.frame(0:(round(max(temp_list$Druck.Hubwerk..................................................[,1])*100,digits = 2)+1000))
names(fp_df) = "ID_count"
fp_df = mutate(fp_df, time_id = 0 + ID_count * 0.01)


#box short all rows (in descending nrow order)

  w_column = "Crash.Z........................................................"
  #drop not usefull columns
  # if(
  #   w_column == "Crash.Flag....................................................." |
  #   w_column == "Crash.WD......................................................." | 
  #   w_column == "Thermo.01.K4..................................................." |
  #   w_column == "Thermo.01.K3..................................................." |
  #   w_column == "Thermo.01.K2..................................................." |
  #   w_column == "Thermo.01.K1..................................................." |
  #   w_column == "Thermo.01.K8..................................................." |
  #   w_column == "Thermo.01.K7..................................................." |
  #   w_column == "Thermo.01.K6..................................................." |
  #   w_column == "Thermo.01.K5..................................................." 
  # )
  # {
  #   print(paste(w_column," is skipped",sep=""))
  #   next()
  # }
  print(w_column)
  fp_i = 1
  #make new row in fp_df
  fp_df = mutate(fp_df, temp_col = as.numeric("NA"))
  
  #boxshort one row (round the time in the temp)
  for(row in 1:length(temp_list[[w_column]][,1]))
  {
    # #debug
    # print("row")
    # print(row)
    # print(fp_df$time_id[fp_i])
    # print(round(temp_list[[w_column]][row, 1],digits = 2))
    # print(abs(fp_df$time_id[fp_i] - round(temp_list[[w_column]][row, 1],digits = 2)))
    # print(fp_i)
    
    #boxshort core      
    while(abs(fp_df$time_id[fp_i] - round(temp_list[[w_column]][row, 1],digits = 2)) > 0.005)
    {
      # print("fp_i inside the loop")
      fp_i = fp_i + 1
      # print(fp_i)
    }
    
    fp_df$temp_col[fp_i] = temp_list[[w_column]][row, 2]
  }
  #rename temp_col to actual colname (df ready for the new mutate)
  names(fp_df) = gsub("temp_col",w_column,names(fp_df))
  warnings()
