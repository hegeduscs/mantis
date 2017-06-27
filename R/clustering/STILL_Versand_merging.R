#setting workspace directory (modify it accordingly)
setwd("C:/Users/Public/R/still")

#loading in the dplyr package
#install.packages("dplyr")
library(dplyr)
#install.packages("R.matlab")
library(R.matlab)
library(ggplot2)

crash_wd.list <- readMat("still_mat_borzadaly/crash_wd.mat")
crash_wd <- data.frame(crash_wd.list)
names(crash_wd)[1] <- 'timeId'
names(crash_wd)[2] <- 'crash_wd'

crash_x.list <- readMat("still_mat_borzadaly/crash_x.mat")
crash_x <- data.frame(crash_x.list)
names(crash_x)[1] <- 'timeId'
names(crash_x)[2] <- 'crash_x'

crash_y.list <- readMat("still_mat_borzadaly/crash_y.mat")
crash_y <- data.frame(crash_y.list)
names(crash_y)[1] <- 'timeId'
names(crash_y)[2] <- 'crash_y'

crash_z.list <- readMat("still_mat_borzadaly/crash_z.mat")
crash_z <- data.frame(crash_z.list)
names(crash_z)[1] <- 'timeId'
names(crash_z)[2] <- 'crash_z'

DAC_6_Begrenzung_V_Motor_Moment.list <- readMat("still_mat_borzadaly/DAC_6_Begrenzung_V_Motor_Moment.mat")
DAC_6_Begrenzung_V_Motor_Moment <- data.frame(DAC_6_Begrenzung_V_Motor_Moment.list)
names(DAC_6_Begrenzung_V_Motor_Moment)[1] <- 'timeId'
names(DAC_6_Begrenzung_V_Motor_Moment)[2] <- 'DAC_6_Begrenzung_V_Motor_Moment'

DAC_7_Begrenzung_F_Motor_Moment.list <- readMat("still_mat_borzadaly/DAC_7_Begrenzung_F_Motor_Moment.mat")
DAC_7_Begrenzung_F_Motor_Moment <- data.frame(DAC_7_Begrenzung_F_Motor_Moment.list)
names(DAC_7_Begrenzung_F_Motor_Moment)[1] <- 'timeId'
names(DAC_7_Begrenzung_F_Motor_Moment)[2] <- 'DAC_7_Begrenzung_F_Motor_Moment'

day.list <- readMat("still_mat_borzadaly/day.mat")
day <- data.frame(day.list)
names(day)[1] <- 'timeId'
names(day)[2] <- 'day'

engine_rpm.list <- readMat("still_mat_borzadaly/engine_rpm.mat")
engine_rpm <- data.frame(engine_rpm.list)
names(engine_rpm)[1] <- 'timeId'
names(engine_rpm)[2] <- 'engine_rpm'

engine_rpm_2.list <- readMat("still_mat_borzadaly/engine_rpm_2.mat")
engine_rpm_2 <- data.frame(engine_rpm_2.list)
names(engine_rpm_2)[1] <- 'timeId'
names(engine_rpm_2)[2] <- 'engine_rpm_2'

engine_torque.list <- readMat("still_mat_borzadaly/engine_torque.mat")
engine_torque <- data.frame(engine_torque.list)
names(engine_torque)[1] <- 'timeId'
names(engine_torque)[2] <- 'engine_torque'

engine_torque_2.list <- readMat("still_mat_borzadaly/engine_torque_2.mat")
engine_torque_2 <- data.frame(engine_torque_2.list)
names(engine_torque_2)[1] <- 'timeId'
names(engine_torque_2)[2] <- 'engine_torque_2'

fork_hydraulic_pressure.list <- readMat("still_mat_borzadaly/fork_hydraulic_pressure.mat")
fork_hydraulic_pressure <- data.frame(fork_hydraulic_pressure.list)
names(fork_hydraulic_pressure)[1] <- 'timeId'
names(fork_hydraulic_pressure)[2] <- 'fork_hydraulic_pressure'

hour.list <- readMat("still_mat_borzadaly/hour.mat")
hour <- data.frame(hour.list)
names(hour)[1] <- 'timeId'
names(hour)[2] <- 'hour'

injected_fuel_amount.list <- readMat("still_mat_borzadaly/injected_fuel_amount.mat")
injected_fuel_amount <- data.frame(injected_fuel_amount.list)
names(injected_fuel_amount)[1] <- 'timeId'
names(injected_fuel_amount)[2] <- 'injected_fuel_amount'

minute.list <- readMat("still_mat_borzadaly/minute.mat")
minute <- data.frame(minute.list)
names(minute)[1] <- 'timeId'
names(minute)[2] <- 'minute'

second.list <- readMat("still_mat_borzadaly/second.mat")
second <- data.frame(second.list)
names(second)[1] <- 'timeId'
names(second)[2] <- 'second'

sitzkontakt.list <- readMat("still_mat_borzadaly/sitzkontakt.mat")
sitzkontakt <- data.frame(sitzkontakt.list)
names(sitzkontakt)[1] <- 'timeId'
names(sitzkontakt)[2] <- 'sitzkontakt'

still.3day.df <- full_join(crash_wd, crash_x, by = "timeId")
still.3day.df <- full_join(still.3day.df, crash_y, by = "timeId")
still.3day.df <- full_join(still.3day.df, crash_z, by = "timeId")
still.3day.df <- full_join(still.3day.df, DAC_6_Begrenzung_V_Motor_Moment, by = "timeId")
still.3day.df <- full_join(still.3day.df, DAC_7_Begrenzung_F_Motor_Moment, by = "timeId")
still.3day.df <- full_join(still.3day.df, day, by = "timeId")
still.3day.df <- full_join(still.3day.df, engine_rpm, by = "timeId")
still.3day.df <- full_join(still.3day.df, engine_rpm_2, by = "timeId")
still.3day.df <- full_join(still.3day.df, engine_torque, by = "timeId")
still.3day.df <- full_join(still.3day.df, engine_torque_2, by = "timeId")
still.3day.df <- full_join(still.3day.df, fork_hydraulic_pressure, by = "timeId")
still.3day.df <- full_join(still.3day.df, hour, by = "timeId")
still.3day.df <- full_join(still.3day.df, injected_fuel_amount, by = "timeId")
still.3day.df <- full_join(still.3day.df, minute, by = "timeId")
still.3day.df <- full_join(still.3day.df, second, by = "timeId")
still.3day.df <- full_join(still.3day.df, sitzkontakt, by = "timeId")

write.csv(still.3day.df, file = "still_3day_merged.csv", row.names = FALSE)

#big gap around 31900-63100 abd 116900-150000
quantile(crash_wd$timeId, probs = seq(0, 1, 0.01))

ggplot(crash_wd, aes(timeId, crash_wd)) + geom_point() + xlab("timeID [s]") + ylab("crash_wd")
ggplot(crash_wd, aes(crash_wd)) + geom_density()
crash_wd_sampled <- sample_frac(crash_wd, 0.05)
ggplot(crash_wd_sampled, aes(timeId, crash_wd)) + geom_point() + xlab("timeID [s]") + ylab("crash_wd") + ggtitle("sample 5% of the data")
ggplot(crash_wd_sampled, aes(timeId, crash_wd)) + geom_jitter() + xlab("timeID [s]") + ylab("crash_wd")
ggplot(crash_wd_sampled, aes(crash_wd)) + geom_density()

crash_wd_sampled_filtered <- filter(crash_wd_sampled, timeId > 10000 & timeId < 13600)
ggplot(crash_wd_sampled_filtered, aes(timeId, crash_wd)) + geom_point() + xlab("timeID [s]") + ylab("crash_wd") + ggtitle("sample 5% of the data")
ggplot(crash_wd_sampled_filtered, aes(timeId, crash_wd)) + geom_jitter() + xlab("timeID [s]") + ylab("crash_wd")
ggplot(crash_wd_sampled_filtered, aes(crash_wd)) + geom_density()

crash_wd_filtered <- filter(crash_wd, timeId > 10000 & timeId < 13600)
ggplot(crash_wd_filtered, aes(crash_wd)) + geom_density()
ggplot(crash_wd_filtered, aes(timeId, crash_wd)) + geom_point() + xlab("timeID [s]") + ylab("crash_wd")

crash_x_sampled <- sample_frac(crash_x, 0.05)
ggplot(crash_x_sampled, aes(timeId, crash_x)) + geom_point() + xlab("timeID [s]") + ylab("crash_x") + ggtitle("sample 5% of the data")
ggplot(crash_x, aes(crash_x)) + geom_density()
crash_x_filtered <- filter(crash_x, timeId > 10000 & timeId < 13600)
ggplot(crash_x_filtered, aes(crash_x)) + geom_density() + ggtitle("filtered data, timeId between 10k and 13.6k")
ggplot(crash_x_filtered, aes(timeId, crash_x)) + geom_point() + xlab("timeID [s]") + ylab("crash_x")

crash_y_sampled <- sample_frac(crash_y, 0.05)
ggplot(crash_y_sampled, aes(timeId, crash_y)) + geom_point() + xlab("timeID [s]") + ylab("crash_y") + ggtitle("sample 5% of the data")
ggplot(crash_y, aes(crash_y)) + geom_density()
crash_y_filtered <- filter(crash_y, timeId > 10000 & timeId < 13600)
ggplot(crash_y_filtered, aes(crash_y)) + geom_density() + ggtitle("filtered data, timeId between 10k and 13.6k")
ggplot(crash_y_filtered, aes(timeId, crash_y)) + geom_point() + xlab("timeID [s]") + ylab("crash_y")

crash_z_sampled <- sample_frac(crash_z, 0.05)
ggplot(crash_z_sampled, aes(timeId, crash_z)) + geom_point() + xlab("timeID [s]") + ylab("crash_z") + ggtitle("sample 5% of the data")
ggplot(crash_z, aes(crash_z)) + geom_density()
crash_z_filtered <- filter(crash_z, timeId > 10000 & timeId < 13600)
ggplot(crash_z_filtered, aes(crash_z)) + geom_density() + ggtitle("filtered data, timeId between 10k and 13.6k")
ggplot(crash_z_filtered, aes(timeId, crash_z)) + geom_point() + xlab("timeID [s]") + ylab("crash_z")

v_motor_moment_sampled <- sample_frac(DAC_6_Begrenzung_V_Motor_Moment, 0.05)
ggplot(v_motor_moment_sampled, aes(timeId, DAC_6_Begrenzung_V_Motor_Moment)) + geom_point() + xlab("timeID [s]") + ylab("DAC_6_Begrenzung_V_Motor_Moment") + ggtitle("sample 5% of the data")
ggplot(DAC_6_Begrenzung_V_Motor_Moment, aes(DAC_6_Begrenzung_V_Motor_Moment)) + geom_density()
v_motor_moment_filtered <- filter(DAC_6_Begrenzung_V_Motor_Moment, timeId > 10000 & timeId < 13600)
ggplot(v_motor_moment_filtered, aes(DAC_6_Begrenzung_V_Motor_Moment)) + geom_density() + ggtitle("filtered data, timeId between 10k and 13.6k")
ggplot(v_motor_moment_filtered, aes(timeId, DAC_6_Begrenzung_V_Motor_Moment)) + geom_point() + xlab("timeID [s]") + ylab("DAC_6_Begrenzung_V_Motor_Moment")

f_motor_moment_sampled <- sample_frac(DAC_7_Begrenzung_F_Motor_Moment, 0.05)
ggplot(f_motor_moment_sampled, aes(timeId, DAC_7_Begrenzung_F_Motor_Moment)) + geom_point() + xlab("timeID [s]") + ylab("DAC_7_Begrenzung_F_Motor_Moment") + ggtitle("sample 5% of the data")
ggplot(DAC_7_Begrenzung_F_Motor_Moment, aes(DAC_7_Begrenzung_F_Motor_Moment)) + geom_density()
f_motor_moment_filtered <- filter(DAC_7_Begrenzung_F_Motor_Moment, timeId > 10000 & timeId < 13600)
ggplot(f_motor_moment_filtered, aes(DAC_7_Begrenzung_F_Motor_Moment)) + geom_density() + ggtitle("filtered data, timeId between 10k and 13.6k")
ggplot(f_motor_moment_filtered, aes(timeId, DAC_7_Begrenzung_F_Motor_Moment)) + geom_point() + xlab("timeID [s]") + ylab("DAC_7_Begrenzung_F_Motor_Moment")

fork_hydraulic_pressure_sampled <- sample_frac(fork_hydraulic_pressure, 0.05)
ggplot(fork_hydraulic_pressure_sampled, aes(timeId, fork_hydraulic_pressure)) + geom_point() + xlab("timeID [s]") + ylab("fork_hydraulic_pressure") + ggtitle("sample 5% of the data")
ggplot(fork_hydraulic_pressure, aes(fork_hydraulic_pressure)) + geom_density()
fork_hydraulic_pressure_filtered <- filter(fork_hydraulic_pressure, timeId > 10000 & timeId < 13600)
ggplot(fork_hydraulic_pressure_filtered, aes(fork_hydraulic_pressure)) + geom_density() + ggtitle("filtered data, timeId between 10k and 13.6k")
ggplot(fork_hydraulic_pressure_filtered, aes(timeId, fork_hydraulic_pressure)) + geom_point() + xlab("timeID [s]") + ylab("fork_hydraulic_pressure")

engine_rpm_sampled <- sample_frac(engine_rpm, 0.05)
ggplot(engine_rpm_sampled, aes(timeId, engine_rpm)) + geom_point() + xlab("timeID [s]") + ylab("engine_rpm") + ggtitle("sample 5% of the data")
ggplot(engine_rpm, aes(engine_rpm)) + geom_density()
engine_rpm_filtered <- filter(engine_rpm, timeId > 10000 & timeId < 13600)
ggplot(engine_rpm_filtered, aes(engine_rpm)) + geom_density() + ggtitle("filtered data, timeId between 10k and 13.6k")
ggplot(engine_rpm_filtered, aes(timeId, engine_rpm)) + geom_point() + xlab("timeID [s]") + ylab("engine_rpm")

engine_rpm_2_sampled <- sample_frac(engine_rpm_2, 0.05)
ggplot(engine_rpm_2_sampled, aes(timeId, engine_rpm_2)) + geom_point() + xlab("timeID [s]") + ylab("engine_rpm_2") + ggtitle("sample 5% of the data")
ggplot(engine_rpm_2, aes(engine_rpm_2)) + geom_density()
engine_rpm_2_filtered <- filter(engine_rpm_2, timeId > 10000 & timeId < 13600)
ggplot(engine_rpm_2_filtered, aes(engine_rpm_2)) + geom_density() + ggtitle("filtered data, timeId between 10k and 13.6k")
ggplot(engine_rpm_2_filtered, aes(timeId, engine_rpm_2)) + geom_point() + xlab("timeID [s]") + ylab("engine_rpm_2")

engine_torque_sampled <- sample_frac(engine_torque, 0.05)
ggplot(engine_torque_sampled, aes(timeId, engine_torque)) + geom_point() + xlab("timeID [s]") + ylab("engine_torque") + ggtitle("sample 5% of the data")
ggplot(engine_torque, aes(engine_torque)) + geom_density()
engine_torque_filtered <- filter(engine_torque, timeId > 10000 & timeId < 13600)
ggplot(engine_torque_filtered, aes(engine_torque)) + geom_density() + ggtitle("filtered data, timeId between 10k and 13.6k")
ggplot(engine_torque_filtered, aes(timeId, engine_torque)) + geom_point() + xlab("timeID [s]") + ylab("engine_torque")

engine_torque_2_sampled <- sample_frac(engine_torque_2, 0.05)
ggplot(engine_torque_2_sampled, aes(timeId, engine_torque_2)) + geom_point() + xlab("timeID [s]") + ylab("engine_torque_2") + ggtitle("sample 5% of the data")
ggplot(engine_torque_2, aes(engine_torque_2)) + geom_density()
engine_torque_2_filtered <- filter(engine_torque_2, timeId > 10000 & timeId < 13600)
ggplot(engine_torque_2_filtered, aes(engine_torque_2)) + geom_density() + ggtitle("filtered data, timeId between 10k and 13.6k")
ggplot(engine_torque_2_filtered, aes(timeId, engine_torque_2)) + geom_point() + xlab("timeID [s]") + ylab("engine_torque_2")

injected_fuel_amount_sampled <- sample_frac(injected_fuel_amount, 0.05)
ggplot(injected_fuel_amount_sampled, aes(timeId, injected_fuel_amount)) + geom_point() + xlab("timeID [s]") + ylab("injected_fuel_amount") + ggtitle("sample 5% of the data")
ggplot(injected_fuel_amount, aes(injected_fuel_amount)) + geom_density()
injected_fuel_amount_filtered <- filter(injected_fuel_amount, timeId > 10000 & timeId < 13600)
ggplot(injected_fuel_amount_filtered, aes(injected_fuel_amount)) + geom_density() + ggtitle("filtered data, timeId between 10k and 13.6k")
ggplot(injected_fuel_amount_filtered, aes(timeId, injected_fuel_amount)) + geom_point() + xlab("timeID [s]") + ylab("injected_fuel_amount")

sitzkontakt_sampled <- sample_frac(sitzkontakt, 0.05)
ggplot(sitzkontakt_sampled, aes(timeId, sitzkontakt)) + geom_point() + xlab("timeID [s]") + ylab("sitzkontakt") + ggtitle("sample 5% of the data")
ggplot(sitzkontakt, aes(sitzkontakt)) + geom_density()
sitzkontakt_filtered <- filter(sitzkontakt, timeId > 10000 & timeId < 13600)
ggplot(sitzkontakt_filtered, aes(sitzkontakt)) + geom_density() + ggtitle("filtered data, timeId between 10k and 13.6k")
ggplot(sitzkontakt_filtered, aes(timeId, sitzkontakt)) + geom_point() + xlab("timeID [s]") + ylab("sitzkontakt")
