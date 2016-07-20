#Gets the time since start of lever preses in a table for given phase
lever_press_times = function(event_table){
  experimentPhases = c("Test", "Reward", "InterTrial")
  phasesTimes = data.table(event_table[type %in% experimentPhases,])
  phasesTimes[, phaseIndex := c(1:.N), by= list(type, name)]
  phasesTimes[, cycleStart := .SD$startTime[type=="Test"], by=.(name, phaseIndex)]
  
  leverTimes = data.table(event_table[type == "Lever",])
  #merges all possibl elevers with all phases for each participatn and then selects only mathing
  newTable = merge(leverTimes, phasesTimes, by="name", allow.cartesian = T)
  ls = list()
  ls$pressTable = unique(newTable[startTime.x > startTime.y & startTime.x < endTime.y], by = NULL)
  ls$pressTable[, time_since_phase_start := startTime.x - startTime.y[1], by=list(name, type.y, phaseIndex)]
  ls$pressTable[, time_since_cycle_start := startTime.x - cycleStart]
  ls$pressTable[, lever_phase_id := c(1:.N), by=list(name, type.y, phaseIndex)]
  
  ls$releaseTable = unique(newTable[endTime.x > startTime.y & endTime.x < endTime.y], by = NULL)
  
  return(ls)
}