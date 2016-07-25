---
title: "MouseTimePerception"
author: "Lukáš Hejtmánek"
date: "29 June 2016"
output: html_document
---
Data have been preprocessed by reading in all the BAS files and then extracting lever press lever release times. The only possible error in this could be in the extraction adn detection of unclear or unstable lever presses.

```{r, echo=FALSE}
source("Loading.R")
event_table = fread("Computed/dt_analyses.csv", sep=";", header=T)

# check if you can read the saved table
ls = lever_press_times(event_table)
dt_presses = ls$pressTable
dt_releases = ls$releaseTable
ls = NULL

dt_header = fread("Computed/header_table.csv", sep=";", header=T)
dt_presses = merge(dt_presses, dt_header, by = "name")
dt_releases = merge(dt_releases, dt_header, by = "name")
```

So, let's have a look at it
