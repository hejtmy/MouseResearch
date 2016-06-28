lists= list()
for (analysis in timeAnalyses){
  ls =list()
  ls$session = as.numeric(str_extract(analysis$name, "\\d+"))
  ls$id = gsub(".*_|TCO.*", "", analysis$name)
  ls$experimentType = analysis$header$`Experiment type`
  ls$numberOfCycles = analysis$header$`Number of cycles`
  ls$testDuration = analysis$header$`Duration of each test cycle`
  ls$rewardType = analysis$header$`Reward type`
  ls$rewardNumber = analysis$header$`Reward number`
  ls$rewardDuration = analysis$header$`Duration of reward cycle`
  ls$interTrialTime = analysis$header$`Inter trial time`
  lists[[analysis$name]] = ls
}
dt = rbindlist(lists)
write.table(dt, "HeaderTable.csv")