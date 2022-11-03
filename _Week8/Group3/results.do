clear all

* Using code I saw in Group 4's code to set the working directory!

global username "/Users/anton/OneDrive/Documents/Georgetown/ECON/ECON490" // you have to change the line above
cd "${username}/econ490-fall22/_Week8/Group3"

run "simulate.do" // loads our schools program
set seed 341006 // randomization seed

cap mat drop results

// running simulation - 100 runs each for rho = .01, .25, .5, .75, and .99
// note: issues with "convergence not achieved" for rho(1) and rho(0), so we use rho(.99) and rho(.01) instead.
foreach i in .01 .25 .5 .75 .99 { 		// loop over parameter index (icc)
	forv j = 1/100 { 		// # of iterations/runs
		clear
		quietly schools, rho(`i')
		mat results = nullmat(results) \ [`j', `i', icc, g, design]
	}
}

mat colnames results = j rho icc g design // change matrix column names

clear
svmat results, names(col) // stores mat columns as new variables

* scatter plot
scatter design icc, name("design_icc_scatter", replace)
// larger icc corresponds to larger design effect

graph export "week8_design_icc_scatter.png", replace

export delimited week8_rho_icc_design, replace

* another idea: dot plot showing data values by school (cluster) at different ICC ?