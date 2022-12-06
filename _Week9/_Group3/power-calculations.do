// Set up
clear all

global username "/Users/anton/OneDrive/Documents/Georgetown/ECON/ECON490" // you have to change the line above
cd "${username}/econ490-fall22/_Week8/Group3"

// Run program and prepare for loop
run "schoolpower.do" // loads our schools program
set seed 341006 // randomization seed

*** Unbiased Estimator
cap mat drop results
// Generate observations, run regression, and store key information
foreach k in 1 3 5 10 { 				// loop over effect size 
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

	** Based on these tables, we correctly reject the null hypothesis in 100% of simulations where the true effect on test scores for NSLP-ineligible students is 5 points or more, regardless of intracluster correlation. When the true effect size is 3 points and intracluster correlation is low (0 to .5), we correctly reject the null hypothesis in almost all simulations (98% to 100%), and we correctly reject the null hypothesis in 92% of simulations when the intracluster correlation is .75 and the true effect size is 3 points. When the true effect size is 1 point, we correctly reject the null hypothesis in less than half of the simulations.
