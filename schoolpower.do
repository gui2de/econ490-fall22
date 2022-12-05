***** (1) Drop any program called 'schoolpower'
cap prog drop schoolpower

***** (2) Setting up program schoolpower
prog def schoolpower, rclass
	syntax, rho(real) effect_size(real) [biased] // input is intracluster correlation coefficient ('ICC')
	clear

	set obs 200 // 200 clusters (schools)
	gen school = _n // to refer to each school, which are clusters
	gen treat = rbinomial(1, 0.5)
	gen n_students = round(75 + 10*rnormal()) // randomizing number of students per school
	expand n_students // replace each school obs with "n_students" many copies
	by school, sort: gen id = _n // assign ids to each student
	
	// generating actual intracluster correlation in the data
		// assuming total variance = 1
		local sd_u = sqrt(`rho') // u represents standard dev BETWEEN clusters
		local sd_e = sqrt(1-`rho') // e is standard dev WITHIN clusters
		
		// sampling u and e
		by school (id), sort: gen u = rnormal(0, `sd_u') if _n == 1
		by school (id): replace u = u[1] // this is measuring 'school effects', or variance BETWEEN schools. So, within a school, this is the same for all students.
		gen e = rnormal(0, `sd_e')

**** (3) Defining score variable based on treatment status
	// We are creating an outcome variable (standardized test score) on a scale from 1 to 100. We assume that low-income
	// students who are already eligible for free/reduced-price lunch score lower on this test, supported by literature
	// on the interactions between poverty and school achievement. Similarly, we assume that low-income students will see
	// a larger effect size than high-income students. Thus, we generate the outcome variable to fit these assumptions.
	
	gen frpl = round(runiform(0,1)) // whether a students gets free/reduced-price lunch (in the absence of a universal program)
	gen frpl_treat = frpl*treat
	
	gen score = .
	replace score = round(70 + 10*(u + e)) if treat == 0 & frpl == 0
	replace score = round(60 + 10*(u + e)) if treat == 0 & frpl == 1 // assuming low-income students have lower test scores
	replace score = round(70 + `effect_size' + 10*(u + e)) if treat == 1 & frpl == 0
	replace score = round(60 + 1.5*`effect_size' + 10*(u + e)) if frpl_treat == 1 	 // assuming low income students see a larger benefit from program
	replace score = 100 if score > 100 // students can not score above 100 on the exam
		replace score = 0 if score < 0 // fortunately for the students, they also cannot score below 0
		
		
**** (4) Defining additional outcome variables that will be present in the dataset
		gen absences = round(rnormal(3, 3)) // # of absences
		replace absences = 0 if absences < 0
		gen disc = floor(absences/3)+round(runiform(0,3)) // # of disciplinary actions
		replace disc = 0 if disc < 0
		gen bmi = round(rnormal(20,2)) // health measure
		gen tchr_eval = round(rnormal(1,5)) // teacher evaluation of student
		replace tchr_eval = 0 if tchr_eval < 0 
		replace tchr_eval = 0 if tchr_eval > 5
		
**** (5) Modeling the effect of the program on test scores
	// Because free/reduced-price lunch eligibility is included in our data-generating process, excluding this variable (and its interaction with the treatment dummy) will bias the estimator
	
if "`biased'" == "" {
	reg  score treat frpl, robust
	} // non-biased, with previous eligibility for FRPL
else {
	reg  score treat, robust
	} // biased, excludes previous eligibility for FRPL
	
	* save effect coefficient as scalar
		scalar b_treat = _b[treat]
	
**** (6) Power Calculations
	local alpha = 0.05
	matrix regtable=r(table)
	scalar pvalue=regtable[4,1]
end
