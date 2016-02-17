#Loads the scripts in the preprocessing file
#Most importantly - ReadMouseLog
source("PreprocessingFunctions.R")
path ="U:/Vyzkum/AV/FGU/Mouse/BASIC/MouseResearch/Vystupy/TEST_drl_nth"
#mouse log takes only path value as a parameter and reads the file into a list
ls = ReadMouseLog(path)
#the list has three sections - you don't need to resave them, its just for demonstration purposes here
table = ls[["table"]]
events = ls[["events"]]
header = ls[["header"]]

View(table)
View(events)
View(header)

#if you want to get info from the header, you can do following
ls[["header"]]$"Reward type"
