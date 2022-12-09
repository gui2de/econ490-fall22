********* HIGH FREQUENCY CHECKS ************

// Setup
global user "Users/abigailorbe/Documents/repos/econ490-fall22"
cd "$user/_Group Projects/Group_3/Week_12/outputs"

// Number of refusals by enumerator
** If some enumerators are logging more refusals than others, we want to flag this. This could indicate that (1) the enumerators are engaging with students in a way that makes them uncomfortable or unwilling to participate, or (2) the enumerators may not actually be speaking to students and are logging refusals instead of performing the surveys

preserve
drop if enum_name == ""
bysort enum_name: egen n_refusals = sum(b_refused)
bysort enum_name: gen n = _n
drop if n > 1
histogram n_refusals, title("Count of survey refusals by enumerator") xtitle("Number of Refusals, grouped by enumerator")
graph export refusals_by_enumerator.pdf
drop if n_refusals < 7
sort n_refusals
keep enum_uniqueid enum_name school_id treat n_students n_refusals
export delimited enumerators_with_7_or_more_refusals, replace
restore

// Number of completions by enumerator
** We want to know which enumerators have been the most successful at completing surveys as well as the enumerators that have been the least successful

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
drop if n_completed < 24
export delimited enumerators_with_more_than_24_completions, replace
restore

// Survey length by enumerator
** We want to know which enumerators are completing the surveys the quickest (and thus may be rushing through the process and producing poor data) as well as the enumerators who are completing the surveys the slowest (and thus may be wasting time, working inefficiently, or completing unnecessary checks)

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
drop if mean_length > 26
export delimited enumerators_with_mean_survey_under_26_mins, replace
use `length', clear
drop if mean_length < 33
export delimited enumerators_with_mean_survey_over_33_mins, replace
restore

// Checking for falsely reported test scores
** These standardized tests are on a scale from 0 to 100, so scores outside this range indicates misreporting

preserve
drop if b_complete == 0
sort b_score
histogram b_score, title("Student test scores at baseline") xtitle("Standardized test score, as reported by enumerator")
keep if b_score > 100 | b_score < 0
keep enum_uniqueid enum_name school_id treat stud_uniqueid b_score
export delimited suspicious_test_scores, replace
restore
