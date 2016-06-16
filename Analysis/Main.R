#Loads the scripts in the preprocessing file
#Most importantly - ReadMouseLog
library(ggplot2)
source("PreprocessingFunctions.R")
source("TimeClass.R")
source("AnalysisFunctions.R")
path ="U:/Vyzkum/AV/FGU/Mouse/BASIC/MouseResearch/Vystupy/TEST_drl_nth"
path = "../VeronikaVystupy/10_C4TCO.G"
#mouse log takes only path value as a parameter and reads the file into a list
ls = ReadMouseLog(path)
#the list has three sections - you don't need to resave them, its just for demonstration purposes here

timeAnalysis = TimeAnalysis$new(path)

e = BetterEventTable(timeAnalysis$eventTable)

#
leverPressNumber = GetLeverPresses(e, "Reward")
leverTimesToReward = GetLeverPressTimes(e, "Test")
new =leverTimesToReward %>% group_by(phaseOrder) %>% summarise(mean=mean(timeFromStart))
ggplot(new, aes(phaseOrder, mean)) + geom_path()
ggplot(leverPressNumber, aes(order, leverPresses)) + geom_count(stat = "identity")
#if you want to get info from the header, you can do following
timeAnalysis$header$"Reward type"
