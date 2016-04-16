library(Metrics)
library(forecast)
require(dplyr)
library(tidyr)

library(caret)
# data preprocessing
setwd("E:/GoogleDrive/Academic/Information_Retrieval_and_Data_Mining/Group")
load_history <- read.csv("Load_history.csv")
temperature_history <- read.csv("temperature_history.csv")

# removing the comma in the load data
col2cvt <- 5:28
load_history[,col2cvt] <- lapply(load_history[,col2cvt],function(x){as.numeric(gsub(",", "", x))})

# taking columns h1:h24, and gathering them into (hour, load) pairs
load_history_tidy <- load_history %>%  gather(hour, load, h1:h24)
load_history_tidy$hour <- sapply(load_history_tidy$hour, function(x) as.numeric(strsplit(x,"h")[[1]][2]))

# taking columns h1:h24, and gathering them into (hour, temperature) pairs
temperature_history_tidy <- temperature_history %>%  gather(hour, temp, h1:h24)
temperature_history_tidy$hour <- sapply(temperature_history_tidy$hour, function(x) as.numeric(strsplit(x,"h")[[1]][2]))

# spreading the (staion_id, temperature) pairs into colomns station 1:station 11
temperature_history_tidy <- spread(temperature_history_tidy, key = station_id, value = temp)
colnames(temperature_history_tidy)[5:15] <- sapply(
  colnames(temperature_history_tidy)[5:15],function(x) paste("station",x,sep="_")
)

# merging the load data and temperature data up by the time
whole = left_join(load_history_tidy,temperature_history_tidy,
                  by=c("year","month","day","hour"))

#picking out the pieces with full data
whole <- whole[which(!is.na(whole$load)),]
for (i in 1:17){
  whole[[i]] <- as.numeric(whole[[i]])
}

# categorizing the time attributes
for (i in 1:4){
  whole[[i]] <- as.factor(whole[[i]])
}

# predicting with a simple MLR model to pick out the four most representative zones
for (j in 1:20) {
  zone.j <- whole[which(whole$zone_id==j),]
  zone.j$zone_id<-NULL
  control = trainControl(method="cv", number=5, repeats=1)
  fit.station1 = train(load~., data=zone.j, method = "lm", trControl = control)
  print(paste0("Linear regression for zone: ", j))
  print(fit.station1[4]$results[2])
}
