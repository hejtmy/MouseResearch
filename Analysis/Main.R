#Loads the scripts in the preprocessing file
#Most importantly - ReadMouseLog
source("Loading.R")

#try to read in the data
event_table = fread("Computed/dt_analyses.csv", sep=";", header=T)

# check if you can read the saved table
ls = lever_press_times(event_table)
pressTable = ls$pressTable
releaseTable = ls$releaseTable
ls = NULL

singleTable = pressTable %>% filter(name == '10_C4TCO.G')
new = singleTable %>% group_by(phaseIndex) %>% summarise(mean = mean(time_since_phase_start))
ggplot(new, aes(phaseIndex, mean)) + geom_path()
