#setting workspace directory (modify it accordingly)
setwd("C:/Users/Public/R/still")

#loading in the dplyr package
#install.packages("dplyr")
library(dplyr)
#install.packages("ggplot2")
library(ggplot2)

#read the text file into a data frame
still.df <- read.table("new_still.txt", header=TRUE, sep="\t", dec=",", encoding = "UTF-8")

#renaming the timestamp column with the weird name
names(still.df)[names(still.df) == 'X.U.FEFF.timestamp'] <- 'timestamp'

#making sure the required fields have the correct data type
still.df$timestamp<-as.POSIXct(still.df$timestamp, format="%d.%m.%Y %H:%M:%S")
still.df$readoutduration<-as.numeric(still.df$readoutduration)
still.df$identifier<-as.factor(still.df$identifier)
still.df$drivetime<-as.numeric(still.df$drivetime)
still.df$distance<-as.numeric(still.df$distance)
still.df$maxspeed<-as.numeric(still.df$maxspeed)
still.df$numberofdirectionchanges<-as.numeric(still.df$numberofdirectionchanges)
still.df$energyunit<-as.factor(still.df$energyunit)
still.df$consumedamount<-as.numeric(still.df$consumedamount)

#comparing the old dataset with this newer one, so I look at the rows from 1 day
still.df.1day <- still.df %>% 
  filter(timestamp >= as.POSIXct("2015-12-31 00:00:00") & timestamp <= as.POSIXct("2015-12-31 11:59:59"))
table(still.df$identifier)
table(still.df.1day$identifier)

#convert the timing fields' unit into sec (from msec)
still.df$readoutduration <- still.df$readoutduration /1000
still.df$drivetime <- still.df$drivetime / 1000

#75% of the readoutduration is 10 minutes, 25% is less than 10 minutes
quantile(still.df$readoutduration, probs = seq(0, 1, 0.01))

#summary of some of the most important fields
summary(still.df$distance) #median 480, mean 475.4
summary(still.df$readoutduration) #median 600, mean 515.2
summary(still.df$drivetime) #median 425, mean 364.7

#Feature engineering parts
#1) Average speed feature [km/h]
still.df <- still.df %>% mutate(average_speed = distance / readoutduration * 3.6) #median 3.132, mean 3.148
summary(still.df$average_speed)

#2) Driving ratio feature (%)
still.df <- still.df %>% mutate(driving_ratio = drivetime / readoutduration) #median 0.75, mean 0.6645
summary(still.df$driving_ratio)

#3) Direction change feature - normalized with the maximum readout duration (10 minutes)
still.df <- still.df %>% mutate(direction_changes_10min = numberofdirectionchanges * readoutduration / 600) #median 30, mean 32.42
summary(still.df$direction_changes_10min)

#4) Energy consumption rate (a.k.a. Power) [W]
summary(still.df$consumedamount)

#lets see how corraletad is the consumedamount with the distance and readoutduration
still.df.sampled.0.1percent <- sample_frac(still.df, 0.001)
ggplot(still.df.sampled.0.1percent, aes(distance, consumedamount * 1000)) + geom_point() + xlab("Distance [m]") + ylab("Consumed energy [Wh]")
ggplot(still.df.sampled.0.1percent, aes(readoutduration, consumedamount * 1000)) + geom_point() + xlab("Readout duration [s]") + ylab("Consumed energy [Wh]")

#create the new consumption rate [W] field
still.df <- still.df %>% mutate(consumption_rate = (consumedamount * 1000) / (readoutduration / 3600)) #median 1920, mean 1866
summary(still.df$consumption_rate)

forklift_dist <- still.df %>% count(identifier)
still.df2min <- still.df %>% filter(readoutduration < 120)
forklift_dist2min <- still.df2min %>% count(identifier)
forklift_dist <- left_join(forklift_dist, forklift_dist2min, by = "identifier")
names(forklift_dist)[names(forklift_dist) == 'n.x'] <- 'cardinality'
names(forklift_dist)[names(forklift_dist) == 'n.y'] <- 'cardinality_2min'
forklift_dist <- forklift_dist %>% mutate(cardinality_ratio = cardinality_2min / cardinality)
summary(forklift_dist$cardinality_ratio)

#create a filtered daraframe, which only has the columns needed for clustering
still.clustering.df <- still.df %>% select(average_speed, driving_ratio, direction_changes_10min, consumption_rate)
summary(still.clustering.df)
  
#Let's try clustering with k means
set.seed(100)
#asking for 4 clusters, 20 different random starting assignments
still.cluster.hw4 <- kmeans(still.clustering.df, 4, nstart = 20)
#asking for 7 clusters, 20 different random starting assignments
still.cluster.hw7 <- kmeans(still.clustering.df, 7, nstart = 20, iter.max = 20)

#cluster centers
clustering.hw4.centers <- as.data.frame(still.cluster.hw4$centers)
clustering.hw7centers <- as.data.frame(still.cluster.hw7$centers)

#trying out 2 different algoritms too
still.cluster.lloyd4 <- kmeans(still.clustering.df, 4, iter.max = 20, nstart = 20, algorithm = "Lloyd")
still.cluster.lloyd7 <- kmeans(still.clustering.df, 7, iter.max = 20, nstart = 20, algorithm = "Lloyd")
clustering.lloyd4.centers <- as.data.frame(still.cluster.lloyd4$centers)
clustering.lloyd7.centers <- as.data.frame(still.cluster.lloyd7$centers)

still.cluster.mq4 <- kmeans(still.clustering.df, 4, iter.max = 20, nstart = 20, algorithm = "MacQueen")
still.cluster.mq7 <- kmeans(still.clustering.df, 7, iter.max = 20, nstart = 20, algorithm = "MacQueen")
clustering.mq4.centers <- as.data.frame(still.cluster.mq4$centers)
clustering.mq7.centers <- as.data.frame(still.cluster.mq7$centers)

#append the clustering results to the data frames
still.clustering.df$cluster_of4_hw <- as.factor(still.cluster.hw4$cluster)
still.clustering.df$cluster_of7_hw <- as.factor(still.cluster.hw7$cluster)
table(still.clustering.df$cluster_of4_hw)
table(still.clustering.df$cluster_of7_hw)

still.clustering.df$cluster_of4_lloyd <- as.factor(still.cluster.lloyd4$cluster)
still.clustering.df$cluster_of7_lloyd <- as.factor(still.cluster.lloyd7$cluster)
table(still.clustering.df$cluster_of4_lloyd)
table(still.clustering.df$cluster_of7_lloyd)

still.clustering.df$cluster_of4_mq <- as.factor(still.cluster.mq4$cluster)
still.clustering.df$cluster_of7_mq <- as.factor(still.cluster.mq7$cluster)
table(still.clustering.df$cluster_of4_mq)
table(still.clustering.df$cluster_of7_mq)

clustering.hw4.centers <- clustering.hw4.centers %>% mutate(cluster_cardinality = c(247960, 481249, 647256, 272592))
clustering.hw7centers <- clustering.hw7centers %>% mutate(cluster_cardinality 
                        = c(291297, 360295, 170181, 207902, 211174, 344622, 63586))

#install.packages("Rtsne")
library(Rtsne)

features <- c("average_speed", "driving_ratio", "direction_changes_10min", "consumption_rate")

#takes too long to run on the full data frame :()
#set.seed(200)
#tsne.1 <- Rtsne(still.clustering.df[, features1], check_duplicates = FALSE)
#tsne.2 <- Rtsne(still.clustering.df2[, features2], check_duplicates = FALSE)

#randomly select 0.1% of still.clustering.df
still.clustering.sampled.0.1percent <- sample_frac(still.clustering.df, 0.001)

ggplot(still.clustering.sampled.0.1percent, aes(x = direction_changes_10min, y = average_speed, color = still.clustering.sampled.0.1percent$cluster_of4_hw)) + 
  geom_point() + xlab("Number of direction changes") + 
  ylab("Average speed [km/h]") +
  labs(color = "Cluster") +
  ggtitle("0.1% of the data points randomly chosen, 4 clusters")

ggplot(still.clustering.sampled.0.1percent, aes(x = direction_changes_10min, y = average_speed, color = still.clustering.sampled.0.1percent$cluster_of7_hw)) + 
  geom_point() + xlab("Number of direction changes") + 
  ylab("Average speed [km/h]") +
  labs(color = "Cluster") +
  ggtitle("0.1% of the data points randomly chosen, 7 clusters")

ggplot(still.clustering.sampled.0.1percent, aes(x = driving_ratio, y = consumption_rate, color = still.clustering.sampled.0.1percent$cluster_of4_hw)) + 
  geom_point() + xlab("Driving ratio (%)") + 
  ylab("Consumption rate [W]") +
  labs(color = "Cluster") +
  ggtitle("0.1% of the data points randomly chosen, 4 clusters")

#randomly select 1% of still.clustering.df
still.clustering.sampled.1percent <- sample_frac(still.clustering.df, 0.01)

set.seed(200)
#~5 min calculation
tsne.1 <- Rtsne(still.clustering.sampled.1percent[, features], check_duplicates = FALSE)

ggplot(NULL, aes(x = tsne.1$Y[, 1], y = tsne.1$Y[, 2], color = still.clustering.sampled.1percent$cluster_of4_hw)) +
  geom_point() +
  labs(color = "Cluster") +
  ggtitle("t-DSNE with random 1% of the dataset")

ggplot(NULL, aes(x = tsne.1$Y[, 1], y = tsne.1$Y[, 2], color = still.clustering.sampled.1percent$cluster_of7_hw)) +
  geom_point() +
  labs(color = "Cluster") +
  ggtitle("t-DSNE with random 1% of the dataset")