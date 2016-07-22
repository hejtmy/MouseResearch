#Loads the scripts in the preprocessing file
#Most importantly - ReadMouseLog
library(ggplot2)
source("Loading.R")

#check if there is a file with the data
load("timeAnalyses.RData")
#if not, read in the data
event_table = fread("analysesTable.csv", sep=";", header=T)
# check if you can read the saved table
ls = lever_press_times(event_table)
pressTable = ls$pressTable
releaseTable = ls$releaseTable
ls = NULL

singleTable = pressTable %>% filter(name == '10_C4TCO.G')
new = singleTable %>% group_by(phaseIndex) %>% summarise(mean=mean(timeSincePhaseStart))
ggplot(new, aes(phaseIndex, mean)) + geom_path()

new = singleTable %>% group_by(phaseIndex)
ggplot(new, aes(order, leverPresses)) + geom_count(stat = "identity")
