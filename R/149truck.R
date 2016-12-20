##still is the raw csv 

##faulty.logs: still.csv filtered for not empty materials, contains only service logs

##filtered_codes contain the error codes csv with proper fields

##filtered_parts contain only the materials that were marked important or interesting
##replacement_parts contain all materials

##important_replacements contain all rows from faulty.logs where the replaced part was marked as important or interesting

#sublist of still filtered for the ID
truck<-subset(still,still$identifier=="517322D00149")

#separating different types of entries
truck_periodic<-subset(truck, !is.na(truck$distance) | !is.na(truck$maxspeed) | !is.na(truck$numberofdirectionchanges))
truck_periodic<-truck_periodic[,c("identifier","metatimestamp","distance","maxspeed","numberofdirectionchanges","drivetime","liftanddrivetime","lifttime","consumedamount")]

truck_errorcloud<-subset(truck, !is.na(truck$metamachinerrorcode))
truck_errorcloud<-truck_errorcloud[,c("identifier","metatimestamp","metamachinerrorcode","coolanttemperaturemaximal","driveconverter1temperature","driveconverter2temperature","drivemotor1temperature",
                                        "driveconverter2temperature","drivemotor1temperature","drivemotor2temperature","fuellevel","hydraulicconverter1temperature",
                                        "hydraulicdrivestate","hydraulicmotor1temperature","maincontactorstate","tractionbatterycharge","tractionbatterycharge","tractiondrivestate")]

truck_reports<-subset(faulty.logs,faulty.logs$identifier=="517322D00149")
truck_reports$metatimestamp<-as.Date(truck_reports$metatimestamp)

#merging errors to description
truck_errorcloud_merged<-merge(truck_errorcloud,filtered_codes,by.x="metamachinerrorcode",by.y="FehlerNr")
truck_errorcloud_merged<-truck_errorcloud_merged[,c("metatimestamp","metamachinerrorcode","BESCHREIBUNG","URSACHE")]

#creating events and periods
timeline<-truck_errorcloud_merged
names(timeline)[names(timeline)=="metatimestamp"] <- "start"
names(timeline)[names(timeline)=="metamachinerrorcode"] <- "content"
timeline$URSACHE<-NULL
timeline$BESCHREIBUNG<-as.character(timeline$BESCHREIBUNG)
timeline$content<-as.character(timeline$content)
timeline$start<-as.Date(timeline$start)
timeline$group<-"error"
timeline$subgroup<-as.character(timeline$content)
timeline$type<-"point"
names(timeline)[names(timeline)=="BESCHREIBUNG"] <- "title"
timeline$style<-as.character("color:blue;")

#removing two too frequent error codes related to DFU communication failure
timeline<-subset(timeline,timeline$content!="A3977" & timeline$content!="A3979")

#adding service log events
unique_reports<-unique(truck_reports[,c("metatimestamp","description")])
unique_reports$metatimestamp<-as.Date(unique_reports$metatimestamp)
for (i in 1:nrow(unique_reports)) {
  newrow<-c(as.character(unique_reports[i,"metatimestamp"]),"Service Log",unique_reports[i,"description"],"log","","point",as.character("color:red;"))
  timeline[nrow(timeline)+1,]<-newrow
}

#creating groups
id<-c(1,2)
content<-c("log","error")
groups<-data.frame(id,content)
  
#loading timeline lib
library(timevis)

timevis(timeline,fit=FALSE)
