/* Group 1
Week 5 Assignment
Program .do file */

capture program drop one_way_anova
prog def one_way_anova
	
	args data_set outcome_var group_var
	
	sysuse `data_set', clear
	
	* Count total length of data set, excluding missing values
	quietly count if ~missing(`group_var') & ~missing(`outcome_var')
	local len_data_set = r(N)
	
	* Create matrix of names of groups in group variable, excluding groups whose values are missing all values of the outcome variable
	quietly levelsof `group_var' if ~missing(`outcome_var'), matrow(distinct_mat)
	
	* Calculate number of groups
	local nrow_mat = `= rowsof(distinct_mat)'
	
	* Append two empty columns to matrix of group names
	matrix a = J(`nrow_mat',2,.)
	matrix distinct_mat = distinct_mat , a
	
	* Calculate the overall mean of the data, excluding observations whose values for both the group and outcome variables are missing
	quietly sum `outcome_var' if ~missing(`group_var') & ~missing(`outcome_var')
	local overall_mean = `r(mean)'
	
	* Add the mean and size of each group to the matrix of names of groups in order to make future calculations easier
	forvalues i=1/`nrow_mat'{
		quietly sum `outcome_var' if `group_var' == distinct_mat[`i',1] & ~missing(`outcome_var')
		matrix distinct_mat[`i',2] = `r(mean)'
		matrix distinct_mat[`i',3] = `r(N)'
	}
	
	* Calculate sum of squares between (SSB)
	local ssb = 0
	forvalues i=1/`nrow_mat' {
		local j = distinct_mat[`i',3] * (distinct_mat[`i',2] - `overall_mean') ^ 2
		local ssb = `ssb' + `j'
	}
	
	* Calculate sum of squares total (SST), excluding observations whose values for both the group and outcome variables are missing
	gen sst_calc = (`outcome_var' - `overall_mean') ^ 2 if ~missing(`group_var') & ~missing(`outcome_var')
	quietly tabstat sst_calc, stat(sum) save
	matrix stat_sum = r(StatTotal)
	local sst = stat_sum[1,1]
	drop sst_calc
	
	* Calculate sum of squared errors (SSE) using SSB and SST
	local sse = `sst' - `ssb'
	
	* Calculate other parts of ANOVA matrix using local variables defined above
	local bw_treat_df = `nrow_mat' - 1
	local error_df = `len_data_set' - `nrow_mat'
	local total_df = `len_data_set' - 1
	local msb = `ssb' / `bw_treat_df'
	local mse = `sse' / `error_df'
	local f = `msb'/`mse'
	local p_ftest = Ftail(`bw_treat_df', `error_df', `f')
	
	* Assemble ANOVA matrix
	matrix anova_results = J(3,5,.)
	matrix anova_results[1,1] = `ssb'
	matrix anova_results[2,1] = `sse'
	matrix anova_results[3,1] = `sst'
	matrix anova_results[1,2] = `bw_treat_df'
	matrix anova_results[2,2] = `error_df'
	matrix anova_results[3,2] = `total_df'
	matrix anova_results[1,3] = `msb'
	matrix anova_results[2,3] = `mse'
	matrix anova_results[1,4] = `f'
	matrix anova_results[1,5] = `p_ftest'
	
	* Add column and row names to ANOVA matrix
	matrix colnames anova_results = SS DF MS F "Prob>F"
	matrix rownames anova_results = "Between Treatments" Error Total
	
	* Display ANOVA results
	matlist anova_results
	
	* Generate box plot of the outcome variable over each group
	graph box `outcome_var', over(`group_var') title("Distribution of `outcome_var' by `group_var'")
	
end
