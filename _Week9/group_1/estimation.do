cap program drop estimation // note: did not name program 'simulate' because simulate is a pre-existing Stata command

program define estimation, rclass // define an r-class program
	syntax anything [, biased]

	// clear data in memory
	clear

	// generate blank data (observations without any content)
	set obs `anything' // `anything' is the number of constituencies we sampled from (anywhere from 1 to 85, which is the number of electoral wards in Nairobi)
	
	* ---------- generate village clusters and associated fixed effects ----------*
	// generate village cluster
	generate ward = _n // generate constituency clusters
	label variable ward "Electoral ward in which individual is located"
	
	generate u_ci = rnormal(0,0.3) // generate fixed effects for electoral wards
	
	// SHAILY: I'm curious what you think of the assumptions I make above....
	
	// generate individual observations
	quietly count
	local perc_preg = 0.01
	local perc_not_abort = 0.86
	local recruit_rate = 0.05
	forvalues i =1/`r(N)'{
		local ward_sample = rnormal(51729,500) * `perc_preg' * `perc_not_abort' * `recruit_rate'
		expand `ward_sample' if ward == `i'
	}
	
	* generate variable identifying individuals
	bysort ward: generate individual = _n
	
	* ---------- add individual ID variable ----------*
	// generate a string variable with leading zeros for state variable
	tostring ward, format(%02.0f) generate(temp1)
	
	// generate a string variable with leading zeros for university variable
	tostring individual, format(%06.0f) generate(temp2)

	// create id variable by concatenating string variables
	egen id = concat(temp1 temp2)
	label variable id "Identification number for individual"
	
	// drop irrelevant string variables
	drop temp1 temp2

	* ---------- generate individual characteristics of women ----------*
	
	// generate and label age variables such that about 34.8% of women are 15-24, 45.1% of women are 25-34,
	// and 20.1% of women are 35-49
	tempvar random_var0a random_var0b random_var0c random_var0d
	generate `random_var0a' = runiform(0,1)
	generate `random_var0b' = runiformint(15,24)
	generate `random_var0c' = runiformint(25,34)
	generate `random_var0d' = runiformint(35,49)
	generate age = .
	replace age = `random_var0b' if `random_var0a' <= 0.348
	replace age = `random_var0c' if `random_var0a' > 0.348 & `random_var0a' <= 0.799
	replace age = `random_var0d' if `random_var0a' > 0.799
	label variable age "Age of individual"
	
	// generate and label marital status dummy variables such that about 8.6% of women are never married,
	// 82.3% are currently married, and 9.1% are formerly married
	tempvar random_var_1
	generate married = 0
	generate `random_var_1' = runiform(0,1)
	replace married = 1 if `random_var_1' >= 0.823
	label define married 1 "Married at baseline" 0 "Not married at baseline"
	label values married married
	generate formerly_married = 0
	replace formerly_married = 1 if `random_var_1' < 0.091
	label define formerly_married 1 "Formerly married at baseline" 0 "Not formerly married at baseline"
	label values formerly_married formerly_married
	generate never_married = 0
	replace never_married = 1 if married ~= 1 & formerly_married ~= 1
	label define never_married 1 "Never married at baseline" 0 "Never married at baseline"
	label values never_married never_married
	
	// generate and label variable years of education
	tempvar random_var2
	generate `random_var2' = runiform(0,1)
	generate no_education = 0
	generate primary_school = 0
	generate secondary_or_more = 0
	replace no_education = 1 if `random_var2' <= 0.184
	replace primary_school = 1 if `random_var2' > 0.184 & `random_var2' <= 0.746
	replace secondary_or_more = 1 if no_education ~= 1 & primary_school ~= 1
	label variable no_education "Whether they have received less than a primary school level of education"
	label variable primary_school "Whether they have received a primary school education (but not a secondary education)"
	label variable secondary_or_more "Whether they have received a secondary school education or more"
	
	// generate and label variable representing number of weeks pregnant at time of recruitment for study
	generate weeks_preg = runiformint(3,13)
	label variable weeks_preg "Number of weeks pregnant at recruitment"
	
	// generate and label variable representing household income in the past month
	generate income_baseline = rnormal(14000,2000)
	label variable income_baseline "Household income in the past month (in KES)"
	
	// generate variable representing whether or not they own a smartphone
	tempvar random_var3
	generate own_smartphone = 0
	generate `random_var3' = runiform(0,1)
	replace own_smartphone = 1 if `random_var3' < 0.5
	label define own_smartphone 1 "Owns a smartphone at baseline" 0 "Does not own a smartphone at baseline"
	label values own_smartphone own_smartphone
	label variable own_smartphone "Whether or not the individual owns a smartphone at baseline"
	
	// generate dummy variables representing whether they are formally employed, informally employed, or unemployed
	tempvar random_var4
	generate `random_var4' = runiform(0,1)
	generate employed = 0
	replace employed = 1 if `random_var4' < 0.629
	label define employed 1 "Employed at baseline" 0 "Not employed at baseline"
	label values employed employed
	label variable employed "Whether or not the individual was employed at baseline"
	
	// generate variable representing number of other children
	generate num_other_child = runiformint(0,4)
	label variable num_other_child "Number of children, not including child individual is currently pregnant with"
	
	// generate variable representing median age of other child/children
	generate child_age = runiformint(2,18)
	replace child_age = 0 if num_other_child == 0
	label variable child_age "Median age of other children, set equal to zero if they do not have other children"
	
	// generate dummy variable representing whether she received antenatal care in a previous pregnancy
	tempvar random_var5
	generate `random_var5' = runiform(0,1)
	generate prev_antenatal = 0
	replace prev_antenatal = 1 if `random_var5' > 0.5
	replace prev_antenatal = 0 if num_other_child == 0
	label define prev_antenatal 1 "Received antenatal care in a previous pregnancy" 0 ///
	"Did not receive antenatal care in a previous pregnancy (including because the individual does not have other children)"
	label values prev_antenatal prev_antenatal
	label variable prev_antenatal "Whether or not the individual received antenatal care in a previous pregnancy"
	
	// generate variable representing index of severity of past pregnancy complications, set to zero if they had not had children before
	generate past_comp = runiformint(1,10)
	replace past_comp = 0 if num_other_child == 0
	label variable past_comp "Index representing average severity of complications in past pregnancy or pregnancies; if no previous pregnancies, set to zero"
	
	// generate variable representing distance from the nearest health care provider offering ANC in miles
	generate distance_anc = rnormal(8,1)
	label variable distance_anc "Distance from closest antenatal care provider (in kilometers)"
	
	// generate variable representing distance from the nearest hospital
	generate distance_hospital = rnormal(14,2)
	label variable distance_hospital "Distance from closest hospital (in kilometers)"
	
	// generate dummy variable representing whether they've yet visited a doctor during this pregnancy
	tempvar random_var6
	generate `random_var6' = runiform(0,1)
	generate visited_doc = 0
	replace visited_doc = 1 if `random_var6' > 0.5
	label define visited_doc 1 "Have received ANC for this pregnancy at baseline" 0 "Have not received ANC for this pregnancy at baseline"
	label values visited_doc visited_doc
	label variable visited_doc "Whether or not individual has received ANC for this pregnancy at baseline"
	
	* SHAILY: How would the head of household variable included in the concept note work? How would it be different from the marital status variable?
	
	* ---------- generate intent to treat and received treatment variable ----------*
	// assign approximately half of wards to treatment
	generate assign_treat_paper = 0
	generate assign_treat_mobile = 0
	replace assign_treat_paper = 1 if mod(ward,4) == 2
	replace assign_treat_mobile = 1 if mod(ward,4) == 0
	
	// given spillover effects and issues with deliverability of pamphlets and text messages, create a variable 
	// that reflects whether they actually received treatment
	generate receiv_treat_mobile = assign_treat_mobile
	generate receiv_treat_paper = assign_treat_paper
	tempvar random_var6
	generate `random_var6' = runiform(0,1)
	replace receiv_treat_mobile = 0 if `random_var6' < 0.25
	replace receiv_treat_paper = 0 if `random_var6' < 0.25
	
	// randomly drop some observations to represent (random) attrition
	drop if `random_var6' >= 0.92

	* ---------- final steps: generate estimate ----------*
	
	* generate effects for each regressor
	local eff_age = -0.1
	local eff_child_age = -0.2
	local eff_distance_anc = 0.02
	local eff_distance_hospital = 0.01
	local eff_formerly_married = 1
	local eff_primary_school = -0.1
	local eff_secondary_or_more = -0.2
	local eff_employed = -2
	local eff_income_baseline = -0.002
	local eff_married = -0.1
	local eff_num_other_child = 1
	local eff_own_smartphone = -1
	local eff_past_comp = -1
	local eff_prev_antenatal = -1
	local eff_visited_doc = -0.05
	local eff_weeks_preg = 1.5
	local eff_receiv_treat_paper = -0.2
	local eff_receiv_treat_mobile = -0.5
	
	
	* create variable representing number of weeks after intervention of first ANC visit using data-generating process
	generate anc_timing = 2 ///
	+ `eff_age' * age ///
	+ `eff_child_age' * child_age ///
	+ `eff_distance_anc' * distance_anc ///
	+ `eff_distance_hospital' * distance_hospital ///
	+ `eff_married' * married ///
	+ `eff_primary_school' * primary_school ///
	+ `eff_secondary_or_more' * secondary_or_more ///
	+ `eff_employed' * employed ///
	+ `eff_income_baseline' * income_baseline ///
	+ `eff_num_other_child' * num_other_child ///
	+ `eff_own_smartphone' * own_smartphone ///
	+ `eff_past_comp' * past_comp ///
	+ `eff_prev_antenatal' * prev_antenatal ///
	+ `eff_visited_doc' * visited_doc ///
	+ `eff_weeks_preg' * weeks_preg ///
	+ `eff_receiv_treat_paper' * receiv_treat_paper ///
	+ `eff_receiv_treat_mobile' * receiv_treat_mobile ///
	+ u_ci ///
	+ rnormal(0,2)
	label variable anc_timing "Number of weeks after intervention of first ANC visit"
	
	// estimate coefficient on treatment
	if "`biased'" == "" {
		* create list of regressors to be included in regression
		local biased_regressors "age child_age distance_anc distance_hospital married formerly_married primary_school secondary_or_more employed income_baseline num_other_child own_smartphone past_comp prev_antenatal visited_doc weeks_preg assign_treat_paper assign_treat_mobile"
		
		* generate biased statistics by estimating intent to treat (not treatment on the treated) effect
		reg anc_timing `biased_regressors', vce(cluster ward)
		
		* collect statistics resulting from regression
		local b_paper = _b[assign_treat_paper]
		local se_paper = _se[assign_treat_paper]
		local b_mobile = _b[assign_treat_mobile]
		local se_mobile = _se[assign_treat_mobile]
		local sample_size = _N
	} 
	else {
		* create list of regressors to be included in regression
		local unbiased_regressors "age child_age distance_anc distance_hospital married formerly_married primary_school secondary_or_more employed income_baseline num_other_child own_smartphone past_comp prev_antenatal visited_doc weeks_preg"
		
		* generate unbiased statistics by using being assigned treatment as an instrument for receiving treatment
		
		* run first-stage regressions and generate predictions
		regress receiv_treat_mobile assign_treat_mobile `unbiased_regressors'
		predict mobile_predict, xb
		regress receiv_treat_paper assign_treat_paper `unbiased_regressors'
		predict paper_predict, xb
		
		* run second-stage regression
		regress anc_timing mobile_predict paper_predict `unbiased_regressors', vce(cluster ward)
		
		* collect statistics resulting from regression
		local b_paper = _b[paper_predict]
		local se_paper = _se[paper_predict]
		local b_mobile = _b[mobile_predict]
		local se_mobile = _se[mobile_predict]
		local sample_size = _N
	}

	// return statistics (coefficient on treatment and its standard error)
	return scalar b_mobile = `b_mobile'
	return scalar b_paper = `b_paper'
	return scalar se_mobile = `se_mobile'
	return scalar se_paper = `se_paper'
	return scalar sample_size = `sample_size'
end
