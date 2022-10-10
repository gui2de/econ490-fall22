clear

// Set the working directory
global wd "/Users/Neel Desai/Desktop/untitled folder/econ490-fall22/_Group Projects/group1/

// Run the do file that contains the program
do "$wd/one_way_anova.do"

// Demonstration 1
sysuse airfare.dta, clear
one_way_anova airfare.dta year y98

// Demonstration 2
sysuse sandstone.dta, clear
one_way_anova sandstone.dta depth collection

// Demonstration 3
sysuse cancer.dta, clear
one_way_anova cancer.dta died _st
