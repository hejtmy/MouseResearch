#Loads the scripts in the preprocessing file
#Most importantly - ReadMouseLog
library(ggplot2)
library(data.table)
source("PreprocessingFunctions.R")
source("TimeClass.R")
source("AnalysisFunctions.R")
path ="U:/Vyzkum/AV/FGU/Mouse/BASIC/MouseResearch/Vystupy/TEST_drl_nth"
path = "../VeronikaVystupy/"

#mouse log takes only path value as a parameter and reads the file into a list
timeAnalysis = TimeAnalysis$new(path2)
files = list.files(path, full.names = T, include.dirs = F)

#check if there is a file with the data

#if not, read in the data
timeAnalyses = list()
for(file in files){
  print(file)
  analysis = TimeAnalysis$new(file)
  timeAnalyses[[analysis$name]] = analysis
}
save(timeAnalyses, file = "timeAnalyses.RData")
# check if you can read the saved table
analysesTable = data.table()
for(analysis in timeAnalyses){
  print(analysis$name)
  analysis$MakeBetterEventTable()
  analysis$betterEventTable$name = rep(analysis$name, nrow(analysis$betterEventTable))
  analysesTable = rbind(analysesTable, analysis$betterEventTable)
}
analysesTable = rbindlist(tablesList)
write.table(analysesTable, "analysesTable.csv", sep=";")

e = timeAnalyses$`1_M2TCOG`$betterEventTable

leverPressNumber = GetLeverPresses(e, "Reward")
leverTimesToReward = GetLeverPressTimes(e, "Test")

new = leverTimesToReward %>% group_by(phaseOrder) %>% summarise(mean=mean(timeFromStart))
ggplot(new, aes(phaseOrder, mean)) + geom_path()
ggplot(leverPressNumber, aes(order, leverPresses)) + geom_count(stat = "identity")