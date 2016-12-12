mcu_truck<-subset(still.filtered,still.filtered$identifier=="517322D00149" & !is.na(still.filtered$metamachinerrorcode))
table(mcu_truck$metamachinerrorcode)

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