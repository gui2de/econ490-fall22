// Set global dir

global wd "/Users/miglepetrauskaite/Desktop/GITHUB/Repo/econ490-fall22/_Group Projects/Group_5"


// set trace on
// Create a program
log using session
cap prog drop group5 

/// regressing treatment and dependent variable, exporting regression table
program define group5
	ssc install outreg2
	webuse nlswork, clear
	syntax anything
	local var1: word 1 of `anything'
	local var2: word 2 of `anything'
	reg `var1' `var2'
	outreg2 using demonstration.doc
end

group5 ln_wage race
translate session.smcl outcome.pdf
/// to drop the program: 
/// prog drop group5

