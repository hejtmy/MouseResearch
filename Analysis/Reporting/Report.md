---
title: "MouseTimePerception"
author: "Lukáš Hejtmánek"
date: "29 June 2016"
output: html_document
---
Data have been preprocessed by reading in all the BAS files and then extracting lever press lever release times. The only possible error in this could be in the extraction adn detection of unclear or unstable lever presses.

```{r, echo=FALSE}
betterEventTable = fread("analysesTable.csv", sep=";", header=T)
# check if you can read the saved table
ls = GetLeverPressTimes(betterEventTable)
pressTable = ls$pressTable
releaseTable = ls$releaseTable
ls = NULL
hederTable = fread("headerTable.csv", sep=";")
### mergin
releaseTable = merge(headerTable,releaseTable,by="name")
pressTable = merge(headerTable, pressTable, by="name")
```

So, let's have a look at 
