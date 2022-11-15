* first, drop any program called 'schools'
cap prog drop schools

* Now we create a program 'schools' that will store results in r()
prog def schools, rclass
	syntax, rho(real) // input is intracluster correlation coefficient ('ICC')
	
	clear // not clear all bc we need to preserve matrices in results.do
	
	set obs 200 // 200 clusters (schools)
	gen school = _n // to refer to each school, which are clusters
	gen n_students = round(75 + 10*rnormal()) // randomizing number of students (observations) per school (cluster)		obs_per_cluster
	expand n_students // replace each school obs with "n_students" many copies
	by school, sort: gen id = _n // assign ids to each student to differentiate them 
	
	// generating actual intracluster correlation in the data
		// assuming total variance = 1
		local sd_u = sqrt(`rho') // u represents standard dev BETWEEN clusters
		local sd_e = sqrt(1-`rho') // e is standard dev WITHIN clusters
		
		// sampling u and e
		by school (id), sort: gen u = rnormal(0, `sd_u') if _n == 1
		by school (id): replace u = u[1] // this is measuring 'school effects', or variance BETWEEN schools. So, within a school, this is the same for all students.
		gen e = rnormal(0, `sd_e')
		* for student i, school j: Y_ij = \mu + u_j + e_ij, where \mu = 70
		gen score = round(70 + 15*(u + e)) // creating an outcome variable (standardized test score) that has a mean of 70
		replace score = 100 if score > 100 // students can not score above 100 on the exam
		replace score = 0 if score < 0 // fortunately for the students, they also cannot score below 0
		// 
		gen absences = round(rnormal(3, 3)) // # of absences
		replace absences = 0 if absences < 0
		gen disc = floor(absences/3)+round(runiform(0,3)) // # of disciplinary actions
		replace disc = 0 if disc < 0
		gen bmi = round(rnormal(20,2)) // health measure
		gen frpl = round(runiform(0,1)) // whether a students gets free/reduced-price lunch (in the absence of a universal program)
		
		* dependent variable score: independent vars absences, disc, bmi, frpl. grouping variable is school. We are not modeling the effects of any variables as random (should we?)
		mixed score absences disc bmi frpl || school:  
		// NOTE: above line was previously 	[mixed score || school:]
	
	* save coefficients as scalars -- might not need this?
		scalar b_absences = _b[absences]
		scalar b_disc = _b[disc]
		scalar b_bmi = _b[bmi]
		scalar b_frpl = _b[frpl]

		quietly estat icc // will reveal how correlated scores are within the same school, conditional on the fixed-effects covariates
		scalar icc = r(icc2) // icc in the data
	
	// estimating design effect -- a correction factor to adjust required sample size
	egen g = mean(n_students) // average # of students sampled per school
	scalar g = g
	scalar design = sqrt(1+icc*(g-1)) // design effect -- larger design effect means a larger minimal detectable effect, i.e. sample size has to be increased more
end