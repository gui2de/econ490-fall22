///////////////////////////////
///*** WEEK 8 SIMULATION ***///
///////////////////////////////

*Group 5: Noah Blake Smith, Miglé Petrauskaité, and Benjamin Tu

*Date: October 30, 2022

/*
Description:

Each row is a child who applied to the DC charter lottery.
*/

clear all

cap program drop charter_simulation

program define charter_simulation, rclass // Define r-class program

set obs 5000 // Approximate number of children who apply to PK3 lottery

*Unique ID
gen kid_id = .
replace kid_id = _n
la var kid_id "Unique child ID"

*Child IQ
gen iq = rnormal(100,15) // Mean of 100 and SD of 15, per the scaling of the Wechsler Intelligence Scale for Children
la var iq "Child IQ"

*Charter ID
gen charter_id = runiformint(1,135) // Assume each child randomly applies to 1 of DC's 135 charters
la var charter_id "Unique charter ID"

*School capacity
gen capacity = 30 // Size of each school's PK3 class

*Public quality
gen public_quality = rnormal(100,15)  // Arbitrary score assessing public quality with mean of 100 and SD of 15
la var public_quality "Quality score of public school"

*Charter quality
gen charter_quality = rnormal(115,15) // Arbitrary score assessing charter quality, where mean is one SD above that of public quality distribution; we make this assumption because our literature review shows charters tend to produce higher test scores
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
replace ts_charter = iq^0.5 * charter_quality^0.5 if admitted==1 // Cobb-Douglas education production function, where a = 0.5; we chose the number based on the education production function used by Polachek, Kniesner, and Harwood (1978) in the Journal of Educational Statistics
la var ts_charter "Child's test score if he/she attends charter"

*Test score at public school
gen ts_public = .
replace ts_public = iq^0.5 * public_quality^0.5 // Cobb-Douglas education production function, where a = 0.5; see justification for number above
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

*Calculate statistical property

reg ts_actual attend (admitted), r  // IV regression, where admitted is the instrument, attend is the endogenous variable, and ts_actual is our dependent variable; note full sample of data is used here
gen beta_hat = r(table)[1,1] // Extracts coefficient from regression
la var beta_hat "Mean predicted change in child's test score from attending charter, relative to if child had attended public" // The latter is a hypothetical score we generated but do NOT utilize here

gen beta = ts_actual - ts_public if attend==1 // Note only subsample of charter attendees is used
qui sum beta
replace beta = r(mean)
la var beta "Mean actual change in child's test score from attending charter, relative to if child had attended public" // The latter is a hypothetical score that we DO utilize here

local beta = beta // Store beta variable as local; note all same value
local beta_hat = beta_hat // Store beta_hat variable as local; note all same value

return scalar beta = `beta' // Return scalar beta, per requirements of rclass program
return scalar beta_hat = `beta_hat' // Return scalar beta_hat, per requirements of rclass program

end
