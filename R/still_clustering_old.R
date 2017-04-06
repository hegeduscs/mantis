#setting workspace directory (modify it accordingly)
setwd("C:/Users/Public/R/still")

#loading in the dplyr package
#install.packages("dplyr")
library(dplyr)
#install.packages("ggplot2")
library(ggplot2)

#read the csv file into a data frame
still.df <- read.csv("merged_still_cleaned.csv",header=TRUE)

#making sure the required fields have the correct data type
still.df$distance<-as.numeric(still.df$distance)
still.df$maxspeed<-as.numeric(still.df$maxspeed)
still.df$numberofdirectionchanges<-as.numeric(still.df$numberofdirectionchanges)
still.df$readoutduration<-as.numeric(still.df$readoutduration)
still.df$drivetime<-as.numeric(still.df$drivetime)
still.df$lifttime<-as.numeric(still.df$lifttime)
still.df$consumedamount<-as.numeric(still.df$consumedamount)
still.df$energyunit<-as.factor(still.df$energyunit)
still.df$identifier<-as.factor(still.df$identifier)
still.df$metatimestamp<-as.POSIXct(still.df$metatimestamp, format="%Y-%m-%d %H:%M:%S")

#summary of some of the most important fields
summary(still.df$distance) #m, median 200, mean 307.2, 708k NA
summary(still.df$readoutduration) #ms median 10 minutes, 506k NA
summary(still.df$drivetime) #ms, 708k NA
summary(still.df$lifttime) #ms, 708k NA

#omit the rows from the data frame where the 'readoutduration' is NA
#this field is a must have for the clustering and almost all of these rows are missing all the other fields too
still.df <- still.df %>% filter(!is.na(readoutduration))

#Feature engineering parts
#1) Average speed feature [km/h]
still.df <- still.df %>% mutate(average_speed = distance / readoutduration * 1000 * 3.6) #median 2.01, mean 2.32, 202k NA

#2) Driving ratio feature (%)
still.df <- still.df %>% mutate(driving_ratio = drivetime / readoutduration) #median 0.56, mean 0.51, 202k NA

#3) Lifting ratio feature (%)
still.df <- still.df %>% mutate(lifting_ratio = lifttime / readoutduration) #median 0.14, mean 0.16, 202k NA

#4) Energy consumption rate (a.k.a. Power) [kW]
#First we need to assign the battery voltage to each forklift where it's available
battery.voltages <- data.frame(identifier = c("515063B00279", "515063B00287", 
                                              "516210D00488", "516213C00241", "516213C00247","516215D00843", "516215D00862", "516215D00871",
                                              "516315D00171", "516325C00662",
                                              "517312D00011", "517322D00149"),
                               battery_voltage = c(rep("24", 2),
                                                 rep("48", 6),
                                                 rep("80", 2),
                                                 rep(NA, 2)),
                               stringsAsFactors = FALSE)

#must have data type conversions (factor to numeric directly is problematic, hence the stringsAsFactors = FALSE)
battery.voltages$identifier <- as.factor(battery.voltages$identifier)
battery.voltages$battery_voltage <- as.numeric(battery.voltages$battery_voltage)

#Using left join on still.df and battery.voltages
still.df <- still.df %>% left_join(battery.voltages, by = "identifier")

#Summaries about the consumed amounts. 
#The 3rd energy unit option (FUEL_LITERS) has much less rows, and it can't be converted into Watts, so those rows are left out.
table(still.df$energyunit)
ah.units <- still.df %>% filter(energyunit == "BATTERY_AMPERE_HOURS")
kwh.units <- still.df %>% filter(energyunit == "KWH")
fuel.units <- still.df %>% filter(energyunit == "FUEL_LITERS")
summary(ah.units$consumedamount)
summary(kwh.units$consumedamount)
summary(fuel.units$consumedamount)

#converting the consumedamount from Ah to kWh
converted.ah.units <- ah.units %>% 
  mutate(consumedamount = consumedamount * battery_voltage / 1000) %>%
  mutate(energyunit = "KWH")
summary(converted.ah.units$consumedamount)

#the mean and median values of the converted units looks good, let's make this change in still.df too
#first the consumedamount column - we are gonna ignore the consumedamounts in fuel, so we put in NA there
still.df <- mutate(still.df, consumedamount = ifelse(grepl("BATTERY_AMPERE_HOURS", energyunit), consumedamount * battery_voltage / 1000, 
                                              ifelse(grepl("FUEL_LITERS", energyunit), NA, consumedamount)))

#then replace the energyunit values too (this is probably a way too complicated way to do it)
still.df <- mutate(still.df, energyunit = ifelse(grepl("BATTERY_AMPERE_HOURS", energyunit), "KWH", 
                                          ifelse(grepl("KWH", energyunit), "KWH", 
                                          ifelse(grepl("FUEL_LITERS", energyunit), "FUEL_LITERS", NA))))
summary(still.df$consumedamount)
still.df$energyunit <- as.factor(still.df$energyunit)
summary(still.df$energyunit)

#because these consumption rates seem very high to me, 
#i just wanna make sure that they are at least somewhat correlated to the distance and readoutduration variables
ggplot(still.df, aes(distance, consumedamount)) + geom_point() + xlab("Distance [m]") + ylab("Consumed energy [kWh]")
ggplot(still.df, aes(readoutduration, consumedamount)) + geom_point() + xlab("Readout duration [ms]") + ylab("Consumed energy [kWh]")

#and finally create the new consumption rate [kW] field (there is a function called power)
still.df <- still.df %>% mutate(consumption_rate = consumedamount / readoutduration * 3600 * 1000) #median 254.1, mean 299.1, 719k NA
                   
#create filtered dataframe, dropping the columns which were not used (+ keeping ID and metatimestamp)
still.stripped.df <- still.df %>% select(distance, maxspeed, numberofdirectionchanges, readoutduration, 
                                         drivetime, lifttime, consumedamount, energyunit, identifier, 
                                         metatimestamp, average_speed, driving_ratio, lifting_ratio, 
                                         battery_voltage, consumption_rate)

#create an even more filtered daraframe, which only has the columns needed for clustering
still.clustering.df <- still.df %>% select(numberofdirectionchanges, average_speed, driving_ratio, 
                                           lifting_ratio, consumption_rate)

#filter out rows which have more than 3 NA values
still.clustering.df$na_count <- rowSums(is.na(still.clustering.df))
still.clustering.df <- still.clustering.df %>% filter(na_count < 3) #roughly 212k rows filtered out

#fill in the rest of the missing values with median and mean values
summary(still.clustering.df$numberofdirectionchanges) #median 13, mean 16.7 -> replace NA with median
still.clustering.df$numberofdirectionchanges[is.na(still.clustering.df$numberofdirectionchanges)] <- 13

summary(still.clustering.df$average_speed) #median 1.896, mean 2.252 -> replace NA with median
still.clustering.df$average_speed[is.na(still.clustering.df$average_speed)] <- 1.896

summary(still.clustering.df$driving_ratio) #median 0.5405, mean 0.4949 -> replace NA with mean
still.clustering.df$driving_ratio[is.na(still.clustering.df$driving_ratio)] <- 0.4949

summary(still.clustering.df$lifting_ratio) #median 0.1321, mean 0.1608 -> replace NA with median
still.clustering.df$lifting_ratio[is.na(still.clustering.df$lifting_ratio)] <- 0.1321

summary(still.clustering.df$consumption_rate) #median 246, mean 279.8, 585k NA which is more than half of them!
na.consumption <- still.clustering.df %>% filter(is.na(consumption_rate))
#based on the summaries of na.consumption and still.clustering.df, 210 seems like a reasonable replacement for NA values
still.clustering.df$consumption_rate[is.na(still.clustering.df$consumption_rate)] <- 210

#but this is such a drastic data imputation, that I'm gonna do a clustering without the consumption_rate field too
still.clustering.df2 <- still.clustering.df %>% select(-consumption_rate)

#creating a new csv file from still.stripped.df
still.clustering.df <- still.clustering.df %>% select(-na_count)
write.csv2(still.clustering.df, file = "still_clustering.csv", row.names = FALSE)
still.clustering.df2 <- still.clustering.df2 %>% select(-na_count)

#Let's try clustering with k means
set.seed(100)
#clustering with consumption_rate, asking for 4 clusters, 20 different random starting assignments
still.cluster1 <- kmeans(still.clustering.df, 4, nstart = 20)
#clustering with consumption_rate, asking for 7 clusters, 20 different random starting assignments
still.cluster2 <- kmeans(still.clustering.df, 7, nstart = 20)
#clustering without consumption_rate, asking for 4 clusters, 20 different random starting assignments
still.cluster3 <- kmeans(still.clustering.df2, 4, nstart = 20)
#clustering without consumption_rate, asking for 7 clusters, 20 different random starting assignments
still.cluster4 <- kmeans(still.clustering.df2, 7, nstart = 20)

#append the clustering results to the data frames
still.clustering.df$cluster_of4 <- as.factor(still.cluster1$cluster)
still.clustering.df$cluster_of7 <- as.factor(still.cluster2$cluster)
still.clustering.df2$cluster_of4 <- as.factor(still.cluster3$cluster)
still.clustering.df2$cluster_of7 <- as.factor(still.cluster4$cluster)

#install.packages("Rtsne")
library(Rtsne)

features1 <- c("numberofdirectionchanges", "average_speed", "driving_ratio", "lifting_ratio", "consumption_rate")
features2 <- c("numberofdirectionchanges", "average_speed", "driving_ratio", "lifting_ratio")

set.seed(200)
#takes too long to run on the full data frame :()
#tsne.1 <- Rtsne(still.clustering.df[, features1], check_duplicates = FALSE)
#tsne.2 <- Rtsne(still.clustering.df2[, features2], check_duplicates = FALSE)

ggplot(still.clustering.df, aes(x = numberofdirectionchanges, y = average_speed, color = still.clustering.df$cluster_of4)) + 
  geom_point() + xlab("Number of direction changes") + 
  ylab("Average speed [km/h]") +
  labs(color = "Cluster")

#randomly select 0.1% of still.clustering.df
still.clustering.sampled <- sample_frac(still.clustering.df, 0.001)

ggplot(still.clustering.sampled, aes(x = numberofdirectionchanges, y = average_speed, color = still.clustering.sampled$cluster_of4)) + 
  geom_point() + xlab("Number of direction changes") + 
  ylab("Average speed [km/h]") +
  labs(color = "Cluster")

ggplot(still.clustering.sampled, aes(x = numberofdirectionchanges, y = average_speed, color = still.clustering.sampled$cluster_of7)) + 
  geom_point() + xlab("Number of direction changes") + 
  ylab("Average speed [km/h]") +
  labs(color = "Cluster")

ggplot(still.clustering.df, aes(x = driving_ratio, y = consumption_rate, color = still.clustering.df$cluster_of4)) + 
  geom_point() + xlab("Driving ratio (%)") + 
  ylab("Consumption rate [kW]") +
  labs(color = "Cluster")

ggplot(still.clustering.sampled, aes(x = driving_ratio, y = consumption_rate, color = still.clustering.sampled$cluster_of4)) + 
  geom_point() + xlab("Driving ratio (%)") + 
  ylab("Consumption rate [kW]") +
  labs(color = "Cluster")

clustering1.centers <- as.data.frame(still.cluster1$centers)
clustering2.centers <- as.data.frame(still.cluster2$centers)
clustering3.centers <- as.data.frame(still.cluster3$centers)
clustering4.centers <- as.data.frame(still.cluster4$centers)

#~5 min calculations each
tsne.1 <- Rtsne(still.clustering.df[1:20000, features1], check_duplicates = FALSE)
tsne.2 <- Rtsne(still.clustering.df2[1:20000, features2], check_duplicates = FALSE)

ggplot(NULL, aes(x = tsne.1$Y[, 1], y = tsne.1$Y[, 2], color = still.clustering.df2$cluster_of4[1:20000])) +
  geom_point() +
  labs(color = "Cluster")

ggplot(NULL, aes(x = tsne.1$Y[, 1], y = tsne.1$Y[, 2], color = still.clustering.df2$cluster_of7[1:20000])) +
  geom_point() +
  labs(color = "Cluster")

ggplot(NULL, aes(x = tsne.2$Y[, 1], y = tsne.2$Y[, 2], color = still.clustering.df2$cluster_of4[1:20000])) +
  geom_point() +
  labs(color = "Cluster")

ggplot(NULL, aes(x = tsne.2$Y[, 1], y = tsne.2$Y[, 2], color = still.clustering.df2$cluster_of7[1:20000])) +
  geom_point() +
  labs(color = "Cluster")

table(still.cluster3$cluster)
