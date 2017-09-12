#boxshort
library(R.matlab)
library(dplyr)
library(plyr)
library(purrr)

filename = "800hTestDrive_fast.mat"

setwd("/home/vasy/RStudioProjects/STILL_CAN_fp_10m_exp/RStudio_wd_Can_fp")

#container make

temp_list = readMat(filename)
#glimpse(temp_list)
print(names(temp_list))

#all timestamp possibilites
fp_df = data.frame(0:1102200)
names(fp_df) = "ID_count"
fp_df = mutate(fp_df, time_id = 0 + ID_count * 0.01)


#box short all rows (in descending nrow order)
fp_i = 1
for(w_column in names(temp_list))
{
  print(w_column) #tested
  fp_i = 1
  #make new row in fp_df
  fp_df = mutate(fp_df, temp_col = as.numeric("NA"))
  
  #boxshort one row (round the time in the temp)
  for(row in 1:length(temp_list[[w_column]][,1]))
  {
    while(abs(fp_df$time_id[fp_i] - round(temp_list[[w_column]][row, 1],digits = 2)) > 0.005)
    {
      fp_i = fp_i + 1
    }

    fp_df$temp_col[fp_i] = temp_list[[w_column]][row, 2] 
  }
  #rename temp_col to actual colname (df ready for the new mutate)
  names(fp_df) = gsub("temp_col",w_column,names(fp_df))
}

#drop meaningless values
fp_df = select(fp_df,
               -Crash_Flag,
               -Crash_WD,
               -starts_with("Thermo_01_K"))

#name w_columns, short column names 
names(fp_df) = c("Second[s]",
                 "Minute[m]",
                 "Hour[h]",
                 "Day[d]",
                 "Month[mo]",
                 "Year[y]",
                 "Speed_Steering_wheel[U/min]",
                 "Steering_angle[angle]",
                 "Speed_pump_motor[U/min]",
                 "Torque_pump_motor[Nm]",
                 "Crash_Z_0.01g",
                 "Crash_Y_0.01g",
                 "Crash_X_0.01g",
                 "Pressure_Hydraulic_main_mast[bar]",
                 "Lever_position_Add2[mV]_mV_base_4000mV",
                 "Lever_position_Add1[mV]_mV_base_4000mV",
                 "Lever_position_tilting[mV]_mV_base_4000mV",
                 "Lever_position_lifting[mV]_mV_base_4000mV",
                 "Speed_Drivemotor_2[U/min]",
                 "Speed_Drivemotor_1[U/min]",
                 "Torque_Drivemotor_2[Nm]",
                 "Torque_Drivemotor_1[Nm]")

#filter out NA rows
df_fp_tidy = filter(fp_df,
                    !(is.na(Second[s])&
                      is.na(Minute[m])&
                      is.na(Hour[h])&
                      is.na(Day[d])&
                      is.na(Month[mo])&
                      is.na(Year[y])&
                      is.na(Speed_Steering_wheel[U/min])&
                      is.na(Steering_angle[angle])&
                      is.na(Speed_pump_motor[U/min])&
                      is.na(Torque_pump_motor[Nm])&
                      is.na(Crash_Z_0.01g)&
                      is.na(Crash_Y_0.01g)&
                      is.na(Crash_X_0.01g)&
                      is.na(Pressure_Hydraulic_main_mast[bar])&
                      is.na(Lever_position_Add2_mV_base_4000mV)&
                      is.na(Lever_position_Add1_mV_base_4000mV)&
                      is.na(Lever_position_tilting_mV_base_4000mV)&
                      is.na(Lever_position_lifting_mV_base_4000mV)&
                      is.na(Speed_Drivemotor_2[U/min])&
                      is.na(Speed_Drivemotor_1[U/min])&
                      is.na(Torque_Drivemotor_2[Nm])&
                      is.na(Torque_Drivemotor_1[Nm]))
                    )




#csv
#write.csv(fp_df,file="first_boxshort.csv")

#name w_columns, short column names 

#set fignerprint class in columns (set date into one)

#interpolate (zip?)

#(set date into one)

#automate one fingerprint reading&tidiying

#automate all fingerprint in one df

#correct classes in all w_columns (merge date and tiem into one)