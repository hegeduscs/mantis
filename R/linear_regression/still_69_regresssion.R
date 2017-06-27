setwd("D:/datawranglingstuff/Mantis0520datasets/data_sources")

library(dplyr)
library(MASS)
library(car)
library(ggplot2)
library(survival)
library(caret)

#==============================================================================
# Assign driving profiles to the records based on the clustering centers
#==============================================================================

#dont forget to change back the sep argument later!!
fleetmanager.df <- read.table("UCCdataOfApprovedTireChangedFullServiceVehicles_v2.txt", header=TRUE, sep="\t", dec=".", na.strings = c("", " ", "NA"))
#correcting variable names and types
names(fleetmanager.df)[names(fleetmanager.df) == 'ï.¿identifierr'] <- 'identifier'
fleetmanager.df$timestamp <- as.POSIXct(fleetmanager.df$timestamp, format="%d/%m/%Y %H:%M:%S")
fleetmanager.df$readoutduration <- as.numeric(fleetmanager.df$readoutduration)

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

scaled_clustering_columns <- scaled_clustering_columns %>% mutate(diff1 = (average_speed - c69_centers[1,1])^2 + 
                   (drive_only_ratio - c69_centers[1,2])^2 + (lift_only_ratio - c69_centers[1,3])^2 +
                   (lift_and_drive_ratio - c69_centers[1,4])^2 + (norm_number_of_dir_change - c69_centers[1,5])^2) %>%
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

#==============================================================================
# Compile the variables for the regression model + some tests
#==============================================================================

historical_data <- read.table("Wear Tire - Historical Data.csv", header=TRUE, sep=";", encoding = "UTF-8", quote = "")
historical_data$Start.Service <- as.POSIXct(historical_data$Start.Service, format="%Y.%m.%d")
historical_data <- historical_data %>% filter(!is.na(Back.Tyre)) %>%
                    filter(Serial.Number != "516211D00457") %>% filter(Serial.Number != "516215C00622")
#these 2 trucks do not have available fleet manager data at all 

#reading in the questionnaire values for 17 trucks
trucks_with_questionnaire <- read.table("questionnaire_trucks.csv", header=TRUE, sep = ";", dec = ",", stringsAsFactors = FALSE)
trucks_with_questionnaire$identifier <- as.factor(trucks_with_questionnaire$identifier)
trucks_with_questionnaire$beton_floor_ratio <- as.numeric(trucks_with_questionnaire$beton_floor_ratio)
trucks_with_questionnaire$smooth_cement_floor_ratio <- as.numeric(trucks_with_questionnaire$smooth_cement_floor_ratio)

historical_data <- historical_data %>% mutate(profile1_ratio = NA) %>% mutate(profile2_ratio = NA) %>%
  mutate(profile1_hours = NA) %>% mutate(profile2_hours = NA) %>%
  mutate(cumulative_lift_and_drive_time = NA) %>% mutate(cumulative_drive_time = NA) %>%
  mutate(cumulative_lift_time = NA) %>% mutate(cumulative_distance = NA) %>%
  mutate(beton_floor_ratio = NA) %>% mutate(smooth_cement_floor_ratio = NA) %>%
  mutate(floor_contamination = NA) %>% mutate(wet_floor = NA) %>%
  mutate(foreign_parts = NA) %>% mutate(aggressive_media = NA) %>%
  mutate(pulling = NA) %>% mutate(tight_curves = NA) %>%
  mutate(cold_environment = NA) %>% mutate(data_imputation = NA) %>%
  mutate(start_date = NA) %>% mutate(end_date = NA)

#all 3 of these factors have to have the same levels to be comperable
fleetmanager.df$identifier <- factor(fleetmanager.df$identifier, levels=levels(historical_data$Serial.Number))
trucks_with_questionnaire$identifier <- factor(trucks_with_questionnaire$identifier, levels=levels(historical_data$Serial.Number))

#the sum function is overflowing on the liftanddrivetime sums in milisecond -> converting to hours
#not to be confused with lift_and_drive_time, which holds a different value
fleetmanager.df <- fleetmanager.df %>% mutate(readoutduration_hours = readoutduration / (1000*3600))
fleetmanager.df <- fleetmanager.df %>% mutate(lift_hours_when_driving = lift_and_drive_time / (1000*3600))
fleetmanager.df <- fleetmanager.df %>% mutate(drive_time_hours = (drive_only_time + lift_and_drive_time) / (1000*3600))
fleetmanager.df <- fleetmanager.df %>% mutate(distance_km = distance / 1000)

test <- fleetmanager.df %>% filter(readoutduration_hours < lift_and_drive_time_hours)

#1 truck only had front tyre change(s)! the other 2 ID is not in the fleetmanager data, hence the 68 IDs
last.service.df <- data.frame(identifier = unique(historical_data$Serial.Number), last_back_tyre_service = c(rep(NA, 68)))
last.service.df$last_back_tyre_service <- as.POSIXct(last.service.df$last_back_tyre_service, format = "%Y-%m-%d", origin = "2013-02-12")
for(i in 1:nrow(historical_data)){
  truck.fm <- fleetmanager.df %>% filter(identifier == historical_data$Serial.Number[i])
  
  if(is.na(last.service.df[which(last.service.df$identifier == historical_data$Serial.Number[i]),2])){
    fleet.min.date <- min(truck.fm$timestamp)
    hist.earliest.date <- historical_data$Start.Service[i] - (historical_data$Back.Tyre[i] * 3600)
    start.date <- as.POSIXct(ifelse(hist.earliest.date >= fleet.min.date, hist.earliest.date, fleet.min.date), origin = "1970-01-01")
    #start.date <- fleet.min.date
  }else{
    start.date <- last.service.df[which(last.service.df$identifier == historical_data$Serial.Number[i]),2]
  }
  end.date <- historical_data$Start.Service[i]
  last.service.df[which(last.service.df$identifier == historical_data$Serial.Number[i]),2] <- historical_data$Start.Service[i]
  truck.fm.interval <- truck.fm %>% filter(timestamp >= start.date & timestamp <= end.date)
  historical_data$start_date[i] <- start.date
  historical_data$end_date[i] <- end.date
  
  if(nrow(truck.fm.interval) > 500){
    historical_data$profile1_ratio[i] <- table(truck.fm.interval$driving_profile)[1] / sum(table(truck.fm.interval$driving_profile))
    historical_data$profile2_ratio[i] <- table(truck.fm.interval$driving_profile)[2] / sum(table(truck.fm.interval$driving_profile))
    #this next variable is in hours, matching the working hours variable
    historical_data$profile1_hours[i] <- sum(truck.fm.interval$readoutduration_hours[which(truck.fm.interval$driving_profile == 1)])
    historical_data$profile2_hours[i] <- sum(truck.fm.interval$readoutduration_hours[which(truck.fm.interval$driving_profile == 2)])
    historical_data$cumulative_drive_time[i] <- sum(truck.fm.interval$drive_time_hours)
    historical_data$cumulative_lift_time_when_driving[i] <- sum(truck.fm.interval$lift_hours_when_driving)
    #cumulative distance is in kilometers!
    historical_data$cumulative_distance[i] <- sum(truck.fm.interval$distance_km)
    historical_data$data_imputation[i] <- FALSE
  }else{ #this branch is just a data imputation workaround
    historical_data$profile1_ratio[i] <- table(truck.fm$driving_profile)[1] / sum(table(truck.fm$driving_profile))
    historical_data$profile2_ratio[i] <- table(truck.fm$driving_profile)[2] / sum(table(truck.fm$driving_profile))
    historical_data$profile1_hours[i] <- table(truck.fm$driving_profile)[1] / sum(table(truck.fm$driving_profile)) * historical_data$Back.Tyre[i]
    historical_data$profile2_hours[i] <- table(truck.fm$driving_profile)[2] / sum(table(truck.fm$driving_profile)) * historical_data$Back.Tyre[i]
    historical_data$cumulative_drive_time[i] <- sum(truck.fm$drive_time_hours) / sum(truck.fm$readoutduration_hours) * historical_data$Back.Tyre[i]
    historical_data$cumulative_lift_time_when_driving[i] <- sum(truck.fm$lift_hours_when_driving) / sum(truck.fm$readoutduration_hours) * historical_data$Back.Tyre[i]
    historical_data$cumulative_distance[i] <- historical_data$Back.Tyre[i] / sum(truck.fm$readoutduration_hours) * sum(truck.fm$distance_km)
    historical_data$data_imputation[i] <- TRUE
  }

  if(historical_data$Serial.Number[i] %in% trucks_with_questionnaire$identifier){
    questionnaire_row <- trucks_with_questionnaire[which(trucks_with_questionnaire$identifier == historical_data$Serial.Number[i]),]
    historical_data$beton_floor_ratio[i] <- questionnaire_row[2]
    historical_data$smooth_cement_floor_ratio[i] <- questionnaire_row[3]
    historical_data$floor_contamination[i] <- questionnaire_row[4]
    historical_data$wet_floor[i] <- questionnaire_row[5]
    historical_data$foreign_parts[i] <- questionnaire_row[6]
    historical_data$aggressive_media[i] <- questionnaire_row[7]
    historical_data$pulling[i] <- questionnaire_row[8]
    historical_data$tight_curves[i] <- questionnaire_row[9]
    historical_data$cold_environment[i] <- questionnaire_row[10]
  } 
}

#fixing the factor variables
dummy_factor_levels1 = c("Little", "Medium", "Strong")
dummy_factor_levels2 = c("Never", "Sometimes", "Often")
historical_data$beton_floor_ratio <- as.numeric(unlist(historical_data$beton_floor_ratio))
historical_data$smooth_cement_floor_ratio <- as.numeric(unlist(historical_data$smooth_cement_floor_ratio))
historical_data$floor_contamination <- factor(unlist(historical_data$floor_contamination), levels = dummy_factor_levels1)
historical_data$wet_floor <- factor(unlist(historical_data$wet_floor), levels = dummy_factor_levels1)
historical_data$foreign_parts <- factor(unlist(historical_data$foreign_parts), levels = dummy_factor_levels1)
historical_data$aggressive_media <- factor(unlist(historical_data$aggressive_media), levels = dummy_factor_levels1)
historical_data$pulling <- factor(unlist(historical_data$pulling), levels = dummy_factor_levels2)
historical_data$tight_curves <- factor(unlist(historical_data$tight_curves), levels = dummy_factor_levels2)
historical_data$cold_environment <- factor(unlist(historical_data$cold_environment), levels = dummy_factor_levels2)
historical_data$start_date <- as.POSIXct(historical_data$start_date, origin = "1970-01-01")
historical_data$end_date <- as.POSIXct(historical_data$end_date, origin = "1970-01-01")
str(historical_data)

#cleaned historical dataframe with only the relevant columns
columns_needed <- c(10, 22:38, 42)
lm.historical <- historical_data[,columns_needed]
lm.historical.dummies <- lm.historical %>% filter(!is.na(floor_contamination))

#making a new dataframe where the first and last dates are shown in the fleetmanager and historical data, grouped by truck id
truck.dates <- data.frame(last.service.df[,1], fleetmanager_first_date = 1:68, fleetmanager_last_date = 1:68, historical_data_first_date = 1:68, historical_data_last_date = 1:68)
names(truck.dates)[1] <- 'identifier'
truck.dates$identifier <- factor(truck.dates$identifier, levels=levels(historical_data$Serial.Number))
truck.dates$fleetmanager_first_date <- as.POSIXct(truck.dates$fleetmanager_first_date, format = "%Y-%m-%d", origin = "2013-02-12")
truck.dates$fleetmanager_last_date <- as.POSIXct(truck.dates$fleetmanager_last_date, format = "%Y-%m-%d", origin = "2013-02-12")
truck.dates$historical_data_first_date <- as.POSIXct(truck.dates$historical_data_first_date, format = "%Y-%m-%d", origin = "2013-02-12")
truck.dates$historical_data_last_date <- as.POSIXct(truck.dates$historical_data_last_date, format = "%Y-%m-%d", origin = "2013-02-12")

for(j in 1:nrow(truck.dates)){
  truck.fm <- fleetmanager.df %>% filter(identifier == truck.dates$identifier[j])
  historical.rows <- historical_data %>% filter(Serial.Number == truck.dates$identifier[j])
  
  truck.dates$fleetmanager_first_date[j] = min(truck.fm$timestamp)
  truck.dates$fleetmanager_last_date[j] = max(truck.fm$timestamp)
  truck.dates$historical_data_first_date[j] = min(historical.rows$Start.Service)
  truck.dates$historical_data_last_date[j] = max(historical.rows$Start.Service)
}
write.csv2(truck.dates, file = "truck_date_compares.csv", row.names = FALSE)
truck.dates <- truck.dates %>% mutate(historical_covered = ifelse(fleetmanager_first_date <= historical_data_first_date &
                                                                    fleetmanager_last_date >= historical_data_last_date, 1, 0))
sum(truck.dates$historical_covered) #16, 20 if only the first date is considered
#this means 66 entries have their variables calculated, 87 do not have it

ggplot(historical_data, aes(x = Back.Tyre)) + geom_density() + xlab("Back tire working hours")

#==============================================================================
# Fitting different regression models and doing diagnostics on them
#==============================================================================

lm.fit1 <- lm(Back.Tyre ~ profile1_ratio + profile2_ratio + profile1_hours + profile2_hours + 
                cumulative_lift_and_drive_time + cumulative_drive_time + cumulative_lift_time + 
                cumulative_distance, data = lm.historical)

#a bunch of different diagnostics about the fit
variable.selection1 <- stepAIC(lm.fit1, direction="both")
variable.selection1$anova # display results -> suggests to drop profile2_ratio and cumulative_lift_and_drive_time
summary(lm.fit1) #overall F-statistic 14.43 - adjusted R squared 0.412

lm.fit2 <- lm(Back.Tyre ~ profile1_ratio + profile1_hours + profile2_hours + cumulative_drive_time + 
                cumulative_lift_time + cumulative_distance, data = lm.historical)
variable.selection2 <- stepAIC(lm.fit2, direction="both")
variable.selection2$anova
summary(lm.fit2) #overall F-statistic 19.93 - adjusted R squared 0.4212
res.vector.fit2 <- residuals(lm.fit2)
MSE.fit2 <- sum(res.vector.fit2 * res.vector.fit2) / (nrow(lm.historical) - 7) #n-k-1
error.ratio_fit2 = sqrt(MSE.fit2) / mean(lm.historical$Back.Tyre)
anova(lm.fit2)
cor.matrix2 <- cov2cor(vcov(lm.fit2)) #profile1 and profile2 ratio are hihgly correlated
vif(lm.fit2) #minium is 1 (not correlated with the other variables at all), higher values mean higher correlation
plot(lm.fit2)

lm.fit3 <- lm(Back.Tyre ~ profile2_hours + cumulative_lift_time + cumulative_distance, data = lm.historical)
variable.selection3 <- stepAIC(lm.fit3, direction="both")
variable.selection3$anova #suggests to drop profile2_hours
summary(lm.fit3) #overall F-statistic 30.27 - adjusted R squared 0.3662
res.vector.fit3 <- residuals(lm.fit3)
MSE.fit3 <- sum(res.vector.fit3 * res.vector.fit3) / (nrow(lm.historical) - 4) #n-k-1
error.ratio_fit3 = sqrt(MSE.fit3) / mean(lm.historical$Back.Tyre)

lm.fit4 <- lm(Back.Tyre ~ profile1_hours + profile2_hours + cumulative_lift_and_drive_time + cumulative_drive_time + cumulative_lift_time, data = lm.historical)
variable.selection4 <- stepAIC(lm.fit4, direction="both")
variable.selection4$anova #suggests to drop profile2_hours
summary(lm.fit4) #overall F-statistic 18.67 - adjusted R squared 0.3676
res.vector.fit4 <- residuals(lm.fit3)
MSE.fit4 <- sum(res.vector.fit4 * res.vector.fit4) / (nrow(lm.historical) - 6) #n-k-1
error.ratio_fit4 = sqrt(MSE.fit4) / mean(lm.historical$Back.Tyre)

lm.fit5 <- lm(Back.Tyre ~ profile1_hours + cumulative_lift_and_drive_time + cumulative_lift_time, data = lm.historical)
variable.selection5 <- stepAIC(lm.fit5, direction="both")
variable.selection5$anova #suggests to drop profile2_hours
summary(lm.fit5) #overall F-statistic 31.51 - adjusted R squared 0.3758
res.vector.fit5 <- residuals(lm.fit5)
MSE.fit5 <- sum(res.vector.fit5 * res.vector.fit5) / (nrow(lm.historical) - 4) #n-k-1
error.ratio_fit5 = sqrt(MSE.fit5) / mean(lm.historical$Back.Tyre)
vif(lm.fit5)

lm.fit6 <- lm(Back.Tyre ~ profile1_ratio + cumulative_distance, data = lm.historical)
summary(lm.fit6)

lm.fit7 <- lm(Back.Tyre ~ profile1_ratio + profile1_hours + profile2_hours + cumulative_drive_time + 
                cumulative_lift_time + cumulative_distance + beton_floor_ratio + floor_contamination + 
                wet_floor, data = lm.historical.dummies)
summary(lm.fit7)
res.vector.fit7 <- residuals(lm.fit7)
MSE.fit7 <- sum(res.vector.fit7 * res.vector.fit7) / (nrow(lm.historical.dummies) - 10) #n-k-1
error.ratio_fit7 = sqrt(MSE.fit7) / mean(lm.historical.dummies$Back.Tyre)
vif(lm.fit7)
anova(lm.fit7)
cor.matrix7 <- cov2cor(vcov(lm.fit7))
columns_needed <- c(2, 4, 5, 7:10)
cor(lm.historical.dummies$Back.Tyre, lm.historical.dummies[, columns_needed])
alias(lm.fit7)

lm.historical$residual5 <- lm.fit5$residuals 
lm.historical.filtered <- lm.historical %>% filter(Back.Tyre > 1000 & Back.Tyre < 4000 & abs(residual5) < 2000)
lm.fit5.filtered <- lm(Back.Tyre ~ profile1_hours + cumulative_lift_and_drive_time + cumulative_lift_time, data = lm.historical.filtered)
summary(lm.fit5.filtered)
variable.selection5.filtered <- stepAIC(lm.fit5.filtered, direction="both")
variable.selection5.filtered$anova #suggests to drop profile2_hours
res.vector.fit5.filtered <- residuals(lm.fit5.filtered)
MSE.fit5.filtered <- sum(res.vector.fit5.filtered * res.vector.fit5.filtered) / (nrow(lm.historical.filtered) - 4) #n-k-1
error.ratio_fit5.filtered = sqrt(MSE.fit5.filtered) / mean(lm.historical.filtered$Back.Tyre)
plot(lm.fit5.filtered, which = 1)

#==============================================================================
# Checking out the new historical data source
#==============================================================================

historical.df <- read.table("SAP-Serviceberichte-sourcedata.txt", header=TRUE, sep="\t", dec=".", na.strings = c("", " ", "NA"), fill = TRUE, quote = "", encoding = "UTF-8")
