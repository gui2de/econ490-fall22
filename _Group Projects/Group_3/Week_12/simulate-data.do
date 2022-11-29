********* SIMULATED SCHOOL LUNCH RCT BASELINE DATA ************
** SCENARIO: Our group's RCT on universal free lunch is halfway through baseline data collection. We are working with 100 elementary schools, each of which have an mean of 75 fourth grade students, our study subjects. We have recruited 300 certified nurses assistants to serve as our enumerators for the project. Each school will be assigned three CNAs to perform the baseline surveys and health assessments. Before performing each baseline survey, the enumerators will access administrative records to note the student's free/reduced-price lunch eligibility and third grade standardized test score. During the baseline survey, the enumerators will perform a basic health exam on the student, measuring their BMI and assigning the student an overall health score on a scale from 1 to 5 (very poor, poor, fair, good, excellent). During the health exam, the enumerator will also ask the student questions about their social experiences at school and their use of the free/reduced-price lunch program if they are eligible.

// Set up globals
global user "Users/abigailorbe/Documents/repos/econ490-fall22"
cd "$user/_Group Projects/Group_3/Week_12/"

// Create a tempfile of enumerator names
tempfile enumerators
set seed 10063963
clear
set obs 100 // 100 schools
gen school_id = _n
tostring school_id, replace
expand 3 // 3 CNAs per school
by school_id, sort: gen enum_id = _n
tostring enum_id, replace
gen enum_uniqueid = school_id+"-"+enum_id // create a unique id for each enumerator
gen enum_name = char(runiformint(65,90)) + char(runiformint(65,90)) + char(runiformint(65,90)) + char(runiformint(65,90)) // generate a name for each enumerator
// to check that no two enumerators have the same name: distinct name 
save `enumerators'

clear
set seed 10063963
set obs 100 // 100 schools
gen school_id = _n
tostring school_id, replace
gen treat = rbinomial(1, 0.5) // 50% of schools are assigned to treatment group
gen n_students = round(75 + 10*rnormal()) // randomizing number of fourth graders per school with a mean of 75
expand n_students // replace each school obs with "n_students" many copies
by school_id, sort: gen stud_id = _n // assign ids to each student
tostring stud_id, replace
gen stud_uniqueid = "00"+school_id+"00"+stud_id // create a unique id for each student

// Assign enumerators to observations
gen b_complete = rbinomial(1, 0.5) // we are 50% through the baseline data collection, so each student has a 50% chance of having completed a survey
gen b_refused = .
replace b_refused = rbinomial(1, .25) if b_complete == 0 // whether or not a student has refused the survey
replace b_refused = . if b_refused == 0
gen b_enum = .
replace b_enum = round(runiform(1, 3)) if b_complete == 1 | b_refused == 1 // each student that has been contacted (refused a survey or completed a survey) was contacted by an enumerator
tostring b_enum, replace
gen enum_uniqueid = ""
replace enum_uniqueid = school_id+"-"+b_enum if b_complete == 1 | b_refused == 1 

merge m:1 enum_uniqueid using `enumerators' // match up the ids of enumerators that have completed surveys / contacted students with the names we previously generated
drop _merge enum_id b_enum stud_id
sort school_id stud_uniqueid

// Generate survey results
gen b_survey_mins_elapsed = rnormal(30, 5) if b_complete == 1 // length of survey in minutes
gen b_score = round(rnormal(75, 10)) if b_complete == 1 // baseline test score, as copied from administrative record by enumerator
gen b_frpl = rbinomial(1, 0.3) if b_complete == 1 // whether student is eligible for free lunch, as copied from administrative record by enumerator
gen b_frpl_use = rbinomial(1, 0.75) if b_complete == 1 & b_frpl == 1 // whether student uses free lunch, as reported by student
gen b_sex = runiform(1, 2) if b_complete == 1 // where 1 is female and 2 is male
gen b_bmi = rnormal(16.5, 1.3) if b_complete == 1 // student bmi, as reported by enumerator after physical exam
gen b_happiness = runiform(1, 5) if b_complete == 1 // student's reported happiness at school (1 being the least happy and 5 being the most happy)
gen b_comfort = runiform(1, 5) if b_complete == 1 // student's reported comfortability at school (1 being the least comfortable and 5 being the most comfortable)
gen b_healthyreport = runiform(1, 5) if b_complete == 1 // health score assigned to student after physical exam by enumerator

// Export as a csv
export delimited simulated_survey_data, replace
