setwd("D:/datawranglingstuff/Mantis0520datasets/data_sources")
library(dplyr)
library(quanteda)
library(ggplot2)

#==============================================================================
# Doing text analytics on the service reports
#==============================================================================


#read in the service reports to a dataframe
service.reports <- read.table("SAP-Serviceberichte-sourcedata.txt", header=TRUE, sep="\t", dec=".", 
                              na.strings = c("", " ", "NA"), fill = TRUE, quote = "", encoding = "UTF-8")

#read in the 69 truck IDs into a dataframe so we could filter the service reports with it
truck.ids <- read.table("69_truck_dataset.txt", header=FALSE)

#out of 311039 rows 2536 left (these are the 69 trucks with fleet manager data available)
service.reports <- filter(service.reports, Serialnummer %in% truck.ids$V1)
write.csv2(service.reports, file = "text_analys/service_reports.csv", row.names = FALSE)

#combining the 2 character columns with service comments
service.reports$service_comments <- with(service.reports, ifelse(is.na(technischer.Hinweis), as.character(interne.Bemerkung),
                                ifelse(is.na(interne.Bemerkung), as.character(technischer.Hinweis), 
                                       paste(technischer.Hinweis, interne.Bemerkung, sep = " | "))))

#filter for only the columns with potentially useful information to us
service.reports <- service.reports %>% dplyr::select(Serialnummer, BauJ, BewArt, Name.1, Ort, service_comments, Beginn, Ende)
names(service.reports) <- c("serial_number", "year_of_production", "service_type", "client_name", "city_of_usage", "service_comments", 
                            "start_of_service", "end_of_service")

#fixing data types
service.reports$start_of_service <- as.POSIXct(service.reports$start_of_service, format="%d/%m/%Y")
service.reports$end_of_service <- as.POSIXct(service.reports$end_of_service, format="%d/%m/%Y")
#dropping unused factor levels
service.reports[] <- lapply(service.reports, function(x) if(is.factor(x)) factor(x) else x)
#filter out 41 cases where the service_comments are NA
service.reports <- filter(service.reports, !is.na(service.reports$service_comments))
length(which(!complete.cases(service.reports$start_of_service))) #611 missing date of service

#creating a regular expression which substitutes "[anychar].[anychar]" expressions to "[anychar]. [anychar]"
#this is done because the quanteda tokenizer treated expressions like this as 1 word
service.reports$service_comments <- gsub("(\\w+\\.)(\\w+)", "\\1 \\2", service.reports$service_comments)
#similar expressions needed for :
service.reports$service_comments <- gsub("(\\w+\\:)(\\w+)", "\\1 \\2", service.reports$service_comments)
#similar expression needd for digits too!
service.reports$service_comments <- gsub("(\\D*)(\\d+)(\\D*)", "\\1 \\2 \\3", service.reports$service_comments)

#creating new feature, tracking the service_comments length
service.reports$text_length <- nchar(service.reports$service_comments)
summary(service.reports$text_length)

#plotting service_comment length distribution
ggplot(service.reports, aes(x = text_length, fill = service_type)) + theme_bw() +
  geom_histogram(binwidth = 5) +
  labs(y = "Quantity", x = "Number of Charachters",
       title = "Distribution of text lengths in the service_comments column")

write(service.reports$service_comments, file = "text_analys/service_report_comments.txt")

#creating a quanteda corpus object from the service comments
sr.corpus <- corpus(service.reports$service_comments)
docvars(sr.corpus, "service_type") <- service.reports$service_type
docvars(sr.corpus, "city_of_usage") <- service.reports$city_of_usage

#check out if the service_type variable is indicative of the service_comment or not
type5_services <- filter(service.reports, service_type == 510)
write(type5_services$service_comments, file = "text_analys/type5_services_comments.txt")
type6_services <- filter(service.reports, startsWith(as.character(service_type), "6"))
write(type6_services$service_comments, file = "text_analys/type6_services_comments.txt")
type617_services <- filter(service.reports, service_type == 617)
write(type617_services$service_comments, file = "text_analys/type617_services_comments.txt")
type6_but_not_617_services <- filter(type6_services, service_type != 617)
write(type6_but_not_617_services$service_comments, file = "type6_but_not_617_service_comments.txt")
type7_services <- filter(service.reports, startsWith(as.character(service_type), "7"))
write(type7_services$service_comments, file = "text_analys/type7_services_comments.txt")

#tokenize the technician comments, make them lower case and remove common "stopwords" with no information
sr.tokens <- tokens(service.reports$service_comments, what = "word", 
                       remove_numbers = TRUE, remove_punct = TRUE,
                       remove_symbols = TRUE, remove_hyphens = TRUE, remove_twitter = TRUE)
sr.tokens <- tokens_tolower(sr.tokens)
sr.tokens <- tokens_select(sr.tokens, stopwords(kind = "german"), selection = "remove")
sr.tokens.nostem <- sr.tokens

#stemming is a process of removing affixation from the words, 
#so different versions of the same word are not counted separately 
sr.tokens <- tokens_wordstem(sr.tokens, language = "german")

# Createing the document feature matrix from the tokens
sr.tokens.dfm <- dfm(sr.tokens) #2556 features, 99.7% sparse
sr.tokens.nostem.dfm <- dfm(sr.tokens.nostem) #2960 features, 99.7% sparse
topfeatures(sr.tokens.dfm, 50)
write(featnames(sr.tokens.dfm), file = "text_analys/tokens_in_dfm.txt")
write(featnames(sr.tokens.nostem.dfm), file = "text_analys/tokens_in_dfm_nostem.txt")
word.count <- as.data.frame(topfeatures(sr.tokens.dfm, 5000))
word.count.nostem <- as.data.frame(topfeatures(sr.tokens.nostem.dfm, 5000))
word.count <- tibble::rownames_to_column(word.count)
word.count.nostem <- tibble::rownames_to_column(word.count.nostem)
names(word.count) <- c("word", "count")
names(word.count.nostem) <- c("word", "count")

textplot_wordcloud(sr.tokens.dfm, min.freq = 20, random.order = FALSE, rot.per = .25, 
                   colors = RColorBrewer::brewer.pal(8,"Dark2"))

#creating a dictionary for relevant synonym words
#tire
# tire.names <- word.count.nostem %>% filter(grepl("reif", word))
# tire.names <- rbind(tire.names, filter(word.count.nostem, grepl("reifen", word)))
# tire.names <- rbind(tire.names, filter(word.count, grepl("rad", word)))
# tire.names <- rbind(tire.names, filter(word.count.nostem, grepl("räder", word)))
# tire.names <- rbind(tire.names, filter(word.count.nostem, grepl("bereifung", word)))
# tire.names <- dplyr::distinct(tire.names)
# write.csv2(tire.names, file = "text_analys/tire_synonyms_with_count.csv", row.names = FALSE)
# write(tire.names$word, file = "text_analys/tire_synonyms.txt")
# 
# #back (to identify front or back tire change happened)
# back.synonyms <- word.count.nostem %>% filter(grepl("hinte", word))
# back.synonyms <- rbind(back.synonyms, filter(word.count, grepl("hint", word)))
# back.synonyms <- rbind(back.synonyms, filter(word.count.nostem, grepl("lenk", word)))
# back.synonyms <- rbind(back.synonyms, filter(word.count.nostem, grepl("zurück", word)))
# back.synonyms <- rbind(back.synonyms, filter(word.count, grepl("zuruck", word)))
# back.synonyms <- dplyr::distinct(back.synonyms)
# write(back.synonyms$word, file = "text_analys/back_synonyms.txt")
# 
# front.synonyms <- word.count.nostem %>% filter(grepl("vorn", word)) 
# front.synonyms <- rbind(front.synonyms, filter(word.count.nostem, grepl("drehschemelachse", word)))
# front.synonyms <- rbind(front.synonyms, filter(word.count, grepl("drehschemelachs", word)))
# front.synonyms <- rbind(front.synonyms, filter(word.count.nostem, grepl("antriebsachse", word)))
# front.synonyms <- rbind(front.synonyms, filter(word.count, grepl("antriebsachs", word)))
# front.synonyms <- dplyr::distinct(front.synonyms)
# write(front.synonyms$word, file = "text_analys/front_synonyms.txt")
# 
# replace.synonyms <- word.count.nostem %>% filter(grepl("ausgewechselt", word)) 
# replace.synonyms <- rbind(replace.synonyms, filter(word.count.nostem, grepl("erneuert", word)))
# replace.synonyms <- rbind(replace.synonyms, filter(word.count.nostem, grepl("ersetzt", word)))
# replace.synonyms <- rbind(replace.synonyms, filter(word.count.nostem, grepl("ersetzen", word)))
# replace.synonyms <- rbind(replace.synonyms, filter(word.count.nostem, grepl("austauschen", word)))
# replace.synonyms <- rbind(replace.synonyms, filter(word.count.nostem, grepl("auswechseln", word)))
# replace.synonyms <- rbind(replace.synonyms, filter(word.count.nostem, grepl("erneuern", word)))
# replace.synonyms <- rbind(replace.synonyms, filter(word.count.nostem, grepl("verdrängen", word)))
# replace.synonyms <- rbind(replace.synonyms, filter(word.count.nostem, grepl("vertreten", word)))
# replace.synonyms <- rbind(replace.synonyms, filter(word.count.nostem, grepl("substituieren", word)))
# replace.synonyms <- rbind(replace.synonyms, filter(word.count.nostem, grepl("auflegen", word)))
# replace.synonyms <- dplyr::distinct(replace.synonyms)
# write(replace.synonyms$word, file = "text_analys/replace.synonyms.txt")

tire.synonyms <- read.table("text_analys/tire_synonyms.txt", header = FALSE, stringsAsFactors = FALSE)
front.synonyms <- read.table("text_analys/front_synonyms.txt", header = FALSE, stringsAsFactors = FALSE)
back.synonyms <- read.table("text_analys/back_synonyms.txt", header = FALSE, stringsAsFactors = FALSE)
replace.synonyms <- read.table("text_analys/replace_synonyms.txt", header = FALSE, stringsAsFactors = FALSE)

sr.dict <- dictionary(list(tire = c(tire.synonyms$V1, "pneu"),
                           front = front.synonyms$V1,
                           back = back.synonyms$V1,
                           replace = replace.synonyms$V1))

stopword.list <- stopwords(kind = "german")
removeIndexes <- c(2:6)
stopword.list <- stopword.list[-removeIndexes]

#making a new dfm with synonym dictionaries and groupings
sr.dfm_with_dict <- as.data.frame(dfm(sr.corpus, groups = c("service_type", "city_of_usage"), dictionary = sr.dict, tolower = TRUE,
                                      remove = stopwords(kind = "german"), stem = TRUE))


sr.dfm_with_thesaurus <- dfm(sr.tokens, thesaurus = sr.dict, tolower = TRUE, remove = stopword.list, stem = TRUE)

sr.tokens.df <- as.data.frame(sr.dfm_with_thesaurus)
# making sure there are no duplicate columns
sr.tokens.df <- sr.tokens.df[, !duplicated(colnames(sr.tokens.df))]
# writing the words out to a text file
write(names(sr.tokens.df), file = "text_analys/feature_names_in_df.txt")

#this command is here so I do not have to reload the whole service report dataset with read table when something is changed in the dfm
service.reports <- service.reports[, 1:8]
#binding the dfm to the original comments
service.reports <- cbind(service.reports, sr.tokens.df[, (ncol(sr.tokens.df) - 3):(ncol(sr.tokens.df))])

tire.reports <- filter(service.reports, TIRE > 0) %>% filter(!is.na(start_of_service))
write(tire.reports$service_comments, file = "text_analys/tire_report_comments.txt")
write.csv2(tire.reports[c(36, 105),], file = "text_analys/questionable_cases.csv")
tire.replace.reports <- filter(service.reports, TIRE > 0 & REPLACE > 0) %>% filter(!is.na(start_of_service))
write(tire.replace.reports$service_comments, file = "text_analys/tire_replace_report_comments.txt")

#==============================================================================
# Data cleaning, filtering, feature engineering on the remaining tire reports
#==============================================================================

#starting with some date comparing
fleetmanager.df <- read.table("UCCdataOfApprovedTireChangedFullServiceVehicles_v2.txt", header=TRUE, sep="\t", dec=".", na.strings = c("", " ", "NA"))
names(fleetmanager.df)[names(fleetmanager.df) == 'ï.¿identifier'] <- 'identifier'
fleetmanager.df$timestamp <- as.POSIXct(fleetmanager.df$timestamp, format="%d/%m/%Y %H:%M:%S")
fleetmanager.df$readoutduration <- as.numeric(fleetmanager.df$readoutduration)
#remove a row with bad timestamp (1970-01-01)
fleetmanager.df <- fleetmanager.df[-1984075, ]

#making a new dataframe where the first and last dates are shown in the fleetmanager and historical data, grouped by truck id
truck.dates <- data.frame(levels(service.reports$serial_number), fleetmanager_first_date = 1:69, fleetmanager_last_date = 1:69, sr_first_date = 1:69, sr_last_date = 1:69)
names(truck.dates)[1] <- 'identifier'
truck.dates$fleetmanager_first_date <- as.POSIXct(truck.dates$fleetmanager_first_date, format = "%Y-%m-%d", origin = "2013-02-12")
truck.dates$fleetmanager_last_date <- as.POSIXct(truck.dates$fleetmanager_last_date, format = "%Y-%m-%d", origin = "2013-02-12")
truck.dates$sr_first_date <- as.POSIXct(truck.dates$sr_first_date, format = "%Y-%m-%d", origin = "2013-02-12")
truck.dates$sr_last_date <- as.POSIXct(truck.dates$sr_last_date, format = "%Y-%m-%d", origin = "2013-02-12")

for(j in 1:nrow(truck.dates)){
  truck.fm <- fleetmanager.df %>% filter(identifier == truck.dates$identifier[j])
  sr.rows <- tire.reports %>% filter(serial_number == truck.dates$identifier[j])
  
  truck.dates$fleetmanager_first_date[j] = min(truck.fm$timestamp)
  truck.dates$fleetmanager_last_date[j] = max(truck.fm$timestamp)
  if(nrow(sr.rows) == 0){
    truck.dates$sr_first_date[j] = NA
    truck.dates$sr_last_date[j] = NA
  }
  else{
    truck.dates$sr_first_date[j] = min(sr.rows$start_of_service)
    truck.dates$sr_last_date[j] = max(sr.rows$end_of_service)
  }
}
truck.dates <- truck.dates %>% filter(complete.cases(sr_first_date)) %>% mutate(service_report_covered = 
                               ifelse(fleetmanager_first_date <= sr_first_date & fleetmanager_last_date >= sr_last_date, 1, 0))
sum(truck.dates$service_report_covered) #10, 16 if only the first date is considered


tire.reports$fleetmanager_first_date <- as.POSIXct(1:nrow(tire.reports), format = "%Y-%m-%d %H:%M:%S", origin = "2013-02-12")
tire.reports$fleetmanager_last_date <- as.POSIXct(1:nrow(tire.reports), format = "%Y-%m-%d %H:%M:%S", origin = "2013-02-12")
for(i in 1:nrow(tire.reports)){
  truck.date <- truck.dates %>% filter(identifier == tire.reports$serial_number[i])
  tire.reports$fleetmanager_first_date[i] = truck.date$fleetmanager_first_date
  tire.reports$fleetmanager_last_date[i] = truck.date$fleetmanager_last_date
}
tire.reports <- tire.reports %>% mutate(service_report_covered = ifelse(fleetmanager_first_date <= end_of_service, 1, 0))
sum(tire.reports$service_report_covered) #only 55 services have fleetmanager data prior to the servicing :(

# tire.reports$start_of_service <- as.Date(tire.reports$start_of_service)
# ggplot(tire.reports, aes(x = start_of_service)) +
#   facet_wrap(~serial_number) +
#   geom_histogram(binwidth = 30)
# tire.reports$start_of_service <- as.POSIXct(tire.reports$start_of_service)

#these remove all the rows where services were too close to each other (ordering tire for example and then replacing it few days later),
#rows where the tire was not actually changed, and rows where the tire change was because of defect or external damage
removeIndexes <- c(3, 6, 11, 18, 21, 25, 27, 32, 37, 41, 42, 45, 50, 58, 64, 65, 91, 93, 113, 114, 115, 116, 128, 133, 141, 142, 145, 152, 153, 155)
filtered.tire.reports <- tire.reports[-removeIndexes, ]
filtered.tire.reports <- as.data.frame(filtered.tire.reports, row.names = 1:nrow(filtered.tire.reports))
#row 11 and 18 were only removed because the tire service was split into 2 service reports (front and back), now updating the remaining service report accordingly
filtered.tire.reports$service_comments[8] <- "Räder alle ausgewechselt."
filtered.tire.reports$BACK[8] <- 1
filtered.tire.reports$service_comments[14] <- "Räder alle ausgewechselt."
filtered.tire.reports$BACK[14] <- 1

sum(filtered.tire.reports$service_report_covered) #44 :(

#these are all the rows where services were too close to each other (ordering tire for example and then replacing it few days later), or the tire was not changed
removeIndexes <- c(3, 6, 11, 18, 21, 24, 25, 27, 32, 37, 41, 42, 50, 58, 64, 65, 91, 93, 113, 114, 115, 128, 155)
tire.reports <- tire.reports[-removeIndexes, ]
tire.reports <- as.data.frame(tire.reports, row.names = 1:nrow(tire.reports))

filtered.tire.reports$tire_usage_start_date <- as.POSIXct(1:nrow(filtered.tire.reports), origin = "1970-01-01")
for(i in 1:nrow(filtered.tire.reports)){
  truck.sr.list <- tire.reports %>% filter(serial_number == filtered.tire.reports$serial_number[i]) %>% 
    filter(start_of_service < filtered.tire.reports$start_of_service[i]) %>% arrange(start_of_service)
  
   filtered.tire.reports$tire_usage_start_date[i] <- as.POSIXct(ifelse(nrow(truck.sr.list) > 0, truck.sr.list$end_of_service[nrow(truck.sr.list)], NA), origin = "1970-01-01")
   
   if(is.na(filtered.tire.reports$tire_usage_start_date[i]) & filtered.tire.reports$start_of_service[i] >= filtered.tire.reports$fleetmanager_first_date[i]){
     filtered.tire.reports$tire_usage_start_date[i] <- filtered.tire.reports$fleetmanager_first_date[i]
     filtered.tire.reports$imputed_usage_start[i] <- TRUE
   }
   else{
     filtered.tire.reports$imputed_usage_start[i] <- FALSE
   }
}
filtered.tire.reports <- filtered.tire.reports %>% mutate(days_passed = as.numeric(end_of_service - tire_usage_start_date))
summary(filtered.tire.reports$days_passed)
table(filtered.tire.reports$imputed_usage_start)

for(i in 1:nrow(filtered.tire.reports)){
  truck.fm <- fleetmanager.df %>% filter(identifier == filtered.tire.reports$serial_number[i])
  truck.fm.interval <- truck.fm %>% filter(timestamp >= filtered.tire.reports$tire_usage_start_date[i] & timestamp <= filtered.tire.reports$end_of_service[i])
  filtered.tire.reports$service_report_with_1000_fm_entry[i] <- ifelse(nrow(truck.fm.interval) > 1000, 1, 0)
}
sum(filtered.tire.reports$service_report_with_1000_fm_entry) #39, but 15 with usage_start_date imputed :(
sr.covered.test <- filtered.tire.reports %>% filter(service_report_covered == 1 & service_report_with_1000_fm_entry == 0) #1 interesting case here to check out
#truck id: 516211D00198 has 0 fleetmanager entry between 2014-09-01 and 2016-01-13 for some reason (but 4k in the 7 montsh before that, and 10k in the 7 months after)

sr.imputed <- filtered.tire.reports %>% filter(imputed_usage_start == TRUE) #days passed column is within reasonable limits

sr.not.covered <- filter(filtered.tire.reports, service_report_covered == 0 | service_report_with_1000_fm_entry == 0)
sr.not.covered$start_of_service <- format(sr.not.covered$start_of_service, format="%Y")
table(sr.not.covered$start_of_service) #2013 - 23, 2014 - 46, 2015 - 12, 2016 - 8

#making a dataframe for Ansgar
ansgar.df <- service.reports %>% select(serial_number, client_name, city_of_usage) %>% distinct()
write.csv2(ansgar.df, file = "text_analys/truck_client_city.csv", row.names = FALSE)
write.csv2(filtered.tire.reports, file = "text_analys/Tire_RUL_service_reports.csv", row.names = FALSE)