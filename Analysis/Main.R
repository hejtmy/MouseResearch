#Loads the scripts in the preprocessing file
#Most importantly - ReadMouseLog
library(ggplot2)
library(data.table)
source("PreprocessingFunctions.R")
source("TimeClass.R")
source("AnalysisFunctions.R")
path = "../VeronikaVystupy/"

#check if there is a file with the data
load("timeAnalyses.RData")
#if not, read in the data
betterEventTable = fread("analysesTable.csv", sep=";", header=T)
# check if you can read the saved table
ls = GetLeverPressTimes(betterEventTable)
pressTable = ls$pressTable
releaseTable = ls$releaseTable

new = pressTable %>% filter(name == '10_C4TCO.G')
new = leverTimesToReward %>% group_by(phaseOrder) %>% summarise(mean=mean(timeFromStart))
ggplot(new, aes(phaseOrder, mean)) + geom_path()
ggplot(leverPressNumber, aes(order, leverPresses)) + geom_count(stat = "identity")