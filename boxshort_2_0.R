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

head(temp_list$Druck.Hubwerk..................................................)

head(diff(temp_list$Druck.Hubwerk..................................................))
tail(diff(temp_list$Druck.Hubwerk..................................................))

x <- 1:10
y <- rnorm(10)
par(mfrow = c(2,1))
plot(x, y, main = "approx(.) and approxfun(.)")
points(approx(x, y, n = 30), col = 2, pch = "*")
#points(approx(x, y, method = "constant"), col = 4, pch = "*")

f <- approxfun(x, y)
curve(f(x), 0, 10, col = "green")
points(x, y)
is.function(fc <- approxfun(x, y, method = "const")) # TRUE
curve(fc(x), 0, 10, col = "darkblue", add = TRUE)

## Show treatment of 'ties' :

x <- c(2,2:4,4,4,5,5,7,7,7)
y <- c(1:6, 5:4, 3:1)
approx(x,y, xout=x)$y # warning
(ay <- approx(x,y, xout=x, ties = "ordered")$y)
stopifnot(ay == c(2,2,3,6,6,6,4,4,1,1,1))
approx(x,y, xout=x, ties = min)$y
approx(x,y, xout=x, ties = max)$y

plot(temp_list$Druck.Hubwerk..................................................[1:30000,1], temp_list$Druck.Hubwerk..................................................[1:30000,2], main = "Vasyteszt")

#######
head(approx(temp_list$Druck.Hubwerk..................................................[,1],
            temp_list$Druck.Hubwerk..................................................[,2], n = 3*length(temp_list$Druck.Hubwerk..................................................[,1])))
######
length(temp_list$Druck.Hubwerk..................................................[,1])
length(temp_list$Druck.Hubwerk..................................................[,2])

mean(diff(temp_list$Druck.Hubwerk..................................................[,1]))
nrow(temp_list$Druck.Hubwerk..................................................)
