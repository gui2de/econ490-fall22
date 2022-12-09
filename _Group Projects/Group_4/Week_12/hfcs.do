********************************************************************************
* ECON 491
* Week 12 Assignment: HFCs
* Group 4
* December 9, 2022
********************************************************************************

set more off
clear all

global username "/Users/geenapanzitta/Documents/GitHub"
cd "${username}/econ490-fall22/_Group Projects/Group_4/Week_12"

global hfc_output "week12_hfc_output"

********************************************************************************
* DATA GENERATING PROCESS
********************************************************************************

{
	
set seed 42
set obs 2000

gen student_id = _n

*randomly picks ~1% of sample to have duplicates and ~1% to be missing
gen rand=runiform()
gen duplicate = 0
replace duplicate = 1 if rand < .01
gen missing = 0
replace missing = 1 if rand > .99
drop rand

/* for testing, to compare how the actual vs found amounts
count if missing == 1
local number_missing = r(N)

count if duplicate == 1
local number_duplicate = r(N)
*/

*for students with duplicates, randomly determines the number of duplicates
gen number_of_entries = 1
replace number_of_entries = ceil(rnormal(2,.7)) if duplicate == 1
replace number_of_entries = 2 if number_of_entries < 2 & duplicate == 1
expand (number_of_entries) if duplicate == 1

drop if missing == 1 //drops missing students

*generates random consistency variable, making ~10% of entries not internally consistent
gen rand=runiform()
gen inconsistent = 0
replace inconsistent = 1 if rand < .1
drop rand

*randomly picks ~5% of sample to spend too little time and ~5% of sample to spend too much time
gen rand=runiform()
gen timing = ""
replace timing = "under" if rand < .05
replace timing = "over" if rand > .95
drop rand

*for each question, randomly picks around 5% of entries to be blank
forv i = 1/4 {
	gen blank_`i' = 0
	gen rand = runiform()
	replace blank_`i' = 1 if rand < .05
	drop rand
}

*generates responses, dependent on each other
local numberofq 4
gen phq_q1 = trunc(runiform(0,4))
forv i=2/`numberofq' {
	egen phq_sum=rowtotal(phq_q*)
	gen phq_q`i' = trunc((1/3)*(phq_sum + runiform(0,4)))
	drop phq_sum
}

*changes responses
forv i = 1/4 { //for inconsistent entries, generates variables independent of each other
	replace phq_q`i'= trunc(runiform(0,4)) if inconsistent == 1 //for inconsistent entries, generates variables independent of each other
	replace phq_q`i' = . if blank_`i' == 1 //replaces blank questions
}

*generate duration
gen duration = rnormal(120,20) //generate normal distribution of duration
replace duration = rnormal(15,5) if timing == "under" //generate normal distribution of low duration
replace duration = 0 if duration < 0 //ensures no negative durations
replace duration = rnormal(700,100) if timing == "over" //generate normal distribution of high duration

*generate start and end times
gen double starttime = clock("2024 May 6 8:00:00", "YMDhms") //random monday in may
gen double endtime = starttime + (duration*1000) //generate endtime based on duration

*generates survey id
gen survey_id = _n

/* for testing, to compare how the actual vs found amounts

forv i = 1/4 {
	count if blank_`i' == 1
	local number_q`i'_blank = r(N)
}

count if timing == "under"
local number_timing_under = r(N)

count if timing == "over"
local number_timing_over = r(N)

count if inconsistent == 1
local number_inconsistent = r(N)

*/

*save data as it would look when collected
drop duplicate missing number_of_entries inconsistent timing duration blank*

order survey_id student_id starttime endtime

save hfc_data_pre.dta, replace

}

********************************************************************************
* HIGH FREQUENCY CHECKS
********************************************************************************

{

*find duration
gen duration = (endtime - starttime)/1000

*find duplicates
by student_id, sort: generate entry_number = _n
by student_id, sort: egen number_of_entries_found = max(entry_number)
gen duplicate_flag = 0
replace duplicate_flag = 1 if number_of_entries_found != 1

*find blank questions
gen blank_flag = 0
gen blank_all_flag = 1

forv i = 1/4 {
	gen blank_`i'_flag = 0
	replace blank_`i'_flag = 1 if phq_q`i' == .
	replace blank_flag = 1 if phq_q`i' == .
	replace blank_all_flag = 0 if phq_q`i' != .
}

*find low and high durations
gen duration_flag = ""
replace duration_flag = "too low" if duration <= 20
replace duration_flag = "too high" if duration >= 600

*find internal inconsistent entries
gen inconsistent_flag = 0 //subjective measure of consistency, dependent on total difference between answers
forv i=1/3{
	forv j=2/4{
		gen dif`i'`j'=abs(phq_q`i'-phq_q`j') if `i'<`j'	//for each combination of variables, calculate the difference between them
	}
}
egen totalsumofdiff=rowtotal(dif*) //sums all the differences
drop dif*
replace inconsistent_flag = 1 if totalsumofdiff >= 10 //10 is an arbitrary cutoff point, you can mess with the cutoff for different amount of flagged data

*find missing student ids
gen missing_flag = 0
local N = _N
forv i = 1/2000 { //run through all student ids
	local missing_`i' = 1
	forv j = 1/`N' { //run through all observations
		if student_id[`j'] == `i' { //see if observation matches student id
			local missing_`i' = 0
			break
		}
	}
	if `missing_`i'' == 1 { //if missing student id, generate obs with that id
		local new = _N + 1
		set obs `new'
		replace student_id = `i' if _n == `new'
		replace missing_flag = 1 if _n == `new'
	}
}

*save data as it would look after hfcs
drop entry_number totalsumofdiff
save hfc_data_post.dta, replace

/* for testing, to compare how the actual vs found amounts

count if missing_flag == 1
local number_missing_found = r(N)

preserve
collapse duplicate_flag, by(student_id)
count if duplicate_flag == 1
local number_duplicate_found = r(N)
restore

forv i = 1/4 {
	count if blank_`i'_flag == 1
	local number_q`i'_blank_found = r(N)
}

count if duration_flag == "too low"
local number_timing_under_found = r(N)
count if duration_flag == "too high"
local number_timing_over_found = r(N)

count if inconsistent_flag == 1
local number_inconsistent_number = r(N)
dis `number_inconsistent_number'

*/


/* for testing, compare actual vs found amounts

dis "Actual number missing: " `number_missing'

dis "Number missing found: " `number_missing_found'

dis "Actual number duplicate: " `number_duplicate'

dis "Number duplicates found: " `number_duplicate_found'

forv i = 1/4 {
	dis "Actual number q" `i' " blank: " `number_q`i'_blank'
	dis "Number q" `i' " blank found: " `number_q`i'_blank_found'
}

dis "Actual number timing under: " `number_timing_under'
dis "Number timing under found: " `number_timing_under_found'
dis "Actual number timing over: " `number_timing_over'
dis "Number timing over found: " `number_timing_over_found'
dis "Actual number inconsistent: " `number_inconsistent'
dis "Number inconsistent found: " `number_inconsistent_found'

*/

}

********************************************************************************
* OUTPUT
********************************************************************************

{
	
gen flag = ""

*produce sheet for missing and duplicate entries
preserve
	keep student_id
	collapse (sum) student_id
	gen note = "no missing or duplicates"
	keep note
	export excel using "$hfc_output.xlsx", sheet("Missing, duplicates", replace) firstrow(variables)
restore

preserve
	keep if missing_flag == 1 | duplicate_flag == 1
	replace flag = "missing" if missing_flag == 1
	replace flag = "duplicate" if duplicate_flag == 1
	keep survey_id student_id flag
	sort student_id
	count
	if `r(N)' > 0 {
		export excel using "$hfc_output.xlsx", sheet("Missing, duplicates", replace) firstrow(variables)
	}
restore

*produce sheet for blank questions (some or all)
preserve
	keep student_id
	collapse (sum) student_id
	gen note = "no blank questions"
	keep note
	export excel using "$hfc_output.xlsx", sheet("Blank questions", replace) firstrow(variables)
restore
	
preserve
	keep if blank_all_flag == 1 | blank_flag == 1
	replace flag = "all questions blank" if blank_all_flag == 1
	replace flag = "some questions blank" if blank_all_flag == 0 & blank_flag == 1
	keep survey_id student_id flag
	sort student_id
	count
	if `r(N)' > 0 {
		export excel using "$hfc_output.xlsx", sheet("Blank questions", replace) firstrow(variables)
	}
restore

*produce sheet for blank questions, by question
preserve
	keep student_id
	collapse (sum) student_id
	gen note = "no blank questions"
	keep note
	export excel using "$hfc_output.xlsx", sheet("Blank questions, detail", replace) firstrow(variables)
restore

preserve
clear
tempfile flags_temp
save `flags_temp', emptyok replace
restore

forv i = 1/4 {
	preserve
		keep if blank_`i'_flag == 1
		replace flag = "question `i' blank"
		keep survey_id student_id flag
		append using `flags_temp'
		qui save `flags_temp', replace
		sort student_id flag
		count
		if `r(N)' > 0 {
			export excel using "$hfc_output.xlsx", sheet("Blank questions, detail", replace) firstrow(variables)
		}
	restore
}

*produce sheet for duration
preserve
	keep student_id
	collapse (sum) student_id
	gen note = "no short or long durations"
	keep note
	export excel using "$hfc_output.xlsx", sheet("Duration", replace) firstrow(variables)
restore
	
preserve
	keep if duration_flag != ""
	replace flag = "duration is too low" if duration_flag == "too low"
	replace flag = "duration is too high" if duration_flag == "too high"
	keep survey_id student_id flag duration
	rename duration duration_minutes
	sort student_id
	count
	if `r(N)' > 0 {
		export excel using "$hfc_output.xlsx", sheet("Duration", replace) firstrow(variables)
	}
restore

*produce sheet for internal consistency
preserve
	keep student_id
	collapse (sum) student_id
	gen note = "no internal consistency issues"
	keep note
	export excel using "$hfc_output.xlsx", sheet("Internal consistency", replace) firstrow(variables)
restore
	
preserve
	keep if inconsistent_flag == 1
	replace flag = "internal consistency concern"
	keep survey_id student_id flag
	sort student_id
	count
	if `r(N)' > 0 {
		export excel using "$hfc_output.xlsx", sheet("Internal consistency", replace) firstrow(variables)
	}
restore

}

drop flag

********************************************************************************
* END
********************************************************************************
