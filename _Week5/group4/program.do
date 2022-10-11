cap prog drop graphsum
//drops previous programs named "graphsum"

prog define graphsum
	syntax anything
	local sysdata: word 1 of `anything'
	local var1: word 2 of `anything'
	local var2: word 3 of `anything' 		//we separate the inputs into their own local variables 
	sysuse `sysdata', clear 
	twoway (scatter `var1' `var2') (lfit `var1' `var2')
	graph save `sysdata'_scatter_`var1'_`var2'.gph, replace			//We save a scatterplot with best fit line to the current working directory
	cap matrix drop `sysdata'_summary
	forval i=1/2{
		qui sum `var`i''
		mat `sysdata'_summary = nullmat(`sysdata'_summary)\[r(N), r(mean), r(Var), r(sd), r(min), r(max)]		//We save a matrix with summary statistics for both variables
	}
	matrix colnames `sysdata'_summary  = obs mean var sd min max
	matrix rownames `sysdata'_summary  = `var1' `var2'
	forval i=1/2{
		hist `var`i''
		graph save `sysdata'_hist_`var`i''.gph, replace				//We save histograms of both variables to the current working directory
	}
	graph combine `sysdata'_hist_`var1'.gph `sysdata'_hist_`var2'.gph 
	graph save `sysdata'_hist_`var1'_`var2'.gph, replace			//We combine the histograms to view in one file
	reg `var1' `var2', robust
	mat `sysdata'_reg_`var1'_`var2'_results = r(table)		//we save a matrix with regression results for the variables
	
end

