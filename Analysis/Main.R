#Loads the scripts in the preprocessing file
#Most importantly - ReadMouseLog
library(ggplot2)
library(data.table)
source("AnalysisFunctions.R")

#check if there is a file with the data
load("timeAnalyses.RData")
#if not, read in the data
betterEventTable = fread("analysesTable.csv", sep=";", header=T)
# check if you can read the saved table
ls = GetLeverPressTimes(betterEventTable)
pressTable = ls$pressTable
releaseTable = ls$releaseTable
ls = NULL

singleTable = pressTable %>% filter(name == '10_C4TCO.G')
new = singleTable %>% group_by(phaseIndex) %>% summarise(mean=mean(timeSincePhaseStart))
ggplot(new, aes(phaseIndex, mean)) + geom_path()
new = singleTable %>% group_by(phaseIndex) %>% summarise(max=max())
ggplot(new, aes(order, leverPresses)) + geom_count(stat = "identity")