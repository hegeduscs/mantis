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

tdf1 = read_csv("FastTrackEight_wl_fast.csv")
tdf2 = read_csv("FastTrackEight_wol_slow.csv")

tdfsum = bind_rows(tdf1,tdf2)

tdfsum = tdfsum %>%
  colwise(na.locf)() 

#summary(colwise(na.locf)(tdfsum))

summary(tdfsum)
# tdf = mutate(tdf,time = hms(time))
# head(tdf$time)
# max(tdf$time)
# min(tdf$time)
# tail(tdf$time)
# names(tdfsum)
# ggplot(tdf1,aes(x = as.numeric(time),y = Pressure_Hydraulic_main_mast_bar)) + geom_point(alpha = 0.8, shape = 21, size = 1.5)

#windowing search

#window width
w_width = 11
if(w_width%%2!=0)
  print("Must be even!")
is.weight_limit = 50
big_resonation_limit_plus = 300
big_resonation_limit_minus = 250

#is.weight on the truck
tdf_attributes = mutate(
  tdfsum,
  weight_mean = c(rep(0,w_width/2),
                  roll_mean(Pressure_Hydraulic_main_mast_bar,w_width,fill = numeric(0),align = "center"),
                  rep(0,w_width/2)
                  ),
   is.weight = weight_mean > is.weight_limit, #contans from plots

  resonation_mean = c(rep(0,w_width/2),
                       roll_mean(Crash_Z_0.01g,w_width,fill = numeric(0),align = "center"),
                    rep(0,w_width/2)
                    ),
  big_resonation_event = resonation_mean > big_resonation_limit_plus | resonation_mean < big_resonation_limit_minus
  
)
#check direction change
direction_check <- function(value,next_value){
  return(sign(value) != sign(next_value))
}
#smoohting used in direction and derivatives
smoothing = 1
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
#resolution for factor matrix
reso_m = 9 #must be odd!!!
if(reso_m%%2!=1)
  print("Must be odd!")
speed_max = 5000
torque_max = 80

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
smoothing = 5
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
summary(tdf_attributes)
sum(tdf_attributes$abs_trav_distance_dt)
                                      

#events:


#ramp event (crash Z, torque, speed,)
#ggplot(tdf_attributes,aes(time_ID_s,resonation_mean)) + geom_point() + facet_wrap(~factor(fingerprint_type))

summary(tdf_attributes)
# length(tdfsum$Pressure_Hydraulic_main_mast_bar)
# length(roll_mean(tdfsum$Pressure_Hydraulic_main_mast_bar,10,fill = numeric(0),align = "center"))
#coerce nulls

sum(tdf_attributes$abs_trav_distance_dt)
ggplot(tdf_attributes,aes(time_ID_s,abs_trav_distance_dt)) + geom_point() + facet_wrap(~factor(fingerprint_type))
