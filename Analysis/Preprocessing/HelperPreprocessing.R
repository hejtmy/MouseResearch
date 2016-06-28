CreateAnalysesTable = function(analysisList){
  analysesTable = data.table()
  for(analysis in timeAnalyses){
    print(analysis$name)
    analysis$MakeBetterEventTable()
    analysis$betterEventTable$name = rep(analysis$name, nrow(analysis$betterEventTable))
    analysesTable = rbind(analysesTable, analysis$betterEventTable)
  }
  write.table(analysesTable, "analysesTable.csv", sep=";", row.names = F, quote = F)
}

CreateAnalysesList = function(path){
  files = list.files(path, full.names = T, include.dirs = F)
  timeAnalyses = list()
  for(file in files){
    print(file)
    analysis = TimeAnalysis$new(file)
    timeAnalyses[[analysis$name]] = analysis
  }
  save(timeAnalyses, file = "timeAnalyses.RData")
}