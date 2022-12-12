********* HIGH FREQUENCY CHECKS ************

// Setup
global user "/Users/anton/OneDrive/Documents/Georgetown/ECON/ECON490/econ490-fall22" // CHANGE THIS LINE TO USE
cd "$user/_Group Projects/Group_3/Week_12"

clear

import delimited simulated_survey_data

cd "$user/_Group Projects/Group_3/Week_12/outputs"

// Number of refusals by enumerator
** If some enumerators are logging more refusals (per survey) than others, we want to flag this. This could indicate that (1) the enumerators are engaging with students in a way that makes them uncomfortable or unwilling to participate, or (2) the enumerators may not actually be speaking to students and are logging refusals instead of performing the surveys. 
** Rather than only tracking the number of refusals, it would be more useful to flag enumerators with high refusal RATES.

preserve
drop if enum_name == ""
bysort enum_name: egen n_refusals = sum(b_refused)
bysort enum_name: egen n_surveys = count(enum_name)
bysort enum_name: gen refusal_rate = n_refusals/n_surveys
bysort enum_name: gen n = _n
drop if n > 1
histogram refusal_rate, title("Survey refusal rates by enumerator") xtitle("Refusal rate, grouped by enumerator")
graph export refusals_by_enumerator.pdf, replace
drop if refusal_rate <= .25 // drop enumerators who successfully complete at least three quarters of interviews
sort refusal_rate
keep enum_uniqueid enum_name school_id treat n_students n_refusals refusal_rate
export delimited enumerators_with_7_or_more_refusals, replace
restore

// Number of completions by enumerator
** We want to know which enumerators have been the most successful at completing surveys as well as the enumerators that have been the least successful. If enumerators have not been completing many surveys, perhaps they could use a reminder about how they should proceed, be nudged to start conducting surveys, or checked in on to see what the cause of delays are. If enumerators are completing many more surveys than others, it might be worth checking in on them to discuss their next steps and ensure surveys have been properly conducted.

preserve
drop if enum_name == ""
bysort enum_name: egen n_completed = sum(b_complete)
bysort enum_name: gen n = _n
drop if n > 1
histogram n_completed, title("Count of completed surveys by enumerator") xtitle("Number of Completions, grouped by enumerator")
graph export completions_by_enumerator.pdf, replace
sort n_completed
keep enum_uniqueid enum_name school_id treat n_students n_completed
tempfile comp
save `comp'
drop if n_completed > 5
export delimited enumerators_with_less_than_6_completions, replace
use `comp', clear
drop if n_completed <= 24
export delimited enumerators_with_more_than_24_completions, replace
restore

// Survey length by enumerator
** We want to know which enumerators are completing the surveys the quickest (and thus may be rushing through the process and producing poor data) as well as the enumerators who are completing the surveys the slowest (and thus may be wasting time, working inefficiently, or completing unnecessary checks). These enumerators can be contacted to make sure they are properly following scripts and are not having any issues interacting with students.

preserve
drop if enum_name == ""
bysort enum_name: egen mean_length = mean(b_survey_mins_elapsed)
bysort enum_name: gen n = _n
drop if n > 1
histogram mean_length, title("Mean length of survey by enumerator") xtitle("Mean length of survey in minutes, grouped by enumerator")
graph export survey_length_by_enumerator.pdf, replace
sort mean_length
keep enum_uniqueid enum_name school_id treat n_students mean_length
tempfile length
save `length'
drop if mean_length > 15
export delimited enumerators_with_mean_survey_under_15_mins, replace
use `length', clear
drop if mean_length < 22
export delimited enumerators_with_mean_survey_over_22_mins, replace
restore

// Checking for falsely reported test scores
** These standardized tests are on a scale from 0 to 100, so scores outside this range indicates misreporting

preserve
drop if b_complete == 0
sort b_score
histogram b_score, title("Student test scores at baseline") xtitle("Standardized test score, as reported by enumerator")
graph export test_scores_baseline.pdf, replace

keep if b_score > 100 | b_score < 0
keep enum_uniqueid enum_name school_id treat stud_uniqueid b_score
export delimited suspicious_test_scores, replace
restore

// Checking for bmi values misentered
** When inputting values, enumerators may neglect to enter a decimal place. This could cause bmi values to be in the triple digits or more, which is not possible. These observations would be flagged so that enumerators can either recalculate the student's BMI or input the decimal place after the first two digits.

preserve
drop if b_complete == 0
sort b_bmi
histogram b_bmi, title("Student BMIs at baseline") xtitle("Student BMI, as calculated by enumerator")
graph export student_bmi_baseline.pdf, replace
keep if b_bmi >= 100
keep enum_uniqueid enum_name school_id treat stud_uniqueid b_bmi
export delimited miscalculated_bmi, replace
restore