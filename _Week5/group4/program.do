cap prog drop graphsum
//drops previous programs named "graphsum"

prog define graphsum
	syntax anything
	local sysdata: word 1 of `anything'
	local var1: word 2 of `anything'
	local var2: word 3 of `anything' 		//we separate the inputs into their own local variables 
	sysuse `sysdata', clear 				//we load the data from system
	twoway (scatter `var1' `var2') (lfit `var1' `var2')
	graph save `sysdata'_scatter_`var1'_`var2'.gph, replace			//we save a scatterplot with best fit line to the current working directory
	cap matrix drop `sysdata'_summary			//drops previous matrices
	forval i=1/2{
		qui sum `var`i''
		mat `sysdata'_summary = nullmat(`sysdata'_summary)\[r(N), r(mean), r(Var), r(sd), r(min), r(max)]		//we save a matrix with summary statistics for both variables
	}
	matrix colnames `sysdata'_summary  = obs mean var sd min max
	matrix rownames `sysdata'_summary  = `var1' `var2'
	forval i=1/2{
		hist `var`i''
		graph save `sysdata'_hist_`var`i''.gph, replace				//we save histograms of both variables to the current working directory
	}
	graph combine `sysdata'_hist_`var1'.gph `sysdata'_hist_`var2'.gph 
	graph save `sysdata'_hist_`var1'_`var2'.gph, replace			//we combine the histograms to view in one file
	reg `var1' `var2', robust						//we run a robust regression of var1 on var2
	mat `sysdata'_reg_`var1'_`var2'_results = r(table)		//we save a matrix with regression results for the variables
	
end

