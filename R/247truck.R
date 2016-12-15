truck247_logs<-subset(important_replacements,important_replacements$identifier=="516213C00247")
truck247_all_logs<-subset(still,still$identifier=="516213C00247" & !is.na(still$Concatenate.Material..for))

truck247_all_logs<-subset(still,still$identifier=="516213C00247" & !is.na(still$metamachinerrorcode))
table(truck247_all_logs$metamachinerrorcode)
