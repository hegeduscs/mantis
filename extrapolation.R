#extrapolate
library(readr)
library(R.matlab)
library(dplyr)
library(purrr)
library(plyr)
library(lubridate)
library(zoo)

#fill empty spaces with "NA"
extrapolate_column <- function(list_to_ex,list_to_match) {
  
  temp_df = list_to_ex %>%
    as.data.frame() %>%
    mutate(V1 = round(V1)) %>%
    group_by(V1) %>%
    summarise_all(mean,na.rm = TRUE)
  
  return(
    c(
      rep(as.numeric("NA"),temp_df$V1[1]),
      temp_df$V2,
      rep(as.numeric("NA"),length(list_to_match)-length(temp_df$V1)-temp_df$V1[1])
    )
  )
}


setwd("/home/vasy/RStudioProjects/still_github/RStudio_wd_Can_fp/")

temp_list = readMat("FastTrack800h_fast.mat")

fp_df = data.frame(
  0:(
     max(
        temp_list$Druck.Hubwerk..................................................[,1]
      )
    + 10
  )
)
names(fp_df) = "time_ID"

for(w_column in names(temp_list))
{
  #drop not usefull columns
  if(
    w_column == "Crash.Flag....................................................." |
    w_column == "Crash.WD......................................................." | 
    w_column == "Thermo.01.K4..................................................." |
    w_column == "Thermo.01.K3..................................................." |
    w_column == "Thermo.01.K2..................................................." |
    w_column == "Thermo.01.K1..................................................." |
    w_column == "Thermo.01.K8..................................................." |
    w_column == "Thermo.01.K7..................................................." |
    w_column == "Thermo.01.K6..................................................." |
    w_column == "Thermo.01.K5..................................................." 
  )
  {
    print(paste(w_column," is skipped",sep=""))
    next()
  }
  print(w_column)
  
  #fp_df = mutate(fp_df, !!w_column := strech_and_interpolate(temp_list[[w_column]],time_id)) 
  #fp_df = mutate(fp_df,  temp_col = "NA")
  
  
  fp_df = mutate(fp_df,  temp_col = extrapolate_column(temp_list[[w_column]],time_ID))
  
  names(fp_df)[names(fp_df) == "temp_col"] <- w_column
}
summary(fp_df)
warnings()


temp_df = temp_list$Druck.Hubwerk.................................................. %>%
as.data.frame() %>%
mutate(V1 = round(V1)) %>%
group_by(V1) %>%
summarise_all(mean,na.rm = TRUE)


fp_df = left_join(fp_df,temp_df, by = c("time_ID" = "V1"))


glimpse(fp_df)
summary(fp_df)

c(
  rep(as.numeric("NA"),temp_df$V1[1]),
  temp_df$V2,
  rep(as.numeric("NA"),length(fp_df$time_ID)-length(temp_df$V1)-temp_df$V1[1])
)

fp_df = mutate(fp_df,  temp_col = c(
  rep(as.numeric("NA"),temp_df$V1[1]),
  temp_df$V2,
  rep(as.numeric("NA"),length(fp_df$time_ID)-length(temp_df$V1)-temp_df$V1[1])
))

glimpse(fp_df)
summary(fp_df)

glimpse(temp_df)
summary(temp_df)

glimpse(temp_list$Druck.Hubwerk..................................................)
summary(temp_list$Druck.Hubwerk..................................................)

seq(0,9,1)
