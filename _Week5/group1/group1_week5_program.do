/* Group 1
Week 5 Assignment
Program .do file */

* SYLVIA: ADD ERROR CODE, like checking that the variables are of the right type (numerical/categorical)
* link to ANOVA calculations: https://sphweb.bumc.bu.edu/otlt/MPH-Modules/BS/BS704_HypothesisTesting-ANOVA/BS704_HypothesisTesting-Anova3.html
* SYLVIA: THINK IF YOU NEED TO DEAL WITH MISSING VALUES ANYWHERE

cap prog drop one_way_anova
set trace on
prog def one_way_anova
	
	* defines a local macro in the scope of 
	syntax program_param // write two variable names
	global data_set: word 1 of `program_param' 
	local group_var: word 2 of `program_param'
	local outcome_var: word 3 of `program_param'
	
	* SYLVIA: NEED TO FIGURE OUT HOW TO LOAD DATA SET
	sysuse `data_set'
	
	* count total length of data set
	local len_data_set = _N
	
	* create matrix of names of groups
	levelsof `group_var', matrow(distinct_mat)
	matlist distinct_mat
	
	* calculate number of treatment groups
	local nrow_mat = `= rowsof(distinct_mat)'
	
	* get the overall mean
	quietly sum `outcome_var' if ~missing(`outcome_var')
	local overall_mean = `r(mean)'
	
	* append two empty columns to matrix
	* SYLVIA: NEED TO FIND A WAY TO MAKE "A" CUSTOMIZED TO # OF GROUPS
	matrix a = [. , . \ . , .]
	matrix distinct_mat = distinct_mat , a
	
	* add the mean and size of each group to matrix of names of groups
	forvalues i=1/`nrow_mat'{
		quietly sum `outcome_var' if `group_var' == distinct_mat[`i',1]
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
	gen sst_calc = (`outcome_var' - `overall_mean') ^ 2
	tabstat sst_calc, stat(sum) save
	matrix stat_sum = r(StatTotal)
	local sst = stat_sum[1,1]
	drop sst_calc
	
	* calculate SSE
	local sse = `sst' - `ssb'
	
	* calculate other parts of ANOVA matrix
	local bw_treat_df = `nrow_mat' - 1
	local error_df = `len_data_set' - `nrow_mat'
	local total_df = `len_data_set' - 1
	local msb = `ssb' - `bw_treat_df'
	local mse = `sse' - `error_df'
	local f = `msb'/`mse'
	
	* assemble ANOVA matrix
	matrix anova = [. , . , . , . \ . , . , . , .  \ . , . , . , . ]
	matrix anova[1,1] = `ssb'
	matrix anova[2,1] = `sse'
	matrix anova[3,1] = `sst'
	matrix anova[1,2] = `bw_treat_df'
	matrix anova[2,2] = `error_df'
	matrix anova[3,2] = `total_df'
	matrix anova[1,3] = `msb'
	matrix anova[2,3] = `mse'
	matrix anova[1,4] = `f'
	
	* SYLVIA: RENAME ROW/COLUMN LABELS OF MATRIX
	matrix rownames anova = SS DF MS F
	matrix colnames anova = between_treatments error total
	
end

one_way_anova auto foreign mpg

* AT END: CHECK OVER FOR EVERYTHING WE'VE LEARNED IN NOTES TO MAKE SURE YOU IMPLEMENT IT
