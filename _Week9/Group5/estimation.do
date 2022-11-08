///////////////////////////////
///*** WEEK 9 SIMULATION ***///
///////////////////////////////

*Group 5: Noah Blake Smith, Miglé Petrauskaité, and Benjamin Tu

*Date: November 6, 2022

/*
Description:

Each row is a child who applied to the DC charter lottery.
*/

clear all

cap program drop charter_simulation

program define charter_simulation, rclass // Define r-class program

syntax, [Biased] // Includes a biased option, which can be abbreviated as b

set obs 5000 // Approximate number of children who apply to PK3 lottery

*Unique ID
gen kid_id = .
replace kid_id = _n
la var kid_id "Unique child ID"

*Child ability
gen ability = rnormal(100,15) // Mean of 100 and SD of 15, per the scaling of the Wechsler Intelligence Scale for Children (although, per Ben's comments, IQ is a problematic measure of ability)
la var ability "Child ability"

*Charter ID
gen charter_id = runiformint(1,135) // Assume each child randomly applies to 1 of DC's 135 charters
la var charter_id "Unique charter ID"

*School capacity
gen capacity = 30 // Size of each school's PK3 class

*Public quality
gen public_quality = rnormal(100,15)  // Arbitrary score assessing public quality with mean of 100 and SD of 15
la var public_quality "Quality score of public school"

*Charter quality
gen charter_quality = rnormal(105,15) // Arbitrary score assessing charter quality, where mean is 1/3 of SD above that of public quality distribution; we make this assumption because our literature review shows charters tend to produce higher test scores
la var charter_quality "Quality score of charter school"

*Applicants
gen applicants = .
forval i = 1/5000 { // Loop through each row
	count if charter_id==`i' // Count the number of kids applying to charter in current row
	replace applicants = r(N) if charter_id==`i' // Replace applicants with the number of kids applying to same charter
}
la var applicants "Total applicants to same charter"

*Oversubscribed
gen oversubscribed = . // Charter is oversubscribed if applicants exceeds school capacity
replace oversubscribed = 1 if applicants>capacity
replace oversubscribed = 0 if applicants<=capacity
la var oversubscribed "=1 if applicants > capacity"

*Random lottery mechanism
gen tempvar = .
replace tempvar = rnormal() if oversubscribed==1 // Randomly assign number to each kid who applied to oversubscribed school
gen lottery_rank = .
la var lottery_rank "Random lottery ranking for oversubscribed charters"
bysort charter_id (tempvar): replace lottery_rank = _n // Sort tempvar in ascending order for applicants to oversubscribed schools, and then fill in lottery rank
drop tempvar // Temporary variable no longer needed

*Admitted to charter
gen admitted = .
replace admitted = 1 if lottery_rank<=capacity // =1 when child's lottery rank is less than school capacity
replace admitted = 1 if oversubscribed==0 // =1 when no lottery occured
replace admitted = 0 if oversubscribed==1 & lottery_rank>capacity // =0 for lottery losers
la var admitted "=1 if child was admitted to charter"

*Test score at charter school
gen ts_charter = .
replace ts_charter = ability^0.5 * charter_quality^0.5 // Cobb-Douglas education production function, where a = 0.5; we chose the number based on the education production function used by Polachek, Kniesner, and Harwood (1978) in the Journal of Educational Statistics
la var ts_charter "Child's test score if he/she attends charter"

*Test score at public school
gen ts_public = .
replace ts_public = ability^0.5 * public_quality^0.5 // Cobb-Douglas education production function, where a = 0.5; see justification for number above
la var ts_public "Child's test score if he/she attends public school"

*School attended
gen attend = .
replace attend = 1 if admitted==1 & ts_charter>=ts_public // =1 if child was admitted to charter and would achieve higher test score attending charter; recall hypothetical test score at charter was generated above using Cobb-Douglas education production function
replace attend = 0 if admitted==0 | ts_charter<ts_public // =0 if child lost charter lottery or would achieve higher test score attending public
la var attend "=1 if child attends charter"

*Actual test score
gen ts_actual = .
replace ts_actual = ts_charter if attend==1 // Actual test score is the hypothetical test score at charter if child attends charter
replace ts_actual = ts_public if attend==0 // Actual test score is hypothetical test score at public if child attends public
la var ts_actual "Child's actual test score"

*Open spots
egen open_spots = sum(attend), by(charter_id) // Number of students attending each charter
replace open_spots = capacity - open_spots // Open spots at each charter
la var open_spots "Open spots available at charter"

*Waitlist
egen waitlist = count(attend) if attend==0 & ts_charter>=ts_public, by(charter_id) // Waitlist is defined as lottery losers who still want to attend charters (i.e., higher test scores attending charters than public)

*Waitlist admission (no lottery)
replace attend = 1 if open_spots>=waitlist // When there are more spots than waitlisted students, all are granted admission

*Update waitlist
drop waitlist // Drop previous variable
egen waitlist = count(attend) if attend==0 & ts_charter>=ts_public, by(charter_id) // Regenerate new waitlist size after no-lottery waitlist admissions round

*Update open spots
drop open_spots // Drop previous variable
egen open_spots = sum(attend), by(charter_id) // Regenerate new number of attending students after no-lottery waitlist admissions round
replace open_spots = capacity - open_spots // Convert to open spots

*Waitlist admission (random lottery)
gen tempvar = .
replace tempvar = rnormal() if attend==0 & waitlist>0 & open_spots>0 // Randomly assign tempvar to lottery losers on waitlist for charters with open spots
gen waitlist_rank = .
la var waitlist_rank "Randomly generated waitlist rank"
bysort charter_id (tempvar): replace waitlist_rank = _n if attend==0 & waitlist>0 & open_spots>0 // Sort tempvar in ascending order for waitlisted students, and then fill in waitlist rank
drop tempvar // Temporary variable no longer needed
replace attend = 1 if waitlist_rank<=open_spots & attend==0 & waitlist>0 & open_spots>0 // Lottery losers on waitlists whose ranks are lower than open spots available attend charters
drop waitlist open_spots // No longer needed

*Update open spots
egen open_spots = sum(attend), by(charter_id) // Regenerate new number of attending students after no-lottery waitlist admissions round
replace open_spots = capacity - open_spots // Convert to open spots

///*** TRUE EFFECT ***///

*Estimate true ATE
gen ite = ts_charter - ts_public
la var ite "True individual treatment effect" // Econometrically, this is the individual treatment effect on each child's attending charter
egen ate_true = mean(ite) // Note mean of ITE is equal to mean(ts_charter) - mean(ts_private)--that is, the mean of the differences equals the difference in means (see this proof on StackExchange: https://stats.stackexchange.com/questions/148868/difference-in-means-vs-mean-difference)

*Output
local ate_true = ate_true // Store ate_true variable as local
return scalar ate_true = `ate_true' // Return scalar ate_true, per requirements of r-class program

///*** BIASED EFFECT ***///

if "`biased'"!="" { // If the biased option is not empty, i.e., is specified
	
	*Biased effect of attending charters
	
	reg ts_actual attend (admitted), r  // IV regression, where admitted is the instrument, attend is the endogenous variable, and ts_actual is our dependent variable; note full sample of data is used here
	gen ate_biased = r(table)[1,1] // Extracts coefficient from regression
	la var ate_biased "Biased average treatment effect of charter attendance on test scores" // Econometrically, this is the effect on compliers amongst the treated
	
	*95% confidence intervals
	
	gen ate_biased_c0 = r(table)[5,1]
	la var ate_biased_c0 "Minimum of biased ATE 95% CI"

	gen ate_biased_c1 = r(table)[6,1]
	la var ate_biased_c1 "Maximum of biased ATE 95% CI"
	
	*Outputs
	
	local ate_biased = ate_biased // Store ate_biased variable as local
	return scalar ate_biased = `ate_biased' // Return scalar ate_biased, per requirements of r-class program
	
	local ate_biased_c0 = ate_biased_c0 // Store ate_biased_c0 variable as local
	return scalar ate_biased_c0 = ate_biased_c0 // Return scalar ate_biased_c0, per requirements of r-class program
	
	local ate_biased_c1 = ate_biased_c1 // Store ate_biased_c1 variable as local
	return scalar ate_biased_c1 = ate_biased_c1 // Return scalar ate_biased_c1, per requirements of r-class program

}

///*** IMPORTANT STATISTICS ***///

sum ts_public
local ts_public_sd = `r(sd)'
return scalar ts_public_sd = `ts_public_sd'
local ts_public_mean = `r(mean)'
return scalar ts_public_mean = `ts_public_mean'

sum ts_charter
local ts_charter_sd = `r(sd)'
return scalar ts_charter_sd = `ts_charter_sd'
local ts_charter_mean = `r(mean)'
return scalar ts_charter_mean = `ts_charter_mean'

pwcorr ts_charter ts_public
local rho = `r(rho)'
return scalar rho = `rho'

end
