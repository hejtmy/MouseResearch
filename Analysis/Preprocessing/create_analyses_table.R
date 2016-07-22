create_analyses_table = function(analysisList){
  dt_analyses = data.table()
  for(analysis in analysisList){
    print(analysis$name)
    analysis$MakeBetterEventTable()
    analysis$betterEventTable$name = rep(analysis$name, nrow(analysis$betterEventTable))
    dt_analyses = rbind(dt_analyses, analysis$betterEventTable)
  }
  if (!dir.exists('Computed')) dir.create('Computed')
  write.table(dt_analyses, "Computed/dt_analyses.csv", sep=";", row.names = F, quote = F)
  return(dt_analyses)
}