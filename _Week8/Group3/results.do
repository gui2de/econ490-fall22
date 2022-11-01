clear all
set seed 341006
do "simulate.do"
cap mat drop results

// running simulation - 100 runs each for rho = 0, .25, .5, .75, and 1
foreach i in 0 .25 .5 .75 1 {
	forv j = 1/100 {
		clear
		quietly schools, rho(`i')
		mat results = nullmat(results) \[`i', `icc', `g' `design']
	}
}

// Now we have to do something with these outputs
