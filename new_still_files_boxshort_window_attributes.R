#new still files 201710 boxshort, clean, windowing and attributes calc - Vass Bence
library(R.matlab)
library(dplyr)
library(purrr)
library(plyr)
library(lubridate)
library(zoo)
library(readr)
library(ggplot2)
library(stringr)
library(RcppRoll)

#contans
w_width = 10
if(w_width%%2!=0)
  print("Must be even!")
is.weight_limit = 50
big_resonation_limit_plus = 300
big_resonation_limit_minus = 250

#resolution for factor matrix
reso_m = 9 #must be odd!!!
if(reso_m%%2!=1)
  print("Must be odd!")
speed_max = 5000
torque_max = 80

smoothing = 1 # changed for travelled distance calc

#boxshort replace, strech and interpolate in one step
strech_and_interpolate <- function(list_to_short,list_to_match) {
  
  approx_list = approx(list_to_short[,1],
                       list_to_short[,2], 
                       n = trunc(median(diff(list_to_short[,1]))*10^2)*length(list_to_short[,1]))
  
  return(
    c(
      rep(as.numeric("NA"),round(approx_list$x[1],digits = 2)/0.01),
      approx_list$y,
      rep(as.numeric("NA"),length(list_to_match)-length(approx_list$y)-round(approx_list$x[1],digits = 2)/0.01)
    )
  )
}

#where the files to be boxshorted

#PAKS3 (batman)
setwd("/home/vassb/ephemeral-account/")
export_location="/home/vassb/box_window_att_files/"

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
  print(paste("file:",file_name_i))
  temp_list = readMat(paste(file_name_i,".mat",sep=""))
  #glimpse(temp_list)
  #print(names(temp_list))
  
  #all timestamp possibilites for boxshort (max calculated /file)
  fp_df = data.frame(
    0:(
      round(
        max(
          temp_list$A5.Sekunde.....................................................[,1]
        )*100
        ,digits = 2
      )
      +1000)
  )
  names(fp_df) = "ID_count"
  fp_df = mutate(fp_df, time_id = 0 + ID_count * 0.01)
  
  
  #box short all rows (in descending nrow order)
  ##################################################################################################################################################################################################################
  #boxshort and cleaning
  ##################################################################################################################################################################################################################
  
  for(w_column in names(temp_list))
  {
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
    
    fp_df = mutate(fp_df,  temp_col = strech_and_interpolate(temp_list[[w_column]],time_id)) 
    names(fp_df)[names(fp_df) == "temp_col"] <- w_column
  }
  warnings()
  
  #cleaning solution
  fp_df = fp_df %>% 
    #drop meaningless values  
    select(-starts_with("ID_count")) %>%
    #rearrenge columns to properly rename them  
    select(
      time_id,
      A5.Sekunde.....................................................,
      A4.Minute......................................................,
      A3.Stunde......................................................,
      A2.Tag.........................................................,
      A1.Monat.......................................................,
      A0.Jahr........................................................,
      SR.DAC.3.Drehzahl.Lenkrad......................................,
      SR.DAC.2.Lenkwinkel............................................,
      SR.DAC.1.Drehzahl.PM...........................................,
      SR.DAC.0.Drehmoment.PM.........................................,
      UE.DAC.6.Auslenkung.Z.prop.....................................,
      UE.DAC.5.Auslenkung.Y.prop.....................................,
      UE.DAC.4.Auslenkung.X.prop.....................................,
      UE.DAC.7.Auslenkung.W.prop.....................................,
      SR.DAC.7.Auslenkung.Zusatz.2...................................,
      SR.DAC.6.Auslenkung.Zusatz.1...................................,
      SR.DAC.5.Auslenkung.Neigen.....................................,
      SR.DAC.4.Auslenkung.Heben......................................,
      UE.DAC.3.Drehzahl.FM.2.........................................,
      UE.DAC.2.Drehzahl.FM.1.........................................,
      UE.DAC.1.Drehmoment.FM.2.......................................,
      UE.DAC.0.Drehmoment.FM.1.......................................
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
                   "Crash_W_0.01g",
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
                          is.na(Crash_W_0.01g)&
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
    #when the is to much NA value (time related columns) last observation carried forward  
    colwise(na.locf)() %>%
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
    #drop redundant values
    select(
      -Second_s,
      -Minute_m,
      -Hour_h,
      -Day_d,
      -Month_mo,
      -Year_y
    ) %>%
    #mutate fingerprint type
    mutate(date_time = as.POSIXct(ymd_hms(paste(date,hms(time),sep = ",") ))) %>%
    group_by(date_time) %>%
    summarise_all(mean,na.rm = TRUE) %>%
    mutate(fingerprint_type = factor(file_name_i))
 
  
  #save in export location
  
  #csv 
  # write.csv(df_fp_tidy_no_na,file=paste(export_location,file_name_i,".csv",sep=""))
  # print(paste(file_name_i,".csv is saved to: ",export_location,sep = ""))
  
  #RDS
  saveRDS(df_fp_tidy_no_na,file=paste(export_location,file_name_i,".rds",sep=""))
  print(paste(file_name_i,".rds is saved to: ",export_location,sep = ""))
  
  warnings()
  ##################################################################################################################################################################################################################
  #windowing and attributes
  ##################################################################################################################################################################################################################
  
  #is.weight on the truck
  tdf_attributes = mutate(
    df_fp_tidy_no_na,
    weight_mean = c(rep(0,w_width/2),
                    roll_mean(Pressure_Hydraulic_main_mast_bar,w_width,fill = numeric(0),align = "center"),
                    rep(0,w_width/2 - 1)
    ),
    is.weight = weight_mean > is.weight_limit, #contans from plots
    
    resonation_mean = c(rep(0,w_width/2),
                        roll_mean(Crash_Z_0.01g,w_width,fill = numeric(0),align = "center"),
                        rep(0,w_width/2 - 1)
    ),
    big_resonation_event = resonation_mean > big_resonation_limit_plus | resonation_mean < big_resonation_limit_minus
    
  )
  #check direction change
  direction_check <- function(value,next_value){
    return(sign(value) != sign(next_value))
  }
  #smoohting used in direction and derivatives
 
  #changing x and y direction
  tdf_attributes = mutate(
    tdf_attributes,
    speed_1_direction_changed = direction_check(Speed_Drivemotor_1_U.min,lag(Speed_Drivemotor_1_U.min,n=smoothing,default = 0)),
    speed_2_direction_changed = direction_check(Speed_Drivemotor_2_U.min,lag(Speed_Drivemotor_2_U.min,n=smoothing,default = 0)),
    torque_1_direction_changed = direction_check(Torque_Drivemotor_1_Nm,lag(Torque_Drivemotor_1_Nm,n=smoothing,default = 0)),
    torque_2_direction_changed = direction_check(Torque_Drivemotor_2_Nm,lag(Torque_Drivemotor_2_Nm,n=smoothing,default = 0)),
    is.changed_y_direction = direction_check(Steering_angle_angle,lag(Steering_angle_angle,n=smoothing,default = 0)),
    is.y_direction_0 = Steering_angle_angle == 0
  )
  
  #speed torque matrix

  #categorise speed and drivemotor profiles, to future comparison using not linear intervall search not binary search but modulo calculation
  drivemotor_category_modulo_calc <- function(value_to_cat,real_scale_max,resolution_m){
    return(
      #cut down decimals, for more resolution, increase reso_m
      floor(
        (
          #(rescale to positive region)  #calc binning
          (value_to_cat+real_scale_max)/(2*real_scale_max/resolution_m)
          #calc the correct binning
        )%%resolution_m
      )
    )
  }
  
  #make all factor variations for comparsion
  factor_variations <- function(resolution_m){
    
    temp_m = expand.grid(0:resolution_m,0:resolution_m)
    
    for(i in 1:(resolution_m+1)**2){
      if(i == 1)
        factor_variations_string = paste(temp_m[i,1],temp_m[i,2],sep = ",")
      else
        factor_variations_string = c(factor_variations_string,paste(temp_m[i,1],temp_m[i,2],sep = ","))
    }
    return(temp_string)
  }
  
  tdf_attributes = mutate(
    tdf_attributes, 
    speed_1_modulo_factor = drivemotor_category_modulo_calc(Speed_Drivemotor_1_U.min,speed_max,reso_m), 
    speed_2_modulo_factor = drivemotor_category_modulo_calc(Speed_Drivemotor_2_U.min,speed_max,reso_m),
    torque_1_modulo_factor = drivemotor_category_modulo_calc(Torque_Drivemotor_1_Nm,torque_max,reso_m),
    torque_2_modulo_factor = drivemotor_category_modulo_calc(Torque_Drivemotor_2_Nm,torque_max,reso_m),
    
    speed_torque_1_factor = paste(speed_1_modulo_factor,torque_1_modulo_factor,sep=","),
    speed_torque_2_factor = paste(speed_2_modulo_factor,torque_2_modulo_factor,sep=","),
    
    speed_torque_1_factor = as.factor(speed_torque_1_factor,levels = factor_variations(reso_m)),
    speed_torque_2_factor = as.factor(speed_torque_2_factor,levels = factor_variations(reso_m)),
    
    is.speed_torque_factor_equal = speed_torque_1_factor == speed_torque_2_factor
  )
  
  #derivatives speed, torque, steering angle and steering speed + resonation calculated from Crash_Z
  
  tdf_attributes = mutate(
    tdf_attributes,
    
    s_1_t_deriv = abs((lag(Speed_Drivemotor_1_U.min,n=smoothing,default = 0) - Speed_Drivemotor_1_U.min))/(lag(time_ID_s,n=smoothing,default = 0)-time_ID_s), 
    s_2_t_deriv = abs((lag(Speed_Drivemotor_2_U.min,n=smoothing,default = 0) - Speed_Drivemotor_2_U.min))/(lag(time_ID_s,n=smoothing,default = 0)-time_ID_s), 
    
    t_1_t_deriv = abs((lag(Torque_Drivemotor_1_Nm,n=smoothing,default = 0) - Torque_Drivemotor_1_Nm))/(lag(time_ID_s,n=smoothing,default = 0)-time_ID_s), 
    t_2_t_deriv = abs((lag(Torque_Drivemotor_2_Nm,n=smoothing,default = 0) - Torque_Drivemotor_2_Nm))/(lag(time_ID_s,n=smoothing,default = 0)-time_ID_s), 
    
    speed_steering_deriv = abs((lag(Speed_Steering_wheel_U.min,n=smoothing,default = 0) - Speed_Steering_wheel_U.min))/(lag(time_ID_s,n=smoothing,default = 0)-time_ID_s),
    steer_wheel_deg_t_deriv = abs((lag(Steering_angle_angle,n=smoothing,default = 0) - Steering_angle_angle))/(lag(time_ID_s,n=smoothing,default = 0)-time_ID_s),
    resonation_t_deriv = abs((lag(Crash_Z_0.01g,n=smoothing,default = 0) - Crash_Z_0.01g))/(lag(time_ID_s,n=smoothing,default = 0)-time_ID_s)
    
  )
  #+ travelled dsitance smooting correction
  #speed convert from U/min to m/s still max speed is 20km/h so 3.6km/h / 1m/s 5.55 m/s, the max U is 3453 so speed_m/s = speedU*5.555/3453 and 
  smoothing = 1
  tdf_attributes = mutate(
    tdf_attributes,
    speed_d1 = (Speed_Drivemotor_1_U.min * 5.555)/4000,
    speed_d2 = (Speed_Drivemotor_2_U.min * 5.555)/4000,
    #delta distance
    abs_trav_distance_dt = abs(
      #delta velocity
      mean(c(lag(speed_d1,n=smoothing,default = 0),lag(speed_d2,n=smoothing,default = 0)))
      -
        mean(c(speed_d1,speed_d2))
    )
    *
      #delta time
      (lag(time_ID_s,n=smoothing,default = 0)-time_ID_s)
    +
      #delta acceleration
      abs(lag(Crash_X_0.01g,n=smoothing,default = 0) - Crash_X_0.01g)
    *
      (lag(time_ID_s,n=smoothing,default = 0)-time_ID_s)^2/2
    
  )

  sum(tdf_attributes$abs_trav_distance_dt)
  
  #savaRDS to attributes
  saveRDS(tdf_attributes,file=paste(export_location,file_name_i,"_att.rds",sep=""))
  print(paste(file_name_i,"_att.rds is saved to: ",export_location,sep = ""))
}











