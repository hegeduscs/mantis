library(dplyr)
library(clustertend)

data(iris)
iris.df <- data.frame(scale(iris[,-5]))

set.seed(100)
hopkins(iris.df, n = nrow(iris.df) - 1) #0.1911713

random1 <- sample(0:100, 150, replace = TRUE)
random2 <- sample(0:100, 150, replace = TRUE)
random3 <- sample(0:100, 150, replace = TRUE)
random4 <- sample(0:100, 150, replace = TRUE)
random.df <- data.frame(cbind(random1, random2, random3, random4))
random.df <- data.frame(scale(random.df))

set.seed(100)
hopkins(random.df, n = nrow(random.df) - 1) #0.5077857 (0.5070865 unscaled)

uni1 <- runif(150, 0, 100)
uni2 <- runif(150, 0, 100)
uni3 <- runif(150, 0, 100)
uni4 <- runif(150, 0, 100)
uni.df <- data.frame(cbind(uni1, uni2, uni3, uni4))
uni.df <- data.frame(scale(uni.df))

set.seed(100)
hopkins(uni.df, n = nrow(uni.df) - 1) #0.4867306 (0.4886513 unscaled)
