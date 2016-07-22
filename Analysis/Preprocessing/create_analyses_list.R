create_analyses_list = function(path){
  files = list.files(path, full.names = T, include.dirs = F)
  timeAnalyses = list()
  for(file in files){
    print(file)
    analysis = TimeAnalysis$new(file)
    timeAnalyses[[analysis$name]] = analysis
  }
  if (!dir.exists('Computed')) dir.create('Computed')
  save(timeAnalyses, file = "Computed/timeAnalyses.RData")
  return(timeAnalyses)
}