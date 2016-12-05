#setting workspace path
setwd("D:/MANTIS projects")

#read csv, but metamachinerrorcode is not empty
still<-read.csv("mergedSTILL.csv",header=TRUE,na.string=c("  ","","NA"))

#listing how R recognized 
str(still)

#need to correct fields, remove unused
still$distance<-as.numeric(still$distance)
still$maxspeed<-as.numeric(still$maxspeed)
still$numberofdirectionchanges<-as.numeric(still$numberofdirectionchanges)
still$readoutduration<-as.numeric(still$readoutduration)
still$consumedamount<-as.numeric(still$consumedamount)
still$timestamp<-as.Date(still$timestamp)
still$technischer.Hinweis<-as.character(still$technischer.Hinweis)
still$erroroccurredtimestamp<-as.Date(still$erroroccurredtimestamp)
still$Filtered.to.at.19.01.12<-NULL
still$BauJ<-NULL
still$automaticlogout<-NULL
still$Ende<-NULL

#list the possible error codes
table(still$metamachinerrorcode)

#creating subset: removing empty errorcode 
still.filtered<-subset(still,!is.na(still$metamachinerrorcode))

#need to load ggplot2 package
library("ggplot2", lib.loc="C:/Program Files/R/R-3.3.2/library")

#plot distribution of error codes per truck
ggplot(still.filtered,aes(x=still.filtered$identifier, fill=factor(still.filtered$metamachinerrorcode))) + 
geom_bar() +
xlab("Truck ID") +
ylab("Total count")+
labs(fill = "Error Code") 

#filtering for truck 516325C00662
#indoor-outdoor truck in Düren
faulty.truck<-subset(still,still$identifier=="516325C00662")
faulty.truck.errors<-subset(faulty.truck,!is.na(faulty.truck$metamachinerrorcode))

#this one has real problems: A 31 80 error code is overwhelming
#A 31 80 -- The fingertip reports an error in the operating levers
filtered.errors<-subset(faulty.truck.errors,faulty.truck.errors$metamachinerrorcode!="A 31 80")
table(filtered.errors$metamachinerrorcode)
barplot(table(filtered.errors$metamachinerrorcode))
#second most frequent error code
# A 38 32: Too few arguments to process a parameterisable additional electrical installation function


#creating table for log records
faulty.logs<-subset(still,!is.na(still$technischer.Hinweis))
table(faulty.logs$identifier)

faulty.logs2<-subset(still,!is.na(still$Concatenate.Material..for))