// Set global dir

global wd "/Users/miglepetrauskaite/Desktop/GITHUB/Repo/econ490-fall22/_Group Projects/Group_5"
global sesame_data "$wd/4-sesame-data.dta"

// set trace on
// Create a program
cap prog drop group5 

/// regressing treatment and dependent variable, exporting regression table
program define group5
	ssc install outreg2
	use "$sesame_data", clear
	syntax anything
	local var1: word 1 of `anything'
	local var2: word 2 of `anything'
	reg `var1' `var2'
	outreg2 using demonstration.doc
end

group5 viewcat treatment

/// to drop the program: 
// prog drop group5

