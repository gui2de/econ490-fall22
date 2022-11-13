



// running simulation - 100 runs each for rho = .01, .25, .5, .75, and .99
// note: issues with "convergence not achieved" for rho(1) and rho(0), so we use rho(.99) and rho(.01) instead.
foreach i in .01 .25 .5 .75 .99 { 		// loop over parameter index (icc)
	forv j = 1/100 { 		// # of iterations/runs
		clear
		quietly schoolpower, rho(`i') effect_size(`k') // also have to define desired effect size
		mat results = nullmat(results) \ [`j', `i', `k', mde, b_treat, icc, g, reject, design]
	}
}

mat colnames results = j rho true_effect mde b_treat // change matrix column names

clear
svmat results, names(col) // stores mat columns as new variables
