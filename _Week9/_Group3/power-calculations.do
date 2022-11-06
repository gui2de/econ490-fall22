clear all

* Using code I saw in Group 4's code to set the working directory!

global username "/Users/anton/OneDrive/Documents/Georgetown/ECON/ECON490" // you have to change the line above
cd "${username}/econ490-fall22/_Week8/Group3"

run "program.do" // loads our schools program
set seed 341006 // randomization seed

cap mat drop results

// running simulation - 100 runs each for rho = .01, .25, .5, .75, and .99
// note: issues with "convergence not achieved" for rho(1) and rho(0), so we use rho(.99) and rho(.01) instead.
foreach i in .01 .25 .5 .75 .99 { 		// loop over parameter index (icc)
	forv j = 1/100 { 		// # of iterations/runs
		clear
		quietly schoolpower, rho(`i') // also have to define desired effect size
		mat results = nullmat(results) \ [`j', `i', icc, g, design]
	}
}
