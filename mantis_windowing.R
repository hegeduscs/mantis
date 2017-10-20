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
# tdf = mutate(tdf,time = hms(time))
# head(tdf$time)
# max(tdf$time)
# min(tdf$time)
# tail(tdf$time)
# names(tdfsum)
# ggplot(tdf1,aes(x = as.numeric(time),y = Pressure_Hydraulic_main_mast_bar)) + geom_point(alpha = 0.8, shape = 21, size = 1.5)

#windowing search

#window width
w_width = 10
if(w_width%%2!=0)
  print("Must be even!")

#is.weight on the truck
tdf_attributes = mutate(
  tdfsum,
  weight_mean = c(rep(0,w_width/2),
                  roll_mean(Pressure_Hydraulic_main_mast_bar,w_width,fill = numeric(0),align = "center"),
                  rep(0,w_width/2-1)
                  ),
  is.weight = weight_mean > 50 #contans from plots
                )
#check direction change
direction_check <- function(value,next_value){
  return(sign(value) != sign(next_value))
}
#changing direction
tdf_attributes = mutate(
  tdf_attributes,
  speed_1_direction_changed = direction_check(Speed_Drivemotor_1_U.min,lag(Speed_Drivemotor_1_U.min,default = 0)),
  speed_2_direction_changed = direction_check(Speed_Drivemotor_2_U.min,lag(Speed_Drivemotor_2_U.min,default = 0)),
  torque_1_direction_changed = direction_check(Torque_Drivemotor_1_Nm,lag(Torque_Drivemotor_1_Nm,default = 0)),
  torque_2_direction_changed = direction_check(Torque_Drivemotor_2_Nm,lag(Torque_Drivemotor_2_Nm,default = 0))
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

tdf_attributes = mutate(
  tdf_attributes, 
  speed_1_modulo_factor = drivemotor_category_modulo_calc(Speed_Drivemotor_1_U.min,speed_max,reso_m), 
  speed_2_modulo_factor = drivemotor_category_modulo_calc(Speed_Drivemotor_2_U.min,speed_max,reso_m),
  torque_1_modulo_factor = drivemotor_category_modulo_calc(Torque_Drivemotor_1_Nm,torque_max,reso_m),
  torque_2_modulo_factor = drivemotor_category_modulo_calc(Torque_Drivemotor_2_Nm,torque_max,reso_m)
)
#factor from previous

#steering angle derivative
#speed and torque change to total range
#left, right 90 degree turn (moving average)
#ramp event (crash Z, torque, speed,)

summary(tdf_attributes)
# length(tdfsum$Pressure_Hydraulic_main_mast_bar)
# length(roll_mean(tdfsum$Pressure_Hydraulic_main_mast_bar,10,fill = numeric(0),align = "center"))
#coerce nulls

