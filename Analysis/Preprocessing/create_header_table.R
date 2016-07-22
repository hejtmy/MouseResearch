library(data.table)
#takes list of TimeAnalysis functions and saves table with header information for each patient
create_header_table = function(analysisList){
  ls = list()
  for(analysis in analysisList){
    patientRow = list(name = analysis$name, session = analysis$session, experimentType = analysis$header$`Experiment type`, numberOfCycles = analysis$header$`Number of cycles`, testCycleDuration = analysis$header$`Duration of each test cycle`, rewardType= analysis$header$`Reward type`, rewardNumber= analysis$header$`Reward number`, rewardDuration= analysis$header$`Duration of reward cycle`, interTrialTime = analysis$header$`Inter trial time`)
    ls[[analysis$name]] = patientRow
  }
  headerTable = rbindlist(ls)
  write.table(headerTable, "HeaderTable.csv", sep=";", row.names = F, quote = F)
  return(headerTable)
}