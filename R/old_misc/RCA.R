# A "merged_important"-ból indulunk ki "materials"-ok alapján,
# a meteralsokat aggregáltan kezeljük (figyelt idõtartam: [elsõcsere-delta, utolsó csere])

#függvénynév és paraméterek - Truck Error Signal Finder (merged_important, )
# Elõször az átvett táblát aggregáljuk a "materials"-ok és az "identifier"-ek alapján, létrehozunk új oszlopot az elsõ és utolsó cserének 
library(stringr)
library(timevis)

#filtering further the "important" parts for RCA purposes
im.parts <- c("Filter", "Hose / Hose parts", "Chain", "Electrical Control Unit", "Electrical component")
important.filtered <- important_replacements[which(str_detect(important_replacements$Type, paste(im.parts, collapse = '|'))),]

all.data <- still[,c("identifier","metatimestamp","metamachinerrorcode")]

plotter <- subset(all.data, !is.na(all.data$metamachinerrorcode) & 
                    (all.data$identifier == important.filtered[4, "identifier"]) & 
                    ((as.Date(all.data$metatimestamp) <= as.Date(important.filtered[4,"metatimestamp"])) &
                       (as.Date(all.data$metatimestamp) >= as.Date(as.Date(important.filtered[4, "metatimestamp"]) - 15))  ))
plotter$style<-"color:blue;"

#add maintenance date - ide jön a truck, a csereidõpontja és az alkatrész
plotter$metatimestamp <- as.character(plotter$metatimestamp)
plotter[nrow(plotter)+1, ] <- c("515063B00279", "2013-07-03 20:00:00", "0174164","color:orange;")
plotter$metatimestamp <- as.factor(plotter$metatimestamp)

plotter["type"] <- "point"

names(plotter)[names(plotter)=="metatimestamp"] <- "start"
names(plotter)[names(plotter)=="metamachinerrorcode"] <- "content"


timevis(plotter, showZoom = FALSE, fit = TRUE, options = list(editable = TRUE, height = "470px"), elementId = "hey")
