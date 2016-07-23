---
title: "MouseTimePerception"
author: "Lukáš Hejtmánek"
date: "29 June 2016"
output: html_document
---
Data have been preprocessed by reading in all the BAS files and then extracting lever press lever release times. The only possible error in this could be in the extraction adn detection of unclear or unstable lever presses.

```{r, echo=FALSE}
#Loads the scripts in the preprocessing file
#Most importantly - ReadMouseLog
source("Loading.R")

#try to read in the data
event_table = fread("Computed/dt_analyses.csv", sep=";", header=T)

# check if you can read the saved table
ls = lever_press_times(event_table)
dt_presses = ls$pressTable
dt_releases = ls$releaseTable
ls = NULL
```

So, let's have a look at it
