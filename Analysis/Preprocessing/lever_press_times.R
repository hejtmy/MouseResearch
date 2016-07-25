#Gets the time since start of lever preses in a table for given phase

lever_press_times = function(event_table){
  experimentPhases = c("Test", "Reward", "InterTrial")
  phasesTimes = data.table(event_table[type %in% experimentPhases,])
  #possibly to order by type and then time
  setorder(phasesTimes, type, start)
  #this works safely because the table is ordered
  phasesTimes[, cycle_index := c(1:.N), by= list(type, name)]
  phasesTimes[, cycle_start := .SD$start[type=="Test"], by=.(name, cycle_index)]
  
  leverTimes = data.table(event_table[type == "Lever",])
  #merges all possibl elevers with all phases for each participatn and then selects only mathing
  newTable = merge(leverTimes, phasesTimes, by = "name", allow.cartesian = T, suffixes = c("_event", "_phase"))
  ls = list()
  ls$pressTable = unique(newTable[start_event > start_phase & start_event < end_phase], by = NULL)
  ls$pressTable = add_columns(ls$pressTable)
  
  ls$releaseTable = unique(newTable[end_event > start_phase & end_event < end_phase], by = NULL)
  ls$releaseTable = add_columns(ls$releaseTable)
  return(ls)
}

add_columns = function(dt){
  dt[, time_since_phase_start := start_event - start_phase[1], by = list(name, type_phase, cycle_index)]
  dt[, time_since_cycle_start := start_event - cycle_start]
  dt[, lever_cycle_id := c(1:.N), by=list(name, cycle_index)]
  dt[, lever_phase_id := c(1:.N), by=list(name, type_phase, cycle_index)]
  return(dt)
}