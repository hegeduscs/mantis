setwd("D:/datawranglingstuff/Mantis0520datasets/data_sources")
library(dplyr)
library(ggplot2)
library(caret)
library(doSNOW)
library(Metrics)
library(scales)
library(rpart)
library(rpart.plot)

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
regression.df$start_of_service <- as.POSIXct(regression.df$start_of_service, format = "%Y-%m-%d")
regression.df$end_of_service <- as.POSIXct(regression.df$end_of_service, format = "%Y-%m-%d")
regression.df$fleetmanager_first_date <- as.POSIXct(regression.df$fleetmanager_first_date, format = "%Y-%m-%d")
regression.df$fleetmanager_last_date <- as.POSIXct(regression.df$fleetmanager_last_date, format = "%Y-%m-%d")
regression.df$tire_usage_start_date <- as.POSIXct(regression.df$tire_usage_start_date, format = "%Y-%m-%d")
regression.df$serial_number <- factor(regression.df$serial_number, levels=levels(fleetmanager.df$identifier))

regression.df <- regression.df %>% filter(!is.na(tire_usage_start_date)) %>% mutate(working_hours = NA) %>%
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
  
  regression.df$working_hours[i] <- sum(truck.fm$readoutduration_hours) * multiplier
  regression.df$profile1_ratio[i] <- table(truck.fm$driving_profile)[1] / sum(table(truck.fm$driving_profile))
  regression.df$profile2_ratio[i] <- table(truck.fm$driving_profile)[2] / sum(table(truck.fm$driving_profile))
  regression.df$profile1_hours[i] <- sum(truck.fm$readoutduration_hours[which(truck.fm$driving_profile == 1)]) * multiplier
  regression.df$profile2_hours[i] <- sum(truck.fm$readoutduration_hours[which(truck.fm$driving_profile == 2)]) * multiplier
  regression.df$cumulative_drive_time[i] <- sum(truck.fm$drive_time_hours) * multiplier
  regression.df$cumulative_lift_time_when_driving[i] <- sum(truck.fm$lift_hours_when_driving) * multiplier
  regression.df$cumulative_distance[i] <- sum(truck.fm$distance_km) * multiplier
}

ggplot(regression.df, aes(x = profile1_ratio)) + facet_wrap(~client_name + city_of_usage) + geom_histogram(binwidth = 0.1)
ggplot(regression.df, aes(x = profile1_ratio)) + geom_histogram(binwidth = 0.05)

#==============================================================================
# Regression model 1
#==============================================================================

# selecting the features used in the regression model
regression <- regression.df %>% select(working_hours, client_name, city_of_usage, profile1_ratio, profile2_ratio, 
                                       profile1_hours, profile2_hours, cumulative_drive_time, cumulative_lift_time_when_driving, cumulative_distance)

# Use caret to create a 70/30% split of the training data, while keeping the median of working_hours the same for the splits 
set.seed(1)
indexes <- createDataPartition(regression$working_hours, times = 1, p = 0.7, list = FALSE)
regression.train <- regression[indexes,]
regression.test <- regression[-indexes,]

# Set up caret to perform 10-fold cross validation repeated 3 times and to use a grid search for optimal model hyperparamter values.
train.control <- trainControl(method = "repeatedcv", number = 10, repeats = 3, search = "grid")

# Leverage a grid search of hyperparameters for xgboost.
tune.grid <- expand.grid(eta = c(0.05, 0.075, 0.1, 0.125),
                         nrounds = c(50, 75, 100, 125, 150),
                         max_depth = 4:9,
                         min_child_weight = c(2.0, 2.25, 2.5),
                         colsample_bytree = c(0.2, 0.3, 0.4, 0.5),
                         gamma = 0,
                         subsample = c(0.8, 0.9, 1))
View(tune.grid)


# Use the doSNOW package to enable caret to train in parallel.
cl <- makeCluster(3, type = "SOCK")
# Register cluster so that caret will know to train in parallel.
registerDoSNOW(cl)

# Train the xgboost model using 10-fold CV repeated 3 times and a hyperparameter grid search to train the optimal model.
set.seed(2)
caret.cv <- train(working_hours ~ ., 
                  data = regression.train,
                  method = "xgbTree",
                  tuneGrid = tune.grid,
                  trControl = train.control)
stopCluster(cl)

# Examine caret's processing results
caret.cv$bestTune

best.tune <- subset(caret.cv$results, rownames(caret.cv$results) == 689)
best.tune <- best.tune %>% mutate(tune_number = NA) %>% mutate(test_set_median = NA) %>% mutate(test_set_RMSE = NA)
best.tune$tune_number <- 1
best.tune$test_set_median <- median(regression.test$working_hours)
# Make predictions on the test set using the xgboost model with optimal parameter values
regression.test$predictions <- predict(caret.cv, regression.test)
best.tune$test_set_RMSE <- rmse(regression.test$working_hours, regression.test$predictions)

xgbtImp <- varImp(caret.cv)
plot(xgbtImp)
#based on this profile2_ratio and the dummy variables can be left out

#==============================================================================
# Regression model 2
#==============================================================================

regression2 <- regression.df %>% select(working_hours, profile1_ratio, profile1_hours, profile2_hours, cumulative_drive_time, 
                                        cumulative_lift_time_when_driving, cumulative_distance)

pp2 <- preProcess(regression2[, -1], method = c("center", "scale", "YeoJohnson"))
transformed.regression2 <- cbind(regression2[, 1], predict(pp2, newdata = regression2[, -1]))
names(transformed.regression2)[1] <- "working_hours"

#set.seed(54621)
set.seed(3)
indexes <- createDataPartition(transformed.regression2$working_hours, times = 1, p = 0.7, list = FALSE)
regression2.train <- transformed.regression2[indexes,]
regression2.test <- transformed.regression2[-indexes,]

train.control2 <- trainControl(method = "repeatedcv", number = 3, repeats = 10, search = "grid")

# Leverage a grid search of hyperparameters for xgboost.
tune.grid2 <- expand.grid(eta = c(0.1, 0.125, 0.15),
                         nrounds = c(100, 125, 150, 175),
                         max_depth = 5:7,
                         min_child_weight = c(2.0, 2.25, 2.5),
                         colsample_bytree = c(0.3, 0.4, 0.5),
                         gamma = 0,
                         subsample = 1)

start.time <- Sys.time()
cl <- makeCluster(3, type = "SOCK")
registerDoSNOW(cl)
#set.seed(23457)
set.seed(4)
caret.cv2 <- train(working_hours ~ ., 
                  data = regression2.train,
                  method = "xgbTree",
                  tuneGrid = tune.grid2,
                  trControl = train.control2)
stopCluster(cl)
total.time <- Sys.time() - start.time
total.time

caret.cv2$bestTune
regression2.test$predictions <- predict(caret.cv2, regression2.test)

#RMSE = 593.2338  -- 557.3217 with the big seed
best.tune.temp <- data.frame(c(subset(caret.cv2$results, rownames(caret.cv2$results) == 133), 2, median(regression2.test$working_hours), 
                    rmse(regression2.test$working_hours, regression2.test$predictions)))
names(best.tune.temp) <- names(best.tune)
best.tune <- rbind(best.tune, best.tune.temp) #97
#RMSE on the train set is 496.2157 which is 16.9% of the median value  -- 553.1056 with the big seed

xgbtImp2 <- varImp(caret.cv2)
plot(xgbtImp2)

#==============================================================================
# Regression model 3 - has NaN at evaulation metrics
#==============================================================================

indexes <- c(1, 3, 5, 7)
transformed.regression3 <- transformed.regression2[, indexes]

set.seed(5)
indexes <- createDataPartition(transformed.regression3$working_hours, times = 1, p = 0.7, list = FALSE)
regression3.train <- transformed.regression3[indexes,]
regression3.test <- transformed.regression3[-indexes,]

start.time <- Sys.time()
cl <- makeCluster(3, type = "SOCK")
registerDoSNOW(cl)
set.seed(6)
caret.cv3 <- train(working_hours ~ ., 
                   data = regression3.train,
                   method = "xgbTree",
                   tuneGrid = tune.grid2,
                   trControl = train.control)
stopCluster(cl)
total.time <- Sys.time() - start.time
total.time

caret.cv3$bestTune
regression3.test$predictions <- predict(caret.cv3, regression3.test)

best.tune.temp <- data.frame(c(subset(caret.cv3$results, rownames(caret.cv3$results) == 49), 3, median(regression3.test$working_hours), 
                               rmse(regression3.test$working_hours, regression3.test$predictions)))
names(best.tune.temp) <- names(best.tune)
best.tune <- rbind(best.tune, best.tune.temp)

xgbtImp3 <- varImp(caret.cv3)
plot(xgbtImp3)

#==============================================================================
# Regression model 4 - has NaN at evaulation metrics
#==============================================================================

regression4.train <- regression3.train
regression4.test <- regression3.test

start.time <- Sys.time()
cl <- makeCluster(3, type = "SOCK")
registerDoSNOW(cl)
set.seed(7)
caret.cv4 <- train(working_hours ~ ., 
                   data = regression4.train,
                   method = "xgbTree",
                   tuneGrid = tune.grid2,
                   trControl = train.control2)
stopCluster(cl)
total.time <- Sys.time() - start.time
total.time

caret.cv4$bestTune
regression4.test$predictions <- predict(caret.cv4, regression4.test)

best.tune.temp <- data.frame(c(subset(caret.cv4$results, rownames(caret.cv4$results) == 49), 4, median(regression4.test$working_hours), 
                               rmse(regression4.test$working_hours, regression4.test$predictions)))
names(best.tune.temp) <- names(best.tune)
best.tune <- rbind(best.tune, best.tune.temp)

xgbtImp4 <- varImp(caret.cv4)
plot(xgbtImp4)

#==============================================================================
# Regression model 5
#==============================================================================

regression5 <- regression.df %>% select(working_hours, profile1_ratio, profile1_hours, profile2_hours, cumulative_drive_time, 
                                        cumulative_lift_time_when_driving, cumulative_distance)

pp5 <- preProcess(regression5[, -1], method = c("YeoJohnson"))
transformed.regression5 <- cbind(regression5[, 1], predict(pp5, newdata = regression5[, -1]))
names(transformed.regression5)[1] <- "working_hours"

set.seed(8)
indexes <- createDataPartition(transformed.regression5$working_hours, times = 1, p = 0.7, list = FALSE)
regression5.train <- transformed.regression5[indexes,]
regression5.test <- transformed.regression5[-indexes,]

start.time <- Sys.time()
cl <- makeCluster(3, type = "SOCK")
registerDoSNOW(cl)
set.seed(9)
caret.cv5 <- train(working_hours ~ ., 
                   data = regression5.train,
                   method = "xgbTree",
                   tuneGrid = tune.grid,
                   trControl = train.control2)
stopCluster(cl)
total.time <- Sys.time() - start.time
total.time

caret.cv5$bestTune
regression5.test$predictions <- predict(caret.cv5, regression5.test)

best.tune.temp <- data.frame(c(subset(caret.cv5$results, rownames(caret.cv5$results) == 1764), 5, median(regression5.test$working_hours), 
                               rmse(regression5.test$working_hours, regression5.test$predictions)))
names(best.tune.temp) <- names(best.tune)
best.tune <- rbind(best.tune, best.tune.temp)

xgbtImp5 <- varImp(caret.cv5)
plot(xgbtImp5)

#==============================================================================
# Regression model 6
#==============================================================================

regression6.train <- regression5.train
regression6.test <- regression5.test

start.time <- Sys.time()
cl <- makeCluster(3, type = "SOCK")
registerDoSNOW(cl)
set.seed(10)
caret.cv6 <- train(working_hours ~ ., 
                   data = regression6.train,
                   method = "xgbTree",
                   tuneGrid = tune.grid2,
                   trControl = train.control2)
stopCluster(cl)
total.time <- Sys.time() - start.time
total.time

caret.cv6$bestTune
regression6.test$predictions <- predict(caret.cv6, regression6.test)

best.tune.temp <- data.frame(c(subset(caret.cv6$results, rownames(caret.cv6$results) == 133), 6, median(regression6.test$working_hours), 
                               rmse(regression6.test$working_hours, regression6.test$predictions)))
names(best.tune.temp) <- names(best.tune)
best.tune <- rbind(best.tune, best.tune.temp)

xgbtImp6 <- varImp(caret.cv6)
plot(xgbtImp6)

#==============================================================================
# Regression model 7
#==============================================================================

regression7 <- regression.df %>% select(working_hours, profile1_ratio, profile1_hours, profile2_hours, cumulative_drive_time, 
                                        cumulative_lift_time_when_driving, cumulative_distance)

set.seed(11)
indexes <- createDataPartition(regression7$working_hours, times = 1, p = 0.7, list = FALSE)
regression7.train <- regression7[indexes,]
regression7.test <- regression7[-indexes,]

start.time <- Sys.time()
cl <- makeCluster(3, type = "SOCK")
registerDoSNOW(cl)
set.seed(12)
caret.cv7 <- train(working_hours ~ ., 
                   data = regression7.train,
                   method = "xgbTree",
                   tuneGrid = tune.grid2,
                   trControl = train.control2)
stopCluster(cl)
total.time <- Sys.time() - start.time
total.time

caret.cv7$bestTune
regression7.test$predictions <- predict(caret.cv7, regression7.test)

best.tune.temp <- data.frame(c(subset(caret.cv7$results, rownames(caret.cv7$results) == 25), 7, median(regression7.test$working_hours), 
                               rmse(regression7.test$working_hours, regression7.test$predictions)))
names(best.tune.temp) <- names(best.tune)
best.tune <- rbind(best.tune, best.tune.temp)

xgbtImp7 <- varImp(caret.cv7)
plot(xgbtImp7)



best.tune <- best.tune %>% mutate(error_to_median_ratio = percent(test_set_RMSE / test_set_median))

#==============================================================================
# Some density plots
#==============================================================================

summary(regression.df$days_passed)
ggplot(regression.df, aes(x = days_passed)) + geom_density() + 
  labs(title = "Density function of the tire worn out, all driving profiles") + xlim(37, 807) + ylim(0, 0.0023)

regression.df <- regression.df %>% mutate(profile1_level = as.factor(ifelse(profile1_ratio < 0.25, 1, ifelse(profile1_ratio < 0.9, 2, 3))))
ggplot(regression.df, aes(x = days_passed, fill = profile1_level)) + geom_density(alpha = 0.5) + 
  labs(title = "Density function of the tire wear out", x = "Days Passed", y = "Density") + xlim(37, 807) + ylim(0, 0.005) + 
  scale_fill_discrete(name="Profile 1 ratio", labels=c("< 0.25 (14)", "> 0.25 and < 0.9 (61)", "> 0.9 (17)"))
table(regression.df$profile1_level)

#==============================================================================
# Single decision tree regression model - easier to implement on new data
#==============================================================================

regression8 <- regression.df %>% select(working_hours, profile1_ratio, profile1_hours, profile2_hours, cumulative_drive_time, 
                                        cumulative_lift_time_when_driving, cumulative_distance)

set.seed(13)
indexes <- createDataPartition(regression8$working_hours, times = 1, p = 0.7, list = FALSE)
regression8.train <- regression8[indexes,]
regression8.test <- regression8[-indexes,]

start.time <- Sys.time()
cl <- makeCluster(3, type = "SOCK")
registerDoSNOW(cl)
set.seed(14)

caret.cv8 <- train(working_hours ~ .,
                   data = regression8.train,
                   method = "rpart",
                   tuneLength = 30,
                   trControl = train.control2)
stopCluster(cl)
total.time <- Sys.time() - start.time
total.time

# Plot
prp(caret.cv8$finalModel, type = 0, extra = 1, under = TRUE)

regression8.test$predictions <- predict(caret.cv8, regression8.test)
rmse(regression8.test$working_hours, regression8.test$predictions) #814.31

