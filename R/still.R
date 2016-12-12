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
#still.filtered<-subset(still,!is.na(still$metamachinerrorcode))
still.filtered<-subset(still,!is.na(still$Concatenate.Material..for))

#need to load ggplot2 package
library("ggplot2", lib.loc="C:/Program Files/R/R-3.3.2/library")

#plot distribution of error codes per truck
ggplot(still.filtered,aes(x=still.filtered$identifier, fill=factor(still.filtered$metamachinerrorcode))) + 
geom_bar() +
xlab("Truck ID") +
ylab("Total count")+
labs(fill = "Error Code") 

#see which trucks have log entries
table(still.filtered$identifier)

#separating material lists into multiple rows
#need to install tidyr 0.5.0 or above
install.packages("tidyr")
library(tidyr)
faulty.logs<-separate_rows(still.filtered,Concatenate.Material..for, sep = ",")

#renaming the Concatenate field to 'materials'
names(faulty.logs)[names(faulty.logs)=="Concatenate.Material..for"] <- "materials"

#creating a subframe for only the 3 technical fields
faulty.logs<-faulty.logs[,c("identifier","metatimestamp","technischer.Hinweis","materials")]
names(faulty.logs)[names(faulty.logs)=="technischer.Hinweis"] <- "description"

#filtering out all replacements that were not marked as important
important_replacements<-faulty.logs[which(faulty.logs$materials %in% replacement_parts$Material),]
merged_important<-merge(faulty.logs,filtered_parts,by.x="materials",by.y="Material")
str(merged_important)
table(merged_important$identifier)

specific_log$Hinweis<-truck.log[,"technischer.Hinweis"]

#reading in replacement parts
replacement_parts<-read.csv("Auftraege_Material.csv",header=TRUE,sep=";",na.strings = "")
replacement_parts$X<-NULL

#see what's inside
str(replacement_parts)

#remove uninteresting parts
filtered_parts<-subset(replacement_parts,replacement_parts$Priority!="Ignore")

#reading in error codes Excel sheet
error_codes<-read.csv("error_list.csv",header=TRUE,sep=";",na.strings = "")
filtered_codes<-error_codes[,c("FehlerNr","NAME","BESCHREIBUNG","URSACHE","REAKT.","QUIT","ABHILFE")]

