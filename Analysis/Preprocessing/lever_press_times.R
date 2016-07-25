#Gets the time since start of lever preses in a table for given phase

lever_press_times = function(event_table){
  experimentPhases = c("Test", "Reward", "InterTrial")
  phasesTimes = data.table(event_table[type %in% experimentPhases,])
  phasesTimes[, phaseIndex := c(1:.N), by= list(type, name)]
  phasesTimes[, cycleStart := .SD$startTime[type=="Test"], by=.(name, phaseIndex)]
  
  leverTimes = data.table(event_table[type == "Lever",])
  #merges all possibl elevers with all phases for each participatn and then selects only mathing
  newTable = merge(leverTimes, phasesTimes, by = "name", allow.cartesian = T, suffixes = c("_event", "_phase"))
  ls = list()
  ls$pressTable = unique(newTable[startTime_event > startTime_phase & startTime_event < endTime_phase], by = NULL)
  ls$pressTable[, time_since_phase_start := startTime_event - startTime_phase[1], by=list(name, type_phase, phaseIndex)]
  ls$pressTable[, time_since_cycle_start := startTime_event - cycleStart]
  ls$pressTable[, lever_phase_id := c(1:.N), by=list(name, type_phase, phaseIndex)]
  
  ls$releaseTable = unique(newTable[endTime_event > startTime_phase & endTime_event < endTime_phase], by = NULL)
  
  return(ls)
}