source("Preprocessing/PreprocessingFunctions.R")
source("Classes/TimeAnalysis.R")
source("AnalysisFunctions.R")

#Preprocessing main
path = "../VeronikaVystupy/"

analyses = CreateAnalysesList(path)
analysesTable = CreateAnalysesTable(analyses)
headerTable = CreatePatientHeaderData(analyses)