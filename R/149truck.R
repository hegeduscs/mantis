##still is the raw csv 

##faulty.logs: still.csv filtered for not empty materials, contains only service logs

##filtered_codes contain the error codes csv with proper fields

##filtered_parts contain only the materials that were marked important or interesting
##replacement_parts contain all materials

##important_replacements contain all rows from faulty.logs where the replaced part was marked as important or interesting

#sublist of still filtered for the ID
truck<-subset(still,still$identifier=="517322D00149")

truck_periodic<-subset(truck, !is.na(truck$distance) | !is.na(truck$maxspeed) | !is.na(truck$numberofdirectionchanges))
truck_errorcloud<-subset(truck, !is.na(truck$metamachinerrorcode))
truck_reports<-subset(truck, !is.na(truck$Concatenate.Material..for) | !is.na(truck$technischer.Hinweis)) 

errorcodeTime<-truck_errorcloud[,c("metamachinerrorcode","metatimestamp")]
#errorcodeTime$EndDate<-errorcodeTime$metatimestamp
names(errorcodeTime)[names(errorcodeTime)=="metatimestamp"] <- "Date"
names(errorcodeTime)[names(errorcodeTime)=="metamachinerrorcode"] <- "Event"


ggplot(errorcodeTime,aes(x=metatimestamp,y=metamachinerrorcode))


table(truck_errorcloud$metamachinerrorcode) 

#filtering this list for specific truck ID-s
#only the parts that were marked important
truck.service.log <-subset(merged_important,merged_important$identifier=="517322D00149")

#fetching all logs for that truck
truck.full.log <-subset(still,still$identifier=="517322D00149")
table(truck.full.log$metamachinerrorcode)

truck.full.log<-subset(truck.full.log,!is.na(truck.full.log$technischer.Hinweis))
truck.full.log<-truck.full.log[,c("identifier","metatimestamp","description","materials")]
truck.full.log<-merge(truck.full.log,replacement_parts,by.x="materials",by.y="Material")

#TODO: join-olni az errorcode táblát ide
#TODO: gantt timeline építése