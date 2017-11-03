#boxshort renew
library(readr)
library(R.matlab)
library(dplyr)
library(purrr)
library(plyr)
library(lubridate)
library(zoo)

setwd("/home/vasy/RStudioProjects/still_github/RStudio_wd_Can_fp/")

temp_list = readMat("Ramp_wl_slow.mat")

#boxshort replace, strech and interpolate in one step
strech_and_interpolate <- function(list_to_short,list_to_match) {
  
  approx_list = approx(list_to_short[,1],
                       list_to_short[,2], 
                       n = round(max(diff(list_to_short[,1])),
                                 digits = 2)/0.01*length(list_to_short[,1]))
  
  return(c(rep(as.numeric("NA"),approx_list[1,1]/0.01),approx_list,rep(as.numeric("NA"),length(list_to_match)-length(approx_list[,2])-approx_list[1,1]/0.01)))
}

fp_df = data.frame(
  0:(
    round(
      max(
        temp_list$Druck.Hubwerk..................................................[,1]
      )*100
      ,digits = 2
    )
    +1000)
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
  fp_df = mutate(fp_df,  temp_col = strech_and_interpolate(temp_list[[w_column]],time_id)) 
  names(fp_df)[names(fp_df) == "temp_col"] <- w_column
}
warnings()

#dynamic variables in mutate


fp_df = mutate(fp_df,  temp_col = "NA")

# library(dplyr)
# multipetalN <- function(df, n){
#   varname <- paste0("petal.", n)
#   df %>%
#     mutate(!!varname := Petal.Width * n)
# }
# 
# data(iris)
# iris1 <- tbl_df(iris)
# iris2 <- tbl_df(iris)
# for(i in 2:5) {
#   iris2 <- multipetalN(df=iris2, n=i)
# }   

df_test = data.frame()
df_test = names(temp_list)
names(df_test)
names(temp_list)

head(temp_list$Druck.Hubwerk..................................................)

round(max(diff(temp_list$Druck.Hubwerk..................................................[,1])),digits = 2)
tail(diff(temp_list$Druck.Hubwerk..................................................))

# x <- 1:10
# y <- rnorm(10)
# par(mfrow = c(2,1))
# plot(x, y, main = "approx(.) and approxfun(.)")
# points(approx(x, y, n = 30), col = 2, pch = "*")
# #points(approx(x, y, method = "constant"), col = 4, pch = "*")
# 
# f <- approxfun(x, y)
# curve(f(x), 0, 10, col = "green")
# points(x, y)
# is.function(fc <- approxfun(x, y, method = "const")) # TRUE
# curve(fc(x), 0, 10, col = "darkblue", add = TRUE)
# 
# ## Show treatment of 'ties' :
# 
# x <- c(2,2:4,4,4,5,5,7,7,7)
# y <- c(1:6, 5:4, 3:1)
# approx(x,y, xout=x)$y # warning
# (ay <- approx(x,y, xout=x, ties = "ordered")$y)
# stopifnot(ay == c(2,2,3,6,6,6,4,4,1,1,1))
# approx(x,y, xout=x, ties = min)$y
# approx(x,y, xout=x, ties = max)$y

# plot(temp_list$Druck.Hubwerk..................................................[1:30000,1], temp_list$Druck.Hubwerk..................................................[1:30000,2], main = "Vasyteszt")

#######
head(approx(temp_list$Druck.Hubwerk..................................................[,1],
            temp_list$Druck.Hubwerk..................................................[,2], n = 3*length(temp_list$Druck.Hubwerk..................................................[,1])))
######
length(temp_list$Druck.Hubwerk..................................................[,1])
length(temp_list$Druck.Hubwerk..................................................[,2])

mean(diff(temp_list$Druck.Hubwerk..................................................[,1]))
nrow(temp_list$Druck.Hubwerk..................................................)
