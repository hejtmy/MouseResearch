require(stringr)
require(plyr)

ReadMouseLog = function(path){
  ls = list()

  #if the file does not exists returning NULL and exiting
  if(!file.exists(path)){
    print("Could not find the file for given log")
    print(path)
    return(NULL)
  }
  
  #reads into a text file at first
  text = readLines(path,warn=F)
  
  #   reading
  #   HEADER
  idxHeaderTop <- which(grepl('HEADER',text))
  idxHeaderBottom <- which(grepl('(\\*){5,}',text))
  headerIndexes = idxHeaderTop : idxHeaderBottom
  #returns the header in a list
  ls[["header"]] <- read_header(text[(idxHeaderTop+1):(idxHeaderBottom-1)])
  
  #   reading
  #   EVENTS
  #gets the event dividers ---
  eventDividerIndexes <- which(grepl('([\\-]{3,})',text[idxHeaderBottom+1:length(text)]))+idxHeaderBottom
  #gets events indexes
  eventIndexes <- which(grepl('^[a-zA-Z]+.*$',text[idxHeaderBottom+1:length(text)]))+idxHeaderBottom
  #reads the text into the events text
  ls[["events"]] <- read_events(text[eventIndexes])
  
  #   reading
  #   TABLE
  #combines all the lines that not to read
  non_table_indexes = c(headerIndexes,eventDividerIndexes,eventIndexes)
  ls[["table"]]  <- read.table(textConnection(text[-non_table_indexes]),header=F,sep="")
  colnames(ls[["table"]])<-c("time","cycle","phase","lever_status","feeder_status")
  
  return(ls)
}

read_header <- function(text =""){
  ls <- list()
  #for each line
  for (info in text) {
    #finds the PROEPRTY NAME
    split <- str_split(info, pattern = ":",n=2)
    #extract the value from the str_split list (this is a weird line but
    #strsplit creates a list of lists so we need to do this
    code <- split[[1]][1]
    #extracting the VALUE from the second part of the list
    value <- str_trim(str_extract_all(split[[1]][2],"[\r\n\t\f ](.*)")[[1]][1])
    #saving into the list 
    ls[[code]] <- value
  }
  return(ls)
}

read_events <-function(text=""){
  #preallocating the table
  frame <- data.frame(event = character(length(text)),time = numeric(length(text)),stringsAsFactors = F)
  i = 1
  #for each line
  for (info in text) {
    #finds the EVENT NAME
    split <- str_split(info, pattern = ";",n=2)
    #extract the value from the str_split list (this is a weird line but
    #strsplit creates a list of lists so we need to do this
    frame$event[i] <- str_trim(split[[1]][1])
    #extracting the VALUE from the second part of the list
    frame$time[i] <- as.numeric(str_trim(split[[1]][2]))
    #saving into the list 
    i=i+1
  }
  return(frame)
}