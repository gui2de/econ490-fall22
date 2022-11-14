// Set up
clear all

global username "/Users/anton/OneDrive/Documents/Georgetown/ECON/ECON490" // you have to change the line above
cd "${username}/econ490-fall22/_Week8/Group3"

// Run program and prepare for loop
run "program.do" // loads our schools program
set seed 341006 // randomization seed
cap mat drop results

// Generate observations, run regression, and store key information
foreach k in 5 10 15 20 { 				// loop over effect size 
foreach i in .25 .5 .75 { 		// loop over parameter index (icc)
	forv j = 1/50 { 		// # of iterations/runs
		clear
		quietly schoolpower, rho(`i') effect_size(`k')
		mat results = nullmat(results) \ [`j', `i', `k', pvalue, b_treat]
	}
}
}

// Create matrix
mat colnames results = j rho true_effect pvalue b_treat // change matrix column names
clear
svmat results, names(col) // stores mat columns as new variables

// Determine whether p-value would be rejected
gen reject = 0
replace reject = 1 if pvalue < 0.05

// Mean p-value for each combination of rho and effect size
tabulate rho true_effect, summarize(pvalue) means

// Percent of iterations in which the null hypothesis was rejected
tabulate rho true_effect, summarize(reject) means
