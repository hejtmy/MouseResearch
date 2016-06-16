#Loads the scripts in the preprocessing file
#Most importantly - ReadMouseLog
source("PreprocessingFunctions.R")
path ="U:/Vyzkum/AV/FGU/Mouse/BASIC/MouseResearch/Vystupy/TEST_drl_nth"
path = "../VeronikaVystupy/11_C1TCO.G"
#mouse log takes only path value as a parameter and reads the file into a list
ls = ReadMouseLog(path)
#the list has three sections - you don't need to resave them, its just for demonstration purposes here

timeAnalysis = TimeAnalysis$new(path)

e = BetterEventTable(timeAnalysis$eventTable)
#if you want to get info from the header, you can do following
timeAnalysis$header$"Reward type"
