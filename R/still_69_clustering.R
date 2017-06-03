setwd("D:/datawranglingstuff/0520datasets")

library(dplyr)
library(clustertend)
library(cluster)
library(ggplot2)
library(RColorBrewer)
library(Rtsne)

#69 unique truck ids
fleetmanager69 <- read.table("UCCdataOfApprovedTireChangedFullServiceVehicles_v2.txt", header=TRUE, sep="\t", dec=".", encoding = "UTF-8", quote = "")

#==============================================================================
# Data cleaning, filtering
#==============================================================================

#correcting variable names and types
str(fleetmanager69)
names(fleetmanager69)[names(fleetmanager69) == 'X.U.FEFF.identifier'] <- 'identifier'
fleetmanager69$timestamp <- as.POSIXct(fleetmanager69$timestamp, format="%d/%m/%Y %H:%M:%S")
fleetmanager69$readoutduration <- as.numeric(fleetmanager69$readoutduration)

summary(fleetmanager69)

#3-4% of the readouts are less then 1 minute, which could skew the clustering, so i'm filtering those out
#also filter out rows where the driving ratio is less than 5%
fleetmanager69 <- fleetmanager69 %>% filter(readoutduration >= 60000) %>%
                                     filter(drivetime / readoutduration > 0.05)



fleetmanager69 <- fleetmanager69 %>% mutate(drive_only_time = liftanddrivetime - lifttime) %>% 
                                     mutate(lift_only_time = liftanddrivetime - drivetime) %>%
                                     mutate(lift_and_drive_time = lifttime + drivetime - liftanddrivetime)

fleetmanager69 <- fleetmanager69 %>% mutate(average_speed = distance / (readoutduration / 1000) * 3.6) %>% 
                                     mutate(drive_only_ratio = drive_only_time / readoutduration) %>%
                                     mutate(lift_only_ratio = lift_only_time / readoutduration) %>%
                                     mutate(lift_and_drive_ratio = lift_and_drive_time / readoutduration) %>%
                                     mutate(norm_number_of_dir_change = numberofdirectionchanges * readoutduration / 600000)

#filter the outlier entries at the max values of the useful variables for better cluster centers
fleetmanager69 <- fleetmanager69 %>% filter(average_speed < 10) #817 filtered rows
fleetmanager69 <- fleetmanager69 %>% filter(norm_number_of_dir_change < 135) #653 filtered rows

fleetmanager.kwh <- fleetmanager69 %>% filter(energyunit == "KWH") %>% 
                    mutate(consumption_rate = (consumedamount * 1000) / (readoutduration / 1000 / 3600)) %>%
                    filter(consumption_rate < 3600) #33396 filtered rows

clustering69 <- fleetmanager69 %>% select(average_speed, drive_only_ratio, lift_only_ratio, lift_and_drive_ratio, norm_number_of_dir_change)
clustering.kwh <- fleetmanager.kwh %>% select(average_speed, drive_only_ratio, lift_only_ratio, lift_and_drive_ratio, norm_number_of_dir_change, consumption_rate)

summary(clustering69)
summary(clustering.kwh)

#==============================================================================
# Checking hopkins statistic, which might show the cluster tendency
#==============================================================================

# set.seed(100)
# #0.5% of the rows ~ 11700 (computing hopkins statistic is expensive)
# sampled.clustering <- sample_frac(clustering69, 0.005)
# set.seed(100)
# hopkins(sampled.clustering, n = nrow(sampled.clustering) - 1) #0.05078556 scaled / 0.09179644 unscaled
# 
# set.seed(101)
# sampled.clustering.kwh <- sample_frac(clustering.kwh, 0.007) #0.7% of the rows ~ 10300
# set.seed(101)
# hopkins(sampled.clustering.kwh, n = nrow(sampled.clustering.kwh) - 1) #0.06915699 scaled / 0.05498509 unscaled
# close to 0 values implies uniform distributions of the dataset

#==============================================================================
# Clustering without consumption rate
#==============================================================================

scaled.clustering69 <- data.frame(scale(clustering69))
set.seed(100)
kmeans.clusters69 <- kmeans(scaled.clustering69, 50, nstart = 20, iter.max=100)
kmeans.centers <- as.data.frame(kmeans.clusters69$centers)
scaled.clustering69$cluster_of_50 <- as.factor(kmeans.clusters69$cluster)

agnes.single <- agnes(kmeans.centers, diss = FALSE, metric = "euclidean", stand = FALSE, method = "single", trace.lev = 2)
plot(as.hclust(agnes.single))

agnes.ward <- agnes(kmeans.centers, diss = FALSE, metric = "euclidean", stand = FALSE, method = "ward", trace.lev = 2)
plot(as.hclust(agnes.ward))

agnes.weighted <- agnes(kmeans.centers, diss = FALSE, metric = "euclidean", stand = FALSE, method = "weighted", trace.lev = 2)
plot(as.hclust(agnes.weighted))

distances <- dist(kmeans.centers, method = "euclidean")

hclust.ward <- hclust(distances, method = "ward.D2" )
plot(hclust.ward)

hclust.centroid <- hclust(distances, method = "centroid" )
plot(hclust.centroid)

#based on the dendograms and intuation I like the 2 ward methods best, going to convert these back to the original clustering69 dataframe
#tree cutting
kmeans.centers$agnes_ward3 <- cutree(agnes.ward, 3)
kmeans.centers$hclust_ward3 <- cutree(hclust.ward, 3)
#all 50 kmeans center got the same cluster group (1-3) from the 2 functions

kmeans_cluster3 <- kmeans.centers$agnes_ward3
scaled.clustering69 <- mutate(scaled.clustering69, cluster_of_3 = as.factor(kmeans_cluster3[cluster_of_50]))
clustering69$cluster_of_3 <- scaled.clustering69$cluster_of_3

cluster1_entries <- filter(clustering69, cluster_of_3 == 1) #73.64%
cluster2_entries <- filter(clustering69, cluster_of_3 == 2) #25.37%
cluster3_entries <- filter(clustering69, cluster_of_3 == 3) #0.9%

cluster1_center <- c(mean(cluster1_entries$average_speed), mean(cluster1_entries$drive_only_ratio), 
                     mean(cluster1_entries$lift_only_ratio), mean(cluster1_entries$lift_and_drive_ratio), 
                     mean(cluster1_entries$norm_number_of_dir_change))

cluster2_center <- c(mean(cluster2_entries$average_speed), mean(cluster2_entries$drive_only_ratio), 
                     mean(cluster2_entries$lift_only_ratio), mean(cluster2_entries$lift_and_drive_ratio), 
                     mean(cluster2_entries$norm_number_of_dir_change))

cluster3_center <- c(mean(cluster3_entries$average_speed), mean(cluster3_entries$drive_only_ratio), 
                     mean(cluster3_entries$lift_only_ratio), mean(cluster3_entries$lift_and_drive_ratio), 
                     mean(cluster3_entries$norm_number_of_dir_change))

clustering69_centers <- data.frame(rbind(cluster1_center, cluster2_center, cluster3_center))
names(clustering69_centers) = c("average_speed", "drive_only_ratio", "lift_only_ratio", "lift_and_drive_ratio", "norm_number_of_dir_change")
#at first look this could be a valid clustering, since the relationship among the matching variables from different 
# clusters are not purely linear + the distance between the centers are big enough

#I'm interested in the single linkage cluster centers too
kmeans.centers$agnes_single4 <- cutree(agnes.single, 4)
kmeans_cluster4_single <- kmeans.centers$agnes_single4
scaled.clustering69 <- mutate(scaled.clustering69, cluster_of_4_single = as.factor(kmeans_cluster4_single[cluster_of_50]))
clustering69$cluster_of_4_single <- scaled.clustering69$cluster_of_4_single

cluster1_single <- filter(clustering69, cluster_of_4_single == 1) #95.74%
cluster2_single <- filter(clustering69, cluster_of_4_single == 2) #3.28%
cluster3_single <- filter(clustering69, cluster_of_4_single == 3) #0.33%
cluster4_single <- filter(clustering69, cluster_of_4_single == 4) #0.65%

cluster1_single_center <- c(mean(cluster1_single$average_speed), mean(cluster1_single$drive_only_ratio), 
                     mean(cluster1_single$lift_only_ratio), mean(cluster1_single$lift_and_drive_ratio), 
                     mean(cluster1_single$norm_number_of_dir_change))

cluster2_single_center <- c(mean(cluster2_single$average_speed), mean(cluster2_single$drive_only_ratio), 
                     mean(cluster2_single$lift_only_ratio), mean(cluster2_single$lift_and_drive_ratio), 
                     mean(cluster2_single$norm_number_of_dir_change))

cluster3_single_center <- c(mean(cluster3_single$average_speed), mean(cluster3_single$drive_only_ratio), 
                     mean(cluster3_single$lift_only_ratio), mean(cluster3_single$lift_and_drive_ratio), 
                     mean(cluster3_single$norm_number_of_dir_change))

cluster4_single_center <- c(mean(cluster4_single$average_speed), mean(cluster4_single$drive_only_ratio), 
                            mean(cluster4_single$lift_only_ratio), mean(cluster4_single$lift_and_drive_ratio), 
                            mean(cluster4_single$norm_number_of_dir_change))

clustering69_centers_single <- data.frame(rbind(cluster1_single_center, cluster2_single_center, cluster3_single_center, cluster4_single_center))
names(clustering69_centers_single) = c("average_speed", "drive_only_ratio", "lift_only_ratio", "lift_and_drive_ratio", "norm_number_of_dir_change")

#and finally the centroid linkage
kmeans.centers$agnes_centroid3 <- cutree(hclust.centroid, 3)
kmeans_cluster3_centroid <- kmeans.centers$agnes_centroid3
scaled.clustering69 <- mutate(scaled.clustering69, cluster_of_3_centroid = as.factor(kmeans_cluster3_centroid[cluster_of_50]))
clustering69$cluster_of_3_centroid <- scaled.clustering69$cluster_of_3_centroid

centroid_center1 <- filter(clustering69, cluster_of_3_centroid == 1) #99.01%
centroid_center2 <- filter(clustering69, cluster_of_3_centroid == 2) #0.33%
centroid_center3 <- filter(clustering69, cluster_of_3_centroid == 3) #0.65%

centroid_cluster1_center <- c(mean(centroid_center1$average_speed), mean(centroid_center1$drive_only_ratio), 
                            mean(centroid_center1$lift_only_ratio), mean(centroid_center1$lift_and_drive_ratio), 
                            mean(centroid_center1$norm_number_of_dir_change))

centroid_cluster2_center <- c(mean(centroid_center2$average_speed), mean(centroid_center2$drive_only_ratio), 
                            mean(centroid_center2$lift_only_ratio), mean(centroid_center2$lift_and_drive_ratio), 
                            mean(centroid_center2$norm_number_of_dir_change))

centroid_cluster3_center <- c(mean(centroid_center3$average_speed), mean(centroid_center3$drive_only_ratio), 
                            mean(centroid_center3$lift_only_ratio), mean(centroid_center3$lift_and_drive_ratio), 
                            mean(centroid_center3$norm_number_of_dir_change))

clustering69_centroid_centers <- data.frame(rbind(centroid_cluster1_center, centroid_cluster2_center, centroid_cluster3_center))
names(clustering69_centroid_centers) = c("average_speed", "drive_only_ratio", "lift_only_ratio", "lift_and_drive_ratio", "norm_number_of_dir_change")
#centroid cluster number 2 and 3 matches perfectly with single cluster number 3 and 4!

#==============================================================================
# Plotting the results
#==============================================================================

sampled.clustering69.03percent <- sample_frac(clustering69, 0.001)
ggplot(sampled.clustering69.03percent, aes(x = norm_number_of_dir_change, y = average_speed, color = sampled.clustering69.03percent$cluster_of_3)) + 
  geom_point() + xlab("Number of direction changes") + 
  ylab("Average speed [km/h]") +
  labs(color = "Cluster") +
  ggtitle("0.1% of the data points randomly chosen, 3 clusters")

ggplot(sampled.clustering69.03percent, aes(x = drive_only_ratio, y = average_speed, color = sampled.clustering69.03percent$cluster_of_3)) + 
  geom_point() + xlab("Drive only ratio [%]") + 
  ylab("Average speed [km/h]") +
  labs(color = "Cluster") +
  ggtitle("0.1% of the data points randomly chosen, 3 clusters")

ggplot(sampled.clustering69.03percent, aes(x = lift_only_ratio, y = average_speed, color = sampled.clustering69.03percent$cluster_of_3)) + 
  geom_point() + xlab("Lift only ratio [%]") + 
  ylab("Average speed [km/h]") +
  labs(color = "Cluster") +
  ggtitle("0.1% of the data points randomly chosen, 3 clusters")

ggplot(sampled.clustering69.03percent, aes(x = lift_and_drive_ratio, y = average_speed, color = sampled.clustering69.03percent$cluster_of_3)) + 
  geom_point() + xlab("Lift and drive ratio [%]") + 
  ylab("Average speed [km/h]") +
  labs(color = "Cluster") +
  ggtitle("0.1% of the data points randomly chosen, 3 clusters")

ggplot(sampled.clustering69.03percent, aes(x = norm_number_of_dir_change, y = drive_only_ratio, color = sampled.clustering69.03percent$cluster_of_3)) + 
  geom_point() + xlab("Number of direction changes") + 
  ylab("Drive only ratio [%]") +
  labs(color = "Cluster") +
  ggtitle("0.1% of the data points randomly chosen, 3 clusters")

ggplot(sampled.clustering69.03percent, aes(x = drive_only_ratio, y = lift_only_ratio, color = sampled.clustering69.03percent$cluster_of_3)) + 
  geom_point() + xlab("Drive only ratio [%]") + 
  ylab("Lift only ratio [%]") +
  labs(color = "Cluster") +
  ggtitle("0.1% of the data points randomly chosen, 3 clusters")

sampled.clustering69.50percent <- sample_frac(clustering69, 0.5)

ggplot(sampled.clustering69.50percent, aes(x = norm_number_of_dir_change, y = average_speed, color = sampled.clustering69.50percent$cluster_of_3)) + 
  geom_density2d() + xlab("Number of direction changes") + 
  ylab("Average speed [km/h]") +
  labs(color = "Cluster") +
  ggtitle("50% of the data points randomly chosen, 3 clusters")

ggplot(clustering69, aes(x = norm_number_of_dir_change, color = clustering69$cluster_of_3)) + 
  geom_density() + xlab("Number of direction changes") + 
  labs(color = "Cluster") +
  ggtitle("Density of the 3 clusters")

ggplot(clustering69, aes(x = average_speed, color = clustering69$cluster_of_3)) + 
  geom_density() + xlab("Average speed [km/h]") + 
  labs(color = "Cluster") +
  ggtitle("Density of the 3 clusters")

ggplot(clustering69, aes(x = drive_only_ratio, color = clustering69$cluster_of_3)) + 
  geom_density() + xlab("Drive only ratio [%]") + 
  labs(color = "Cluster") +
  ggtitle("Density of the 3 clusters")

ggplot(clustering69, aes(x = lift_only_ratio, color = clustering69$cluster_of_3)) + 
  geom_density() + xlab("Lift only ratio [%]") + 
  labs(color = "Cluster") +
  ggtitle("Density of the 3 clusters")

ggplot(clustering69, aes(x = lift_and_drive_ratio, color = clustering69$cluster_of_3)) + 
  geom_density() + xlab("Lift and drive ratio [%]") + 
  labs(color = "Cluster") +
  ggtitle("Density of the 3 clusters")

#tsne plot
sampled.clustering69.20k <- sample_n(clustering69, 20000)
set.seed(200)
tsne <- Rtsne(sampled.clustering69.20k[, 1:5], check_duplicates = FALSE)
ggplot(NULL, aes(x = tsne$Y[, 1], y = tsne$Y[, 2], color = sampled.clustering69.20k$cluster_of_3)) +
  geom_point() +
  labs(color = "Cluster") +
  ggtitle("t-DSNE with 20000 samples, 5 variables")

#==============================================================================
# Clustering with consumption rate
#==============================================================================

scaled.clustering.kwh <- data.frame(scale(clustering.kwh))
set.seed(100)
kmeans.clusters.kwh <- kmeans(scaled.clustering.kwh, 50, nstart = 20, iter.max=100)
kmeans.centers.kwh <- as.data.frame(kmeans.clusters.kwh$centers)
scaled.clustering.kwh$cluster_of_50 <- as.factor(kmeans.clusters.kwh$cluster)

agnes.single2 <- agnes(kmeans.centers.kwh, diss = FALSE, metric = "euclidean", stand = FALSE, method = "single", trace.lev = 2)
plot(as.hclust(agnes.single2))

agnes.ward2 <- agnes(kmeans.centers.kwh, diss = FALSE, metric = "euclidean", stand = FALSE, method = "ward", trace.lev = 2)
plot(as.hclust(agnes.ward2))

agnes.weighted2 <- agnes(kmeans.centers.kwh, diss = FALSE, metric = "euclidean", stand = FALSE, method = "weighted", trace.lev = 2)
plot(as.hclust(agnes.weighted2))

distances.kwh <- dist(kmeans.centers.kwh, method = "euclidean")

hclust.ward2 <- hclust(distances.kwh, method = "ward.D2" )
plot(hclust.ward2)

hclust.centroid2 <- hclust(distances.kwh, method = "centroid" )
plot(hclust.centroid2)

kmeans.centers.kwh$agnes_ward3 <- cutree(agnes.ward, 3)
kmeans.centers.kwh$hclust_ward3 <- cutree(hclust.ward, 3)
#all 50 kmeans center got the same cluster group (1-3) from the 2 functions

kmeans_cluster3.kwh <- kmeans.centers.kwh$agnes_ward3
scaled.clustering.kwh <- mutate(scaled.clustering.kwh, cluster_of_3 = as.factor(kmeans_cluster3.kwh[cluster_of_50]))
clustering.kwh$cluster_of_3 <- scaled.clustering.kwh$cluster_of_3

kwh.cluster1_entries <- filter(clustering.kwh, cluster_of_3 == 1) #64.195%
kwh.cluster2_entries <- filter(clustering.kwh, cluster_of_3 == 2) #31.82%
kwh.cluster3_entries <- filter(clustering.kwh, cluster_of_3 == 3) #3.984%

kwh.cluster1_center <- c(mean(kwh.cluster1_entries$average_speed), mean(kwh.cluster1_entries$drive_only_ratio), 
                     mean(kwh.cluster1_entries$lift_only_ratio), mean(kwh.cluster1_entries$lift_and_drive_ratio), 
                     mean(kwh.cluster1_entries$norm_number_of_dir_change), mean(kwh.cluster1_entries$consumption_rate))

kwh.cluster2_center <- c(mean(kwh.cluster2_entries$average_speed), mean(kwh.cluster2_entries$drive_only_ratio), 
                     mean(kwh.cluster2_entries$lift_only_ratio), mean(kwh.cluster2_entries$lift_and_drive_ratio), 
                     mean(kwh.cluster2_entries$norm_number_of_dir_change), mean(kwh.cluster2_entries$consumption_rate))

kwh.cluster3_center <- c(mean(kwh.cluster3_entries$average_speed), mean(kwh.cluster3_entries$drive_only_ratio), 
                     mean(kwh.cluster3_entries$lift_only_ratio), mean(kwh.cluster3_entries$lift_and_drive_ratio), 
                     mean(kwh.cluster3_entries$norm_number_of_dir_change), mean(kwh.cluster3_entries$consumption_rate))

clustering.kwh_centers <- data.frame(rbind(kwh.cluster1_center, kwh.cluster2_center, kwh.cluster3_center))
names(clustering.kwh_centers) = c("average_speed", "drive_only_ratio", "lift_only_ratio", "lift_and_drive_ratio", "norm_number_of_dir_change", "consumption_rate")

#==============================================================================
# Plotting the results
#==============================================================================

sampled.clustering.kwh.02percent <- sample_frac(clustering.kwh, 0.002)
ggplot(sampled.clustering.kwh.02percent, aes(x = norm_number_of_dir_change, y = average_speed, color = sampled.clustering.kwh.02percent$cluster_of_3)) + 
  geom_point() + xlab("Number of direction changes") + 
  ylab("Average speed [km/h]") +
  labs(color = "Cluster") +
  ggtitle("0.2% of the data points randomly chosen, 3 clusters")

ggplot(sampled.clustering.kwh.02percent, aes(x = consumption_rate, y = average_speed, color = sampled.clustering.kwh.02percent$cluster_of_3)) + 
  geom_point() + xlab("Consumption rate [W]") + 
  ylab("Average speed [km/h]") +
  labs(color = "Cluster") +
  ggtitle("0.2% of the data points randomly chosen, 3 clusters")

ggplot(sampled.clustering.kwh.02percent, aes(x = consumption_rate, y = drive_only_ratio, color = sampled.clustering.kwh.02percent$cluster_of_3)) + 
  geom_point() + xlab("Consumption rate [W]") + 
  ylab("Drive only ratio [%]") +
  labs(color = "Cluster") +
  ggtitle("0.2% of the data points randomly chosen, 3 clusters")

ggplot(sampled.clustering.kwh.02percent, aes(x = consumption_rate, y = lift_and_drive_ratio, color = sampled.clustering.kwh.02percent$cluster_of_3)) + 
  geom_point() + xlab("Consumption rate [W]") + 
  ylab("Lift and drive ratio [%]") +
  labs(color = "Cluster") +
  ggtitle("0.2% of the data points randomly chosen, 3 clusters")

ggplot(sampled.clustering.kwh.02percent, aes(x = consumption_rate, y = norm_number_of_dir_change, color = sampled.clustering.kwh.02percent$cluster_of_3)) + 
  geom_point() + xlab("Consumption rate [W]") + 
  ylab("Number of direction changes") +
  labs(color = "Cluster") +
  ggtitle("0.2% of the data points randomly chosen, 3 clusters")

sampled.clustering.kwh.50percent <- sample_frac(clustering.kwh, 0.5)

ggplot(sampled.clustering.kwh.50percent, aes(x = norm_number_of_dir_change, y = average_speed, color = sampled.clustering.kwh.50percent$cluster_of_3)) + 
  geom_density2d() + xlab("Number of direction changes") + 
  ylab("Average speed [km/h]") +
  labs(color = "Cluster") +
  ggtitle("50% of the data points randomly chosen, 3 clusters")

ggplot(sampled.clustering.kwh.50percent, aes(x = consumption_rate, y = average_speed, color = sampled.clustering.kwh.50percent$cluster_of_3)) + 
  geom_density2d() + xlab("Consumption rate [w]") + 
  ylab("Average speed [km/h]") +
  labs(color = "Cluster") +
  ggtitle("50% of the data points randomly chosen, 3 clusters")

ggplot(sampled.clustering.kwh.50percent, aes(x = consumption_rate, y = drive_only_ratio, color = sampled.clustering.kwh.50percent$cluster_of_3)) + 
  geom_density2d() + xlab("Consumption rate [w]") + 
  ylab("Drive only ratio [%]") +
  labs(color = "Cluster") +
  ggtitle("50% of the data points randomly chosen, 3 clusters")

ggplot(clustering.kwh, aes(x = norm_number_of_dir_change, color = clustering.kwh$cluster_of_3)) + 
  geom_density() + xlab("Number of direction changes") + 
  labs(color = "Cluster") +
  ggtitle("Density of the 3 clusters")

ggplot(clustering.kwh, aes(x = average_speed, color = clustering.kwh$cluster_of_3)) + 
  geom_density() + xlab("Average speed [km/h]") + 
  labs(color = "Cluster") +
  ggtitle("Density of the 3 clusters")

ggplot(clustering.kwh, aes(x = drive_only_ratio, color = clustering.kwh$cluster_of_3)) + 
  geom_density() + xlab("Drive only ratio [%]") + 
  labs(color = "Cluster") +
  ggtitle("Density of the 3 clusters")

ggplot(clustering.kwh, aes(x = lift_only_ratio, color = clustering.kwh$cluster_of_3)) + 
  geom_density() + xlab("Lift only ratio [%]") + 
  labs(color = "Cluster") +
  ggtitle("Density of the 3 clusters")

ggplot(clustering.kwh, aes(x = lift_and_drive_ratio, color = clustering.kwh$cluster_of_3)) + 
  geom_density() + xlab("Lift and drive ratio [%]") + 
  labs(color = "Cluster") +
  ggtitle("Density of the 3 clusters")

ggplot(clustering.kwh, aes(x = consumption_rate, color = clustering.kwh$cluster_of_3)) + 
  geom_density() + xlab("Consumption rate [W]") + 
  labs(color = "Cluster") +
  ggtitle("Density of the 3 clusters")

#tsne plot
sampled.clustering.kwh.20k <- sample_n(clustering.kwh, 20000)
set.seed(200)
tsne2 <- Rtsne(sampled.clustering.kwh.20k[, 1:6], check_duplicates = FALSE)
ggplot(NULL, aes(x = tsne2$Y[, 1], y = tsne2$Y[, 2], color = sampled.clustering.kwh.20k$cluster_of_3)) +
  geom_point() +
  labs(color = "Cluster") +
  ggtitle("t-DSNE with 20000 samples, 5 variables")
