library(data.table)
CreateAnalysesList = function(path){
  files = list.files(path, full.names = T, include.dirs = F)
  timeAnalyses = list()
  for(file in files){
    print(file)
    analysis = TimeAnalysis$new(file)
    timeAnalyses[[analysis$name]] = analysis
  }
  save(timeAnalyses, file = "timeAnalyses.RData")
  return(analyses)
}
CreateAnalysesTable = function(analysisList){
  analysesTable = data.table()
  for(analysis in analysisList){
    print(analysis$name)
    analysis$MakeBetterEventTable()
    analysis$betterEventTable$name = rep(analysis$name, nrow(analysis$betterEventTable))
    analysesTable = rbind(analysesTable, analysis$betterEventTable)
  }
  write.table(analysesTable, "analysesTable.csv", sep=";", row.names = F, quote = F)
  return(analysesTable)
}
#takes list of TimeAnalysis functions and saves table with header information for each patient
CreatePatientHeaderData = function(analysisList){
  ls = list()
  for(analysis in analysisList){
    patientRow = list(name = analysis$name, session = analysis$session, experimentType = analysis$header$`Experiment type`, numberOfCycles = analysis$header$`Number of cycles`, testCycleDuration = analysis$header$`Duration of each test cycle`, rewardType= analysis$header$`Reward type`, rewardNumber= analysis$header$`Reward number`, rewardDuration= analysis$header$`Duration of reward cycle`, interTrialTime = analysis$header$`Inter trial time`)
    ls[[analysis$name]] = patientRow
  }
  headerTable = rbindlist(ls)
  write.table(headerTable, "HeaderTable.csv", sep=";", row.names = F, quote = F)
  return(headerTable)
}