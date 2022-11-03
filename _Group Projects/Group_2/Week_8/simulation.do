clear all

*******************************************************************************
*************************  Change directory  **********************************
*******************************************************************************

cd "/Users/felipe.germanos/Documents/Felipe/Georgetown/Semesters/7thSemester/Research Design/Week 8"

*******************************************************************************
*************** Setting up random seed and running program  *******************
*******************************************************************************


set seed 15771 // generated using random.org
do "program.do"

*******************************************************************************
**** Running the program several times and storing results in a csv files  ****
*******************************************************************************


/* First, we obtain means for 10, 50, 100, and 500 runs of the program to determine whether there is error convergence; error should decrease for larger numbers of runs */
foreach j in 10 50 100 500 {
	forval i = 1/`j' {
	clear
	quietly pmt `j'
	// get the inclusion and exclusion errors 
	mat results = nullmat(results) ///
		\[`i',`r(ie)', `r(ee)']	
		
}

/* Now, we save our resulting inclusion and exclusion errors in tables,
and we graph the distribution of both kinds of error for each iteration
of the program into density plots */
	
mat colnames results = n inclusion_error exclusion_error  
clear
svmat results, names(col)
export delimited using "pmt_`j'_runs", replace

kdensity inclusion_error, b1title("Distribution of Inclusion Error") name("inc_density_`j'", replace)
kdensity exclusion_error, b1title("Distribution of Exclusion Error") name("exc_density_`j'", replace)

sum exclusion_error 
local excl_error = r(mean)
sum inclusion_error
local incl_error = r(mean)
mat errors = nullmat(errors) \[`j', `excl_error', `incl_error']

}

mat colnames errors = n inclusion_error exclusion_error  
clear 
svmat errors, names(col)

export delimited using "errors_summary", replace

*******************************************************************************
************************ Final calculation and output  ************************
*******************************************************************************

/* Here, we simply combine the graphs from before and save one pair of plots
for each sample size we choose. */

foreach j in 10 50 100 500 {
	graph combine inc_density_`j' exc_density_`j', title("Inclusion and Exclusion Error Distribition for n = `j'")
	graph export "errors_`j'_plot.png", replace
}




