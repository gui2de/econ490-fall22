// Set global dir



// Create a program
cap prog drop group5 

program group5					   /// regressing treatment and dependent variable, exporting regression table
	use "/Users/miglepetrauskaite/Documents/1. Washington DC/Academics/2 Semester/Econometrics/Adv econ II/4. Instrumental variables/4-sesame-data.dta"	   	/// sysuse not working, uploading own data 
	syntax anything 			/// write two variables
	local var1: word 1 of `anything'
	local var2: word 2 of `anything'
	reg `var1' `var2'
	outreg2 using program-test-reg.doc
end


group5 age treatment 		/// testing the program
 
/// to drop the program: prog drop group5

