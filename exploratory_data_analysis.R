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

# na.locf tested
# summary(df_container)
# df_container2 = na.locf(df_container,fromLast = TRUE)
# summary(df_container2)

df_container = df_container %>%
  mutate(fast.slow = factor(str_detect(fingerprint_type,"fast"))) %>%
  mutate(wl.wol = factor(str_detect(fingerprint_type,"_wl_"))) %>%
  mutate(ramp = factor(str_detect(fingerprint_type,"Ramp"))) %>%
  mutate(time = hms(time)) %>%
  mutate(fingerprint_type = factor(fingerprint_type))
glimpse(df_container)

# hist(df_container$Speed_Steering_wheel_U.min)
# #Steering_angle_angle
# hist(df_container$Steering_angle_angle)

df_con_pairs = df_container %>%
  mutate(time = as.numeric(time)) %>%
  #delete when running on batman
  filter(X1%%1000 == 0) %>%  
  
  select(-X1,-date) %>%
  select(Torque_Drivemotor_1_Nm,Torque_Drivemotor_2_Nm,Speed_Drivemotor_1_U.min,Speed_Drivemotor_2_U.min,fast.slow,wl.wol,time)
  #select(Steering_angle_angle,Crash_Y_0.01g,fast.slow,wl.wol,time)

ggpairs(df_con_pairs,aes(alpha = 0.1)
        #,aes(alpha = 0.1, size = 1.5)
        ,cardinality_threshold = 22)

ggsave("torque_speed_category", plot = last_plot(), device = "png", path = export_location)


#GGSAVE ?
# ggplot(df_container,aes(x = Speed_Steering_wheel_U.min))+geom_density() + facet_wrap(~fingerprint_type, scales = 'free_x')
# ggplot(df_container,aes(x = Speed_Steering_wheel_U.min))+geom_density() + facet_wrap(~fingerprint_type, scales = 'free_x')
# ggplot(df_container,aes(Speed_Drivemotor_2_U.min,Torque_Drivemotor_2_Nm))+geom_point(alpha = 0.1, shape = 21, size = 1.5) + facet_wrap(~fingerprint_type, scales = 'free_x')
# ggplot(df_container,aes(as.numeric(time),Steering_angle_angle))+geom_point(alpha = 0.4, shape = 21, size = 1.5) + facet_wrap(~fingerprint_type, scales = 'free_x')
# ggplot(df_container,aes(Speed_Drivemotor_2_U.min,Torque_Drivemotor_2_Nm,color = fast.slow,fill = wl.wol))+geom_point(alpha = 0.1, shape = 21, size = 1.5) + facet_wrap(~fingerprint_type, scales = 'free_x')
# ggplot(df_container,aes(x = Speed_Steering_wheel_U.min,color = fast.slow,fill = wl.wol))+geom_density() + facet_wrap(~fingerprint_type, scales = 'free_x')
# ggplot(df_con_pairs,aes(x=Crash_Y_0.01g,y=Steering_angle_angle)) + geom_point() + facet_wrap(~fingerprint_type, scales = 'free_x')
# ggplot(df_con_pairs,aes(x = Crash_Z_0.01g)) + geom_density() + facet_wrap(~fingerprint_type, scales = 'free_x')
# ggplot(df_con_pairs,aes(x=Crash_Y_0.01g,y=Steering_angle_angle,color = ramp)) + geom_point() + facet_wrap(~fingerprint_type, scales = 'free_x')
# ggplot(df_con_pairs,aes(as.numeric(time),Lever_position_lifting_mV_base_4000mV,color = wl.wol))+geom_point(alpha = 0.4, shape = 21, size = 1.5) + facet_wrap(~fingerprint_type, scales = 'free_x')
# ggplot(df_con_pairs,aes(as.numeric(time),Pressure_Hydraulic_main_mast_bar,color = wl.wol))+geom_point(alpha = 0.8, shape = 21, size = 1.5) + facet_wrap(~fingerprint_type, scales = 'free_x')

df_con = df_con_pairs[complete.cases(df_con_pairs),]
df_data = as.matrix(df_con[,3:18])
row.names(df_data) = df_con$X1
df.pr = prcomp(df_data,scale = TRUE)

df.dist.scaled = dist(scale(df_data))
df.hclust = hclust(df.dist.scaled,method = "complete")
df.hclust_4 = cutree(df.hclust,k=4)

# 1) from your hclust object, create a new object with just the ordered column
# 
# hh1 = hclust(dist(dataMatrix))
# DataMatrixOrdered= data.frame(hh1$order)
# 2) Combine Ordered data frame and original data
# 
# DataMatrixOrderedCbind = cbind(dataMatrix, DataMatrixOrdered[,1])
