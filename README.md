# Mouse Time analysis
I know its not about mice, but whatever

There are two main parts to this. The Experiment folder keeps the BAS experiment and the Analysis part is R script for preprocessing and analysisng the data.

# Analysis 

The analysis part has two parts. Preprocessing and analysis on its own.

If you want to play with it, you should focus on the Preprocessing.R and the Main.R. For later reporting, files in the Reporting folder will be made using RMarkdown

## Preprocessing
Preprocessing main shoudl take care of everything. Just modify the path and run it. If it doesn't work, submit a bug into the issues please. 

Assingment of analyses in the `r create_analyses_list` needs to be make. It creates a list to TimeAnalysis R6 class

The assignmend of tables during function calls of `r create_analyses_table,  create_header_table` is optional. These functions shoudl save all computed things in the Computed folder in the project to be loaded later from report files.

## Analysis
There is a tight line between what is preprocessing and what is analysis. This project consideres loading of headers and all events as preprocessing and creating more specified tables as analysis. Therefore e.g. function `r lever_press_times` is actually in the analytical part of the file, but the function is still in the preprocessing function folder - because I just made it so.

The Main.R is focused more as an example of what can be done. THe real reports shoudl follow the dogma of data science and be make in reproduceble manner in IPython notebooks or RMarkdown and published in Reporting folder.

# Prerequisites
The project was built on R 3.2.3 and using the following packages:
data.table => 
dplyr =>
stringr => 
ggplot =>

Any future package updates sould be fine. If something breakes, submit a bug.