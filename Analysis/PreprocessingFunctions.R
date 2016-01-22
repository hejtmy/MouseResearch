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
  #finds the header start
  idxHeaderTop <- which(grepl('HEADER',text))
  idxHeaderBottom <- which(grepl('(\\*){5,}',text))
  headerIndexes = idxHeaderTop : idxHeaderBottom
  #potentially returns the header as well in a list
  ls[["header"]] <- into_list(text[(idxHeaderTop+1):(idxHeaderBottom-1)])
  #gets the event indexes - in two steps because grepl cannot handle 
  eventIndexes <- which(grepl('([\\-]{3,}|^[a-zA-Z]+.*$)',text[idxHeaderBottom+1:length(text)]))+idxHeaderBottom
  non_table_indexes = c(headerIndexes,eventIndexes)
  #fills in the voids
  ls[["table"]]  <- read.table(textConnection(text[-non_table_indexes]),header=F,sep="")
  colnames(ls[["table"]])<-c("time","cycle","phase","lever_status","feeder_status")
  return(ls)
}

into_list <- function(text =""){
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
    #removing the *
    value <- substring(value,2,nchar(value)-1)
    #saving into the list 
    ls[[code]] <- value
  }
  return(ls)
}