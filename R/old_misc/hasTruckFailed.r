
#Kiválasztom a megfelelő oszlopokat a nagy táblázatból
merged.logs <- still[,c("identifier","metatimestamp", "metamachinerrorcode", "Concatenate.Material..for")]

#Az előző táblából kiválasztom azokat a timestampeket ahol alkatrész meg van jelölve (tehát service log), és az azt megelőző timestamp-et egy külön táblába rendezem
codes.detected <- merged.logs[which(!is.na(merged.logs$Concatenate.Material..for))-1,c("metamachinerrorcode", "metatimestamp", "identifier"),]

#Kitörölöm azokat a bejegyzéseket, ahol nincs error log
codes.detected <- na.omit(codes.detected)

#Kiválasztom azokat a service logokat, amelyek előtt volt hibaüzenet
error.detected <- merged.logs[which(merged.logs$metatimestamp == codes.detected$metatimestamp)+1,]

#Itt kézzel megnéztem hogy a kettő közül szerepel-e valamelyik material az important_replacements-ben, és utána a múltkori kódot lefutattam ara a cserére ami important volt

library(stringr)
library(timevis)

im.parts <- c("Filter", "Hose / Hose parts", "Chain", "Electrical Control Unit", "Electrical component")

important.filter <- important_replacements[which(str_detect(important_replacements$Type, paste(im.parts, collapse = '|'))),]

all.data <- still[,c("identifier","metatimestamp","metamachinerrorcode")]

#Megnéztem kézzel hogy hanyadik sorban van az a bejegyzés ami nekem kell

plotter <- subset(all.data, !is.na(all.data$metamachinerrorcode) & 
                    (all.data$identifier == important.filter[18, "identifier"]) & 
                    ((as.Date(all.data$metatimestamp) <= as.Date(important.filter[18,"metatimestamp"])) &
                       (as.Date(all.data$metatimestamp) >= as.Date(as.Date(important.filter[18, "metatimestamp"]) - 15))  ))

#add maintenance date - ide jön a truck, a csereidőpontja és az alkatrész hogy a timeline-ban szerepeljen
plotter$metatimestamp <- as.character(plotter$metatimestamp)
plotter[nrow(plotter)+1, ] <- c("517322D00149", "2014-09-12 13:00:00", "0737871")
plotter$metatimestamp <- as.factor(plotter$metatimestamp)

plotter["type"] <- "point"

names(plotter)[names(plotter)=="metatimestamp"] <- "start"
names(plotter)[names(plotter)=="metamachinerrorcode"] <- "content"


timevis(plotter, showZoom = FALSE, fit = FALSE, options = list(editable = TRUE, height = "470px"), elementId = "hey")
