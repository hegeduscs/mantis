setwd("D:/datawranglingstuff/Mantis0520datasets/data_sources")
library(dplyr)
library(ggplot2)

#==============================================================================
# Feature engineering and extrapolating the fleetmanager data
#==============================================================================

fleetmanager.df <- read.table("UCCdataOfApprovedTireChangedFullServiceVehicles_v2.txt", header=TRUE, sep="\t", dec=".", na.strings = c("", " ", "NA"))
names(fleetmanager.df)[names(fleetmanager.df) == 'ď.żidentifier'] <- 'identifier'
fleetmanager.df$timestamp <- as.POSIXct(fleetmanager.df$timestamp, format="%d/%m/%Y %H:%M:%S")
fleetmanager.df$readoutduration <- as.numeric(fleetmanager.df$readoutduration)
#remove a row with bad timestamp (1970-01-01)
fleetmanager.df <- fleetmanager.df[-1984075, ]

#assigning driving profiles
fleetmanager.df <- fleetmanager.df %>% mutate(drive_only_time = liftanddrivetime - lifttime) %>% 
  mutate(lift_only_time = liftanddrivetime - drivetime) %>%
  mutate(lift_and_drive_time = lifttime + drivetime - liftanddrivetime)

fleetmanager.df <- fleetmanager.df %>% mutate(average_speed = distance / (readoutduration / 1000) * 3.6) %>% 
  mutate(drive_only_ratio = drive_only_time / readoutduration) %>%
  mutate(lift_only_ratio = lift_only_time / readoutduration) %>%
  mutate(lift_and_drive_ratio = lift_and_drive_time / readoutduration) %>%
  mutate(norm_number_of_dir_change = numberofdirectionchanges * readoutduration / 600000)

c69_centers <- read.table("clustering69_centers.csv", header=TRUE, sep=",", dec=".")
scaled_clustering_columns <- as.data.frame(scale(fleetmanager.df %>% select(average_speed, drive_only_ratio, lift_only_ratio,
                                                                            lift_and_drive_ratio, norm_number_of_dir_change)))

scaled_clustering_columns <- scaled_clustering_columns %>% 
  mutate(diff1 = (average_speed - c69_centers[1,1])^2 + (drive_only_ratio - c69_centers[1,2])^2 + 
           (lift_only_ratio - c69_centers[1,3])^2 + (lift_and_drive_ratio - c69_centers[1,4])^2 + 
           (norm_number_of_dir_change - c69_centers[1,5])^2) %>%
  mutate(diff2 = (average_speed - c69_centers[2,1])^2 + (drive_only_ratio - c69_centers[2,2])^2 +
           (lift_only_ratio - c69_centers[2,3])^2 + (lift_and_drive_ratio - c69_centers[2,4])^2 +
           (norm_number_of_dir_change - c69_centers[2,5])^2) %>%
  mutate(diff3 = (average_speed - c69_centers[3,1])^2 + (drive_only_ratio - c69_centers[3,2])^2 +
           (lift_only_ratio - c69_centers[3,3])^2 + (lift_and_drive_ratio - c69_centers[3,4])^2 +
           (norm_number_of_dir_change - c69_centers[3,5])^2) %>%
  mutate(driving_profile = ifelse((diff1 <= diff2) & (diff1 <= diff3), 1, ifelse(diff2 <= diff3, 2, 3)))

#distribution is matching the one I got at clustering (72.1%, 26.6%, 1.2%)
table(scaled_clustering_columns$driving_profile)
fleetmanager.df$driving_profile <- scaled_clustering_columns$driving_profile
#the sum can possibly overflow on the variables if they are in milliseconds
fleetmanager.df <- fleetmanager.df %>% mutate(readoutduration_hours = readoutduration / (1000*3600)) %>% 
  mutate(lift_hours_when_driving = lift_and_drive_time / (1000*3600)) %>% 
  mutate(drive_time_hours = (drive_only_time + lift_and_drive_time) / (1000*3600)) %>% 
  mutate(distance_km = distance / 1000)

#want to check if a linear extrapolation of the fleetmanager data more or less accurate or not
#i can use 2+ years of fleetmanager data from the same truck to check if our parameters are linear with time or not
linear.test.df <- filter(fleetmanager.df, identifier == "516215E00274") %>%  #516215E00274  516215D00237
  select(timestamp, driving_profile, readoutduration, readoutduration_hours, drive_time_hours, lift_hours_when_driving, distance_km) %>% 
  arrange(timestamp) %>%
  mutate(profile1_count = NA) %>% mutate(profile2_count = NA) %>%
  mutate(profile1_ratio = NA) %>% mutate(profile2_ratio = NA) %>%
  mutate(profile1_hours = NA) %>% mutate(profile2_hours = NA) %>%
  mutate(cumulative_drive_time = NA) %>% mutate(cumulative_lift_time_when_driving = NA) %>% mutate(cumulative_distance = NA)

linear.test.df[1, 8:16] <- c(1, 0, 1, 0, 0.0797222222, 0, 0.0613888889, 0.0180555556, 0.185)
#linear.test.df[1, 8:16] <- c(1, 0, 1, 0, 0.0163888889, 0, 0, 0, 0)
for(i in 2:nrow(linear.test.df)){
  if(linear.test.df$driving_profile[i] == 1){
    linear.test.df$profile1_count[i] <- linear.test.df$profile1_count[i - 1] + 1
    linear.test.df$profile2_count[i] <- linear.test.df$profile2_count[i - 1]
    linear.test.df$profile1_hours[i] <- linear.test.df$profile1_hours[i - 1] + linear.test.df$readoutduration_hours[i]
    linear.test.df$profile2_hours[i] <- linear.test.df$profile2_hours[i - 1]
  }
  else if(linear.test.df$driving_profile[i] == 2){
    linear.test.df$profile1_count[i] <- linear.test.df$profile1_count[i - 1]
    linear.test.df$profile2_count[i] <- linear.test.df$profile2_count[i - 1] + 1
    linear.test.df$profile1_hours[i] <- linear.test.df$profile1_hours[i - 1]
    linear.test.df$profile2_hours[i] <- linear.test.df$profile2_hours[i - 1] + linear.test.df$readoutduration_hours[i]
  }
  else{
    linear.test.df$profile1_count[i] <- linear.test.df$profile1_count[i - 1]
    linear.test.df$profile2_count[i] <- linear.test.df$profile2_count[i - 1]
    linear.test.df$profile1_hours[i] <- linear.test.df$profile1_hours[i - 1]
    linear.test.df$profile2_hours[i] <- linear.test.df$profile2_hours[i - 1]
  }
  linear.test.df$profile1_ratio[i] <- linear.test.df$profile1_count[i] / i
  linear.test.df$profile2_ratio[i] <- linear.test.df$profile2_count[i] / i
  linear.test.df$cumulative_drive_time[i] <- linear.test.df$cumulative_drive_time[i - 1] + linear.test.df$drive_time_hours[i]
  linear.test.df$cumulative_lift_time_when_driving[i] <- linear.test.df$cumulative_lift_time_when_driving[i - 1] + linear.test.df$lift_hours_when_driving[i]
  linear.test.df$cumulative_distance[i] <- linear.test.df$cumulative_distance[i - 1] + linear.test.df$distance_km[i]
}

#the linear nature of the variables is well seen on these plots, linear extrapolation is possible
ggplot(aes(x = timestamp, y = cumulative_drive_time), data = linear.test.df) + geom_line() + theme_bw()
ggplot(aes(x = timestamp, y = cumulative_drive_time), data = linear.test.df[1:1000,]) + geom_line() + theme_bw()
ggplot(aes(x = timestamp, y = cumulative_distance), data = linear.test.df) + geom_line() + theme_bw()
ggplot(aes(x = timestamp, y = cumulative_lift_time_when_driving), data = linear.test.df) + geom_line() + theme_bw()
ggplot(aes(x = timestamp, y = profile1_hours), data = linear.test.df) + geom_line() + theme_bw()
ggplot(aes(x = timestamp, y = profile1_ratio), data = linear.test.df) + geom_line() + theme_bw()
ggplot(aes(x = timestamp, y = profile2_ratio), data = linear.test.df) + geom_line() + theme_bw()

regression.df <- read.table("text_analys/Tire_RUL_service_reports.csv", header=TRUE, sep=";", dec=",", na.strings = c("", " ", "NA"))
regression.df$service_comments <- as.character(regression.df$service_comments)
regression.df$start_of_service <- as.POSIXct(regression.df$start_of_service, format = "%Y.%m.%d")
regression.df$end_of_service <- as.POSIXct(regression.df$end_of_service, format = "%Y.%m.%d")
regression.df$fleetmanager_first_date <- as.POSIXct(regression.df$fleetmanager_first_date, format = "%Y.%m.%d")
regression.df$fleetmanager_last_date <- as.POSIXct(regression.df$fleetmanager_last_date, format = "%Y.%m.%d")
regression.df$tire_usage_start_date <- as.POSIXct(regression.df$tire_usage_start_date, format = "%Y.%m.%d")
regression.df$serial_number <- factor(regression.df$serial_number, levels=levels(fleetmanager.df$identifier))

regression.df <- regression.df %>% filter(!is.na(tire_usage_start_date)) %>% 
  mutate(profile1_ratio = NA) %>% mutate(profile2_ratio = NA) %>%
  mutate(profile1_hours = NA) %>% mutate(profile2_hours = NA) %>%
  mutate(cumulative_drive_time = NA) %>% mutate(cumulative_lift_time_when_driving = NA) %>% 
  mutate(cumulative_distance = NA) %>% mutate(entry_frequency = NA)

for(i in 1:nrow(regression.df)){
  truck.fm <- fleetmanager.df %>% filter(identifier == regression.df$serial_number[i]) %>% 
    filter(timestamp >= regression.df$tire_usage_start_date[i] & timestamp <= regression.df$end_of_service[i])
  regression.df$entry_frequency[i] <- nrow(truck.fm) / as.numeric((regression.df$end_of_service[i] - regression.df$tire_usage_start_date[i]))
}

#extrapolating the fleetmanager data for every service report row...
for(i in 1:nrow(regression.df)){
  truck.fm <- fleetmanager.df %>% filter(identifier == regression.df$serial_number[i])
  multiplier <- as.numeric(regression.df$end_of_service[i] - regression.df$tire_usage_start_date[i]) / as.numeric(regression.df$fleetmanager_last_date[i] - regression.df$fleetmanager_first_date[i])
  
  regression.df$profile1_ratio[i] <- table(truck.fm$driving_profile)[1] / sum(table(truck.fm$driving_profile))
  regression.df$profile2_ratio[i] <- table(truck.fm$driving_profile)[2] / sum(table(truck.fm$driving_profile))
  regression.df$profile1_hours[i] <- sum(truck.fm$readoutduration_hours[which(truck.fm$driving_profile == 1)]) * multiplier
  regression.df$profile2_hours[i] <- sum(truck.fm$readoutduration_hours[which(truck.fm$driving_profile == 2)]) * multiplier
  regression.df$cumulative_drive_time[i] <- sum(truck.fm$drive_time_hours) * multiplier
  regression.df$cumulative_lift_time_when_driving[i] <- sum(truck.fm$lift_hours_when_driving) * multiplier
  regression.df$cumulative_distance[i] <- sum(truck.fm$distance_km) * multiplier
}

#TODO: check the validity of the results
