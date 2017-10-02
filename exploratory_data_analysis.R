library(readr)
library(R.matlab)
library(dplyr)
library(purrr)
library(plyr)
library(lubridate)
library(zoo)
library(ggplot2)
library(stringr)

#PC
setwd("/home/vasy/RStudioProjects/still_github/cleaned_files/cleaned_files/")
export_location="/home/vasy/RStudioProjects/still_github/exploratory_files/"

df_container = data_frame()
first = 1

for(file_name_i in list.files())
{
  if(first)
  {
    df_container = read_csv(file_name_i)
    first = 0 
  } 
  else 
  {
    df_container = bind_rows(df_container,read_csv(file_name_i))
  }
}

df_container = df_container %>%
  mutate(fast.slow = str_detect(fingerprint_type,"fast")) %>%
  mutate(wl.wol = str_detect(fingerprint_type,"_wl_")) %>%
  mutate(time = hms(time)) %>%
  mutate(fingerprint_type = factor(fingerprint_type))
glimpse(df_container)

# hist(df_container$Speed_Steering_wheel_U.min)
# #Steering_angle_angle
# hist(df_container$Steering_angle_angle)


#GGSAVE ?
# ggplot(df_container,aes(x = Speed_Steering_wheel_U.min))+geom_density() + facet_wrap(~fingerprint_type, scales = 'free_x')
# ggplot(df_container,aes(x = Speed_Steering_wheel_U.min))+geom_density() + facet_wrap(~fingerprint_type, scales = 'free_x')
# ggplot(df_container,aes(Speed_Drivemotor_2_U.min,Torque_Drivemotor_2_Nm))+geom_point(alpha = 0.1, shape = 21, size = 1.5) + facet_wrap(~fingerprint_type, scales = 'free_x')
# ggplot(df_container,aes(as.numeric(time),Steering_angle_angle))+geom_point(alpha = 0.4, shape = 21, size = 1.5) + facet_wrap(~fingerprint_type, scales = 'free_x')
# ggplot(df_container,aes(Speed_Drivemotor_2_U.min,Torque_Drivemotor_2_Nm,color = fast.slow,fill = wl.wol))+geom_point(alpha = 0.1, shape = 21, size = 1.5) + facet_wrap(~fingerprint_type, scales = 'free_x')
# ggplot(df_container,aes(x = Speed_Steering_wheel_U.min,color = fast.slow,fill = wl.wol))+geom_density() + facet_wrap(~fingerprint_type, scales = 'free_x')