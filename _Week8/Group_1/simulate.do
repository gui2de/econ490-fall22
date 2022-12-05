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
	generate random1 = runiform(15,25) // generate random numbers to be used to vary number of schools per region
	
	// generate university clusters within states, with 15-25 universities per state 
	expand round(random1)
	bysort state: generate university = _n // generate university clusters
	label variable university "College or university that student attended"
	
	generate e_ij = rnormal(0,5)*100 // generate fixed effects for universities
	generate random2 = runiform(300,8000)  // generate random numbers to be used to vary number of students per school
	
	// generate student observations using a uniform random variable, with 300 to 8000 students per school
	expand round(random2)
	bysort state university: generate student = _n // generate student variable

	* ---------- generate individual characteristics of students ----------*
	// generate and label variables for parents education, sat score, and number of AP credits taken in high school
	generate p1_educ = runiformint(10,18)
	label variable p1_educ "Student's parent 1's years of educational attainment"
	generate p2_educ = runiformint(10,18)
	label variable p2_educ "Student's parent 2's years of educational attainment"
	generate sat_score = rnormal(1200,70)
	replace sat_score = round(sat_score)
	label variable sat_score "Student's SAT score"
	replace sat_score = 1600 if sat_score > 1600
	replace sat_score = 400 if sat_score < 400
	generate ap_cred = runiformint(0,12)
	label variable ap_cred "Number of AP credits (or equivalent) taken in high school"

	// generate undergraduate GPA variable, which depends on the individual characteristics calculated above
	generate gpa = 1.5 + (.01)*(p1_educ) + (.01)*(p2_educ) + (.001)*(sat_score) + (.05)*(ap_cred) + (rnormal()/100)
	label variable gpa "Undergraduate GPA"
	replace gpa = 4 if gpa > 4
	replace gpa = 0 if gpa < 0
	 
	// generate variable representing undergraduate major
	generate major = runiformint(1,200)
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
	// generate a string variable for state variable
	tostring state, generate(temp1)
	
	// generate a string variable for university variable
	tostring university, generate(temp2)
	
	// generate a string variable for student variable
	tostring student, generate(temp3)
	
	// generate temporary string variables with characters to be used to create id variable
	tempvar state_string
	tempvar university_string
	tempvar student_string
	generate `state_string' = "sta"
	generate `university_string' = "uni"
	generate `student_string' = "stu"
	
	// create id variable by concatenating string versions of state, university, and student id numbers and character strings created immediately above
	egen id = concat(`state_string' temp1 `university_string' temp2 `student_string' temp3)
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
