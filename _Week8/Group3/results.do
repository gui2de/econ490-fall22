clear all
set seed 341006
do "simulate.do"
cap mat drop results

// running simulation - 100 runs each for rho = 0, .25, .5, .75, and 1
foreach i in 0 .25 .5 .75 1 {
	forv j = 1/100 { 
		clear
		quietly schools, rho(`i')
		mat results = nullmat(results) \ [`i', `icc', `g', `design']
	}
}

mat colnames results = i icc g design

clear

svmat results, names(col)

local vars icc g  // remove design?

foreach `i' in `vars' {
	scatter `i' design, name ("graph_`i'", replace)
}

graph combine graph_icc graph_g

graph display

// Now we have to do something with these outputs

// Ideas:
* plot of icc and design to show how larger ICC corresponds to larger design effect
* plot of g and design (since large cluster sizes often inc. design effect)

* dot plot showing data values by school (cluster) at different ICC ?