#boxshort renew
library(readr)
library(R.matlab)
library(dplyr)
library(purrr)
library(plyr)
library(lubridate)
library(zoo)

setwd("/home/vasy/RStudioProjects/still_github/RStudio_wd_Can_fp/")

temp_list = readMat("FastTrack800h_fast.mat")

#boxshort replace, strech and interpolate in one step
strech_and_interpolate <- function(list_to_short,list_to_match) {
  
  approx_list = approx(list_to_short[,1],
                       list_to_short[,2], 
                       n = trunc(median(diff(list_to_short[,1]))*10^2)*length(list_to_short[,1]))
  
  return(
        c(
          rep(as.numeric("NA"),round(approx_list$x[1],digits = 2)/0.01),
          approx_list$y,
          rep(as.numeric("NA"),length(list_to_match)-length(approx_list$y)-round(approx_list$x[1],digits = 2)/0.01)
          )
        )
}

fp_df = data.frame(
  0:(
    round(
      max(
        temp_list$Druck.Hubwerk..................................................[,1]
      )*100
      ,digits = 2
    )
    +100
    )
)
names(fp_df) = "ID_count"
fp_df = mutate(fp_df, time_id = 0 + ID_count * 0.01)

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
  
  fp_df = mutate(fp_df,  temp_col = strech_and_interpolate(temp_list[[w_column]],time_id)) 
  names(fp_df)[names(fp_df) == "temp_col"] <- w_column
}
summary(fp_df)
warnings()

#approx return test

t_prox = approx(temp_list$Druck.Hubwerk..................................................[,1],temp_list$Druck.Hubwerk..................................................[,2],n = 3*length(temp_list$Druck.Hubwerk..................................................[,2]))
# 
# glimpse(t_prox)
# head(t_prox)

round(median(diff(temp_list$SR.DAC.3.Drehzahl.Lenkrad......................................[,1])),digits = 2)/0.01
round(mean(diff(temp_list$SR.DAC.3.Drehzahl.Lenkrad......................................[,1])),digits = 2)/0.01
trunc(median(diff(temp_list$A0.Jahr........................................................[,1]))*10^2)

median(diff(temp_list$A0.Jahr........................................................[,1]))


trunc(0.048*10^2)/10^2

round(median(diff(temp_list$Druck.Hubwerk..................................................[,1])),
      digits = 2)/0.01*length(temp_list$Druck.Hubwerk..................................................[,1])

x = length(fp_df$time_id)-length(t_prox$y)-round(t_prox$x[1],digits = 2)/0.01

rep(as.numeric("NA"),length(fp_df$time_id)-length(t_prox$y)-round(t_prox$x[1],digits = 2)/0.01)

summary(diff(temp_list$A0.Jahr........................................................))

length(fp_df$time_id)
length(t_prox$y)
round(t_prox$x[1],digits = 2)/0.01
