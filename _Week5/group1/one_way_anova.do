/* Group 1
Week 5 Assignment
Program .do file */

* Explanation of ANOVA: https://sphweb.bumc.bu.edu/otlt/MPH-Modules/BS/BS704_HypothesisTesting-ANOVA/BS704_HypothesisTesting-Anova3.html

* Note that this function does NOT run tests of assumptions needed for ANOVA; should run those tests in Stata before using this program

clear
capture program drop one_way_anova
prog def one_way_anova
	
	args data_set outcome_var group_var
	
	sysuse `data_set'
	
	* count total length of data set, excluding missing values
	quietly count if ~missing(`group_var') & ~missing(`outcome_var')
	local len_data_set = r(N)
	
	* create matrix of names of groups
	quietly levelsof `group_var', matrow(distinct_mat)
	
	* calculate number of treatment groups
	local nrow_mat = `= rowsof(distinct_mat)'
	
	* get the overall mean
	quietly sum `outcome_var' if ~missing(`group_var') & ~missing(`outcome_var')
	local overall_mean = `r(mean)'
	
	* append two empty columns to matrix
	matrix a = J(`nrow_mat',2,.)
	matrix distinct_mat = distinct_mat , a
	
	* add the mean and size of each group to matrix of names of groups
	forvalues i=1/`nrow_mat'{
		quietly sum `outcome_var' if `group_var' == distinct_mat[`i',1] & ~missing(`outcome_var')
		matrix distinct_mat[`i',2] = `r(mean)'
		matrix distinct_mat[`i',3] = `r(N)'
	}
	
	* Calculate SSB
	local ssb = 0
	forvalues i=1/`nrow_mat' {
		local j = distinct_mat[`i',3] * (distinct_mat[`i',2] - `overall_mean') ^ 2
		local ssb = `ssb' + `j'
	}
	
	* Calculate SST
	gen sst_calc = (`outcome_var' - `overall_mean') ^ 2 if ~missing(`group_var') & ~missing(`outcome_var')
	quietly tabstat sst_calc, stat(sum) save
	matrix stat_sum = r(StatTotal)
	local sst = stat_sum[1,1]
	drop sst_calc
	
	* calculate SSE
	local sse = `sst' - `ssb'
	
	* calculate other parts of ANOVA matrix
	local bw_treat_df = `nrow_mat' - 1
	local error_df = `len_data_set' - `nrow_mat'
	local total_df = `len_data_set' - 1
	local msb = `ssb' / `bw_treat_df'
	local mse = `sse' / `error_df'
	local f = `msb'/`mse'
	local p_ftest = Ftail(`bw_treat_df', `error_df', `f')
	
	* assemble ANOVA matrix
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
	
	matrix colnames anova_results = SS DF MS F "Prob>F"
	matrix rownames anova_results = "Between Treatments" Error Total
	
	matlist anova_results
	
	* calculate box plot
	graph box `outcome_var', over(`group_var') title("Distribution of `outcome_var' by `group_var'")
	
end
