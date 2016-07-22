library(dplyr)
source_folder = function(path){
  sapply(list.files(pattern="[.]R$", path=path, full.names=TRUE), source);
}

FindStartEnd = function(eventTable, name, startEndNames = c()){
  starts = filter(eventTable, event == startEndNames[1])
  ends = filter(eventTable, event == startEndNames[2])
  if (nrow(starts) != nrow(ends)){
    return(NULL)
  }
  df = data.frame(type = rep(name, nrow(starts)), startTime = as.numeric(starts$time), endTime = as.numeric(ends$time))
  return(df)
}

FindStartEndLever = function(eventTable, name, startEndNames = c()){
  starts = filter(eventTable, event == startEndNames[1])
  ends = filter(eventTable, event == startEndNames[2])
  newStarts = c()
  newEnds = c()
  if (nrow(starts) != nrow(ends)){
    for(i in 1:nrow(ends)){
      #calculates down from each release
      endTime = ends$time[i]
      potentialStartTimeIdx = tail(which(starts$time < endTime),1)
      if (length(potentialStartTimeIdx) == 0) next
      potentialStartTime = starts$time[potentialStartTimeIdx]
      #diff = endTime-potentialStartTime
      if (length(which(newStarts == potentialStartTime)) > 0) next
      newStarts  =c(newStarts,potentialStartTime)
      newEnds = c(newEnds, endTime)
    }
  }
  df = data.frame(type = rep(name, length(newStarts)), startTime = as.numeric(newStarts), endTime = as.numeric(newEnds))
  return(df)
}