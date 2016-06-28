#Gets the time since start of lever preses in a table for given phase
GetLeverPressTimes = function(betterEventTable){
  experimentPhases = c("Test", "Reward", "InterTrial")
  phasesTimes = data.table(betterEventTable[type %in% experimentPhases,])
  phasesTimes[,phaseIndex:=c(1:.N),by= list(type,name)]
  leverTimes = data.table(betterEventTable[type == "Lever",])
  #merges all possibl elevers with all phases for each participatn and then selects only mathing
  newTable = merge(leverTimes,phasesTimes,by="name", allow.cartesian = T)
  ls = list()
  ls$pressTable = unique(newTable[startTime.x > startTime.y & startTime.x < endTime.y], by = NULL)
  ls$pressTable[,timeSincePhaseStart:= startTime.x - startTime.y[1], by=list(name,type.y,phaseIndex)]
  ls$pressTable[,leverPhaseIndex:=c(1:.N), by=list(name, type.y, phaseIndex)]
  
  ls$releaseTable = unique(newTable[endTime.x > startTime.y & endTime.x < endTime.y], by = NULL)
  
  return(ls)
}