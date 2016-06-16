GetLeverPresses = function(betterEventTable, phaseName){
  phasesTable = filter(betterEventTable, type == phaseName)
  leverTable = filter(betterEventTable, type == "Lever")
  phasesNumber = nrow(phasesTable)
  df = data.frame(order = numeric(phasesNumber), leverPresses = numeric(phasesNumber))
  for (i in 1:nrow(phasesTable)){
    numberOfLeverPresses = sum((leverTable$startTime > phasesTable$startTime[i]) & (leverTable$startTime < phasesTable$endTime[i]))
    df[i,] = c(i,numberOfLeverPresses)
  }
  return(df)
}

GetLeverPressTimes = function(betterEventTable, phaseName){
  phasesTable = filter(betterEventTable, type == phaseName)
  leverTable = filter(betterEventTable, type == "Lever")
  times = numeric(0)
  order = numeric(0)
  for (i in 1:nrow(phasesTable)){
    allTimes = leverTable$startTime[(leverTable$startTime > phasesTable$startTime[i]) & (leverTable$startTime < phasesTable$endTime[i])]
    allTimes = allTimes - phasesTable$startTime[i]
    times = c(times, allTimes)
    order = c(order, rep(i,length(allTimes)))
  }
  df = data.frame(phaseOrder = order, timeFromStart = times)
  return(df)
}