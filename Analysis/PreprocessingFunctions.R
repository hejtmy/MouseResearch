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
  basic_events <- read_events(text[eventIndexes]);
  
  #   reading
  #   TABLE
  #combines all the lines that not to read
  non_table_indexes = c(headerIndexes,eventDividerIndexes,eventIndexes)

  
  ls[["table"]]  <- read.table(textConnection(text[-non_table_indexes]),header=F,sep="")
  
  colnames(ls[["table"]])<-c("time","cycle","phase","lever_status","feeder_status")
  lever_feeder_events <- read_lever_feeder_events(ls[["table"]])
  
  ls[["events"]] <- rbind(basic_events,lever_feeder_events)
  
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

read_lever_feeder_events <- function (tab){
  #set to weird values because of hte way I actually calculate the time
  same_feeder_count = -1;
  same_lever_count = -1;
  same_lever_counter = 1;
  same_feeder_counter = 1;
  for (i in 2:length(tab$time)){
    if (tab$feeder_status[i]==tab$feeder_status[i-1]){
      same_feeder_counter=same_feeder_counter+1;
    } else {
      same_feeder_counter = 0;
    }
    if (tab$lever_status[i]==tab$lever_status[i-1]){
      same_lever_counter=same_lever_counter+1;
    } else {
      same_lever_counter = 0;
    }
    same_feeder_count[i]=same_feeder_counter;
    same_lever_count[i]=same_lever_counter;
  }
  times_lever_pressed = tab$time[(same_lever_count==0 & tab$lever_status ==1)]
  times_lever_released = tab$time[(same_lever_count==0 & tab$lever_status ==0)]
  times_feeder_runs = tab$time[(same_feeder_count==0 & tab$feeder_status ==1)]
  times_feeder_stops = tab$time[(same_feeder_count==0 & tab$feeder_status ==0)]
  
  event_names = c(rep("lever_pressed",length(times_lever_pressed)),
                  rep("lever_released",length(times_lever_released)),
                  rep("feeder_starts",length(times_feeder_runs)),
                  rep("feeder_stops",length(times_feeder_stops)))
  event_times = c(times_lever_pressed,times_lever_released,times_feeder_runs,times_feeder_stops)
  
  frame <- data.frame(event = character(length(event_names)),time = numeric(length(event_names)),stringsAsFactors = F)
  frame$event = event_names
  frame$time <-event_times
  return(frame)
}