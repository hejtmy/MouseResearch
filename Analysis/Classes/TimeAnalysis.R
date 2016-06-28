library('R6')
TimeAnalysis = R6Class("TimeAnalysis",
   public = list(
     logTable = NA,
     eventTable = NA,
     header = NA,
     initialize = function(path){
       if(!missing(path)){
         ls = ReadMouseLog(path)
         if(!is.null(ls)){
           self$logTable = ls[["table"]]
           self$eventTable = ls[["events"]]
           self$header = ls[["header"]]
         }
       }
     }
   )
)