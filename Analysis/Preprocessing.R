#' You should just run this. It creates appropriate files in 
#' the computed folder and then you can just continue with main

source('Loading.R')

path = "../Data - Copy/"

analyses = create_analyses_list(path)
analysesTable = create_analyses_table(analyses)
headerTable = create_header_table(analyses)
