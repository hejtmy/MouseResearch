library('R6')
library('stringr')
TimeAnalysis = R6Class("TimeAnalysis",
   public = list(
     name = NA,
     session = NA,
     logTable = NA,
     eventTable = NA,
     header = NA,
     betterEventTable = NA,
     initialize = function(path){
       if(!missing(path)){
         self$name = gsub("(.*[/])","", path)
         ls = ReadMouseLog(path)
         if(!is.null(ls)){
           self$logTable = ls[["table"]]
           self$eventTable = ls[["events"]]
           self$header = ls[["header"]]
         }
         self$FillInData()
       }
     },
     MakeBetterEventTable = function(){
       self$betterEventTable = BetterEventTable(self$eventTable)
     },
     FillInData = function(){
        self$session = as.numeric(str_extract(self$name, "\\d+"))
     }
   )
)