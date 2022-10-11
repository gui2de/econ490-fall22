// Program is intended for STATA 17.0 Basic Edition

clear

// Set the working directory
global wd "/Users/Neel Desai/Desktop/untitled folder/econ490-fall22/_Group Projects/group1/

// Run the do file that contains the program
do "$wd/one_way_anova.do"

// Demonstration 1
sysuse cancer.dta, clear
one_way_anova cancer.dta age died

// Demonstration 2
sysuse cancer.dta, clear
one_way_anova cancer.dta studytime _d

// Demonstration 3
sysuse cancer.dta, clear
one_way_anova cancer.dta _t drug
