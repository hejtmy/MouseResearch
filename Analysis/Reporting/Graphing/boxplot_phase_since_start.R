#' Description of the functions

boxplot_phase_since_start = function(table, code = NULL){
  #VALIDATIONS!
  
  if(!("type_phase" %in% names(table))){
    print("You gave me wrong table")
    return(NULL)
  }
  
  if(is.null(code)){
    return(ggplot(table, aes(type_phase, time_since_phase_start)) + geom_boxplot())
  }
  
  ggplot(table[name ==  code], aes(type_phase, time_since_phase_start)) + geom_boxplot()
}
