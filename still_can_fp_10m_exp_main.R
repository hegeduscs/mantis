#Still CAN fingerprint 10m experiments - Vass Bence
library(R.matlab)
library(dplyr)
library(purrr)
library(plyr)
library(lubridate)
library(zoo)

#where the files to be boxshorted

#PAKS3 (batman)
setwd("/home/vassb/RStudio_wd_Can_fp/")
export_location="/home/vassb/cleaned_files/"

#PC
#setwd("/home/vasy/RStudioProjects/still_github/RStudio_wd_Can_fp/")
#export_location="/home/vasy/RStudioProjects/still_github/cleaned_files/"

#Cut of ".mat" for classification categories
wd_filenames = list.files()

for(i in 1:length(wd_filenames)){
  wd_filenames[i]=gsub(".mat","",c(wd_filenames[i]),fixed = TRUE)
}

# for(file_name in list.files())
# {
#   print(file_name)
# }

#loop through files in wd
for(file_name_i in wd_filenames)
{
  print(file_name_i)
  temp_list = readMat(paste(file_name_i,".mat",sep=""))
  #glimpse(temp_list)
  #print(names(temp_list))
  
  #all timestamp possibilites for boxshort (max calculated /file)
  fp_df = data.frame(
    0:(round(
      max(
        temp_list$Druck.Hubwerk..................................................[,1]
      )*100
      ,digits = 2
    )+1)
  )
  names(fp_df) = "ID_count"
  fp_df = mutate(fp_df, time_id = 0 + ID_count * 0.01)
  
  
  #box short all rows (in descending nrow order)
  for(w_column in names(temp_list))
  {
    #drop not usefull columns
    if(
        w_column == "Crash.Flag....................................................." |
        w_column == "Crash.WD......................................................." | 
        w_column == "Thermo.01.K4..................................................." |
        w_column == "Thermo.01.K3..................................................." |
        w_column == "Thermo.01.K2..................................................." |
        w_column == "Thermo.01.K1..................................................." |
        w_column == "Thermo.01.K8..................................................." |
        w_column == "Thermo.01.K7..................................................." |
        w_column == "Thermo.01.K6..................................................." |
        w_column == "Thermo.01.K5..................................................." 
      )
    {
      print(paste(w_column," is skipped"))
      next()
    }
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
        fp_i = fp_i + 1
      }

      fp_df$temp_col[fp_i] = temp_list[[w_column]][row, 2]
    }
    #rename temp_col to actual colname (df ready for the new mutate)
    names(fp_df) = gsub("temp_col",w_column,names(fp_df))
  }

  #? before boxshort
  #drop meaningless values
  fp_df = select(fp_df,
                 -starts_with("ID_count")
                 )
  #name w_columns, short column names 
  names(fp_df) = c("time_ID_s",
                   "Second_s",
                   "Minute_m",
                   "Hour_h",
                   "Day_d",
                   "Month_mo",
                   "Year_y",
                   "Speed_Steering_wheel_U.min",
                   "Steering_angle_angle",
                   "Speed_pump_motor_U.min",
                   "Torque_pump_motor_Nm",
                   "Crash_Z_0.01g",
                   "Crash_Y_0.01g",
                   "Crash_X_0.01g",
                   "Pressure_Hydraulic_main_mast_bar",
                   "Lever_position_Add2_mV_base_4000mV",
                   "Lever_position_Add1_mV_base_4000mV",
                   "Lever_position_tilting_mV_base_4000mV",
                   "Lever_position_lifting_mV_base_4000mV",
                   "Speed_Drivemotor_2_U.min",
                   "Speed_Drivemotor_1_U.min",
                   "Torque_Drivemotor_2_Nm",
                   "Torque_Drivemotor_1_Nm")

  #filter out fully NA rows () reamainig of the boxshort
  df_fp_tidy = filter(fp_df,
                      !(is.na(Second_s)&
                          is.na(Minute_m)&
                          is.na(Hour_h)&
                          is.na(Day_d)&
                          is.na(Month_mo)&
                          is.na(Year_y)&
                          is.na(Speed_Steering_wheel_U.min)&
                          is.na(Steering_angle_angle)&
                          is.na(Speed_pump_motor_U.min)&
                          is.na(Torque_pump_motor_Nm)&
                          is.na(Crash_Z_0.01g)&
                          is.na(Crash_Y_0.01g)&
                          is.na(Crash_X_0.01g)&
                          is.na(Pressure_Hydraulic_main_mast_bar)&
                          is.na(Lever_position_Add2_mV_base_4000mV)&
                          is.na(Lever_position_Add1_mV_base_4000mV)&
                          is.na(Lever_position_tilting_mV_base_4000mV)&
                          is.na(Lever_position_lifting_mV_base_4000mV)&
                          is.na(Speed_Drivemotor_2_U.min)&
                          is.na(Speed_Drivemotor_1_U.min)&
                          is.na(Torque_Drivemotor_2_Nm)&
                          is.na(Torque_Drivemotor_1_Nm)
                        )
                      )
  #interpolation
  
  #look up first and last value for the interpolation
  for(col in names(df_fp_tidy))
  {
    df_fp_tidy[[col]][1] = df_fp_tidy[[col]][min(which(!is.na(df_fp_tidy[[col]])))]
    df_fp_tidy[[col]][length(df_fp_tidy[[col]])] = df_fp_tidy[[col]][max(which(!is.na(df_fp_tidy[[col]])))]
  }
  
  #switch remaining NA-s to inperpolated values
  df_fp_tidy_no_na = df_fp_tidy %>%
    na.approx() %>%
    as.data.frame() %>%
  #correct time related values (no value after decimal needed)
    mutate(
      Second_s = floor(Second_s),
      Minute_m = floor(Minute_m),
      Hour_h = floor(Hour_h),
      Day_d = floor(Day_d),
      Month_mo = floor(Month_mo),
      Year_y = floor(Year_y)) %>%
  #date time convert with lubridate separeted  (time_ID leave separated, with the lubridate package it can be merged)
    mutate(date = ymd(paste(Year_y,Month_mo,Day_d)),time = hms(paste(Hour_h,Minute_m,Second_s))) %>%
  #mutate fingerprint type
    mutate(fingerprint_type = factor(file_name_i))
  
  #save in export location
  write.csv(df_fp_tidy_no_na,file=paste(export_location,file_name_i,".csv"))
  
}

#a tanszéki PAKS3-mon lefuttatom
#összefűzöm 1 nagy DF-é az összeset
#a datacamp által inspirált elemzési technikákkal nekiállok és hámozok