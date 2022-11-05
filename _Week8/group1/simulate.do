cap program drop salary_simulate // note: did not name program 'simulate' because simulate is a pre-existing Stata command

program define salary_simulate, rclass // define an r-class program so that the program writes into return and we can get stuff out of the program
	syntax anything

	// clear data in memory
	clear

	// generate blank data (observations without any content)
	set obs `anything' // `anything' is number of states sampled from
	
	* ---------- generate clusters and associated fixed effects ----------*
	// generate state cluster
	generate state = _n // generate state clusters
	label variable state "State in which college or university is located"
	
	generate u_i = rchi2(4)*1000 // generate fixed effects for states
	generate random1 = runiform() // generate random numbers to be used to vary number of schools per region
	
	// generate university clusters within states, with 15-25 universities per state 
	expand 15 if random1 < 0.3
	expand 20 if random1 >= 0.3 & random1 < 0.7
	expand 25 if random1 >= 0.7
	bysort state: generate university = _n // generate university clusters
	label variable university "College or university that student attended"
	
	generate e_ij = rnormal(0,5)*100 // generate fixed effects for universities
	generate random2 = runiform()  // generate random numbers to be used to vary number of students per school
	
	// generate student observations, with 500-1000 students per university
	expand 500 if random2 < 0.3
	expand 750 if random2 >= 0.3 & random2 < 0.8
	expand 1000 if random2 >= 0.8
	bysort state university: generate student = _n // generate student variable

	* ---------- generate individual characteristics of students ----------*
	// generate and label variables for parents education, sat score, and number of AP credits taken in high school
	generate p1_educ = runiformint(10,18)
	label variable p1_educ "Student's parent 1's years of educational attainment"
	generate p2_educ = runiformint(10,18)
	label variable p2_educ "Student's parent 2's years of educational attainment"
	generate sat_score = 1200+rnormal(0,70)
	replace sat_score = trunc(sat_score)
	label variable sat_score "Student's SAT score"
	replace sat_score = 1600 if sat_score > 1600
	replace sat_score = 400 if sat_score < 400
	generate ap_cred = rpoisson(2)
	label variable ap_cred "Number of AP credits (or equivalent) taken in high school"
	replace ap_cred = 8 if ap_cred > 8

	// generate undergraduate GPA variable, which depends on the individual characteristics calculated above
	generate gpa = 1.5 + (.01)*(p1_educ) + (.01)*(p2_educ) + (.001)*(sat_score) + (.05)*(ap_cred) + (rnormal()/100)
	label variable gpa "Undergraduate GPA"
	replace gpa = 4 if gpa > 4
	replace gpa = 0 if gpa < 0
	 
	// geenrate variable representing undergraduate major
	generate major = runiformint(1,34)
	label variable major "College or university undergraduate major"
	bysort major: gen m_k = rnormal()*7493 // generate fixed effect for major of study
	
	// generate local variable representing coefficient on GPA 
	local gpa_effect = 5000
	
	// model post-graduate salary generative model
	generate salary = 60000 + (`gpa_effect')*(gpa) + m_k + u_i + e_ij + (rnormal()*100)
	label variable salary "Post-graduate salary of student"
	
	* ---------- generate strata ----------*
	// generate post-grad salary stratum
	generate stratum_inc = 2
	replace stratum_inc = 3 if salary > 90000
	replace stratum_inc = 1 if salary < 65000
	label variable stratum_inc "Post-graduate income stratum"
	label define stratum1 1 "lower income" 2 "medium income" 3 "higher income"
	label values stratum_inc stratum1
	
	// generate parental educational stratum
	generate stratum_peduc = 2
	replace stratum_peduc = 1 if p1_educ < 16 & p2_educ < 16
	replace stratum_peduc = 3 if p1_educ >= 16 & p2_educ >= 16
	label define stratum2 1 "neither parent graduated four-year college" 2 "only one parent graduated four-year college" ///
	3 "both parents graduated four-year college"
	label values stratum_peduc stratum2
	
	* ---------- add individual ID variable ----------*
	// generate a string variable with leading zeros for state variable
	*generate str1 temp1 = string(state,"%01.0f")
	*replace temp1 = string(state) if state >= 10
	tostring state, format(%02.0f) generate(temp1)
	
	// generate a string variable with leading zeros for university variable
	tostring university, format(%02.0f) generate(temp2)
	
	// generate a string variable with leading zeros for student variable
	tostring student, format(%04.0f) generate(temp3)
	
	// create id variable by concatenating string variables
	egen id = concat(temp1 temp2 temp3)
	label variable id "Identification number for student"
	
	// drop irrelevant string variables
	drop temp1 temp2 temp3

	* ---------- final steps ----------*
	// re-estimate coefficient on gpa
	regress salary gpa m_k u_i e_ij
	local b_gpa = _b[gpa]
	local se_gpa = _se[gpa]
	local sample_size = _N

	// return statistics (coefficient on GPA and its standard error)
	return scalar b_gpa = `b_gpa'
	return scalar se_gpa = `se_gpa'
	return scalar sample_size = `sample_size'
end
