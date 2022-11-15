// Set your global dir
global wd "/Users/miglepetrauskaite/Desktop/GITHUB/Repo/econ490-fall22/_Group Projects/Group_5"


/// The following program will first of all install the user-written outreg2 command and, using the data from the internet, run a simple regression using two variables that you specify. The program will also export the regression results into a neat table in the directory you specify:

program define group5
	ssc install outreg2
	webuse nlswork, clear
	syntax anything
	local var1: word 1 of `anything'
	local var2: word 2 of `anything'
	reg `var1' `var2'
	outreg2 using "$wd/demonstration.doc", replace
end


/// if you need to drop the program, uncomment the following: 
/// prog drop group5


