********* SIMULATED SCHOOL LUNCH RCT BASELINE DATA ************
** SCENARIO: Our group's RCT on universal free lunch is halfway through baseline data collection. We are working with 100 elementary schools, which have a mean of 75 fourth grade students (our study subjects). We have recruited 300 certified nurses assistants to serve as our enumerators for the project. Each school will be assigned three CNAs to perform the baseline surveys and health assessments.
** Before performing each baseline survey, the enumerators will access administrative records to note the student's free/reduced-price lunch eligibility and third grade standardized test score. During the baseline survey, the enumerators will perform a basic health exam on the student, measuring their BMI and assigning the student an overall health score on a scale from 1 to 5 (very poor, poor, fair, good, excellent). During the health exam, the enumerator will also ask the student questions about their social experiences at school and their use of the free/reduced-price lunch program if they are eligible.

clear

// Set up globals
global user "/Users/anton/OneDrive/Documents/Georgetown/ECON/ECON490/econ490-fall22" // CHANGE THIS LINE TO USE
cd "$user/_Group Projects/Group_3/Week_12/"

// Create a tempfile of enumerator names
tempfile enumerators
set seed 10063963 // random
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
gen stud_uniqueid = "00"+school_id+"00"+stud_id if strlen(school_id)==1 & strlen(stud_id)==1
replace stud_uniqueid = "0"+school_id+"00"+stud_id if strlen(school_id)==2 & strlen(stud_id)==1
replace stud_uniqueid = "00"+school_id+"0"+stud_id if strlen(school_id)==1 & strlen(stud_id)==2
replace stud_uniqueid = "0"+school_id+"0"+stud_id if strlen(school_id)==2 & strlen(stud_id)==2
replace stud_uniqueid = school_id+"0"+stud_id if strlen(school_id)==3 & strlen(stud_id)==2
replace stud_uniqueid = "0"+school_id+stud_id if strlen(school_id)==2 & strlen(stud_id)==3
// now all id's are 6 digits long

// Assign enumerators to observations
gen b_complete = rbinomial(1, 0.5) // we are 50% through the baseline data collection, so each student has a 50% chance of having completed a survey
gen b_refused = .
replace b_refused = rbinomial(1, .15) if b_complete == 0 // whether or not a student has refused the survey
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
gen b_survey_mins_elapsed = rnormal(20, 7) if b_complete == 1 // length of survey in minutes
gen b_score = round(rnormal(75, 10)) if b_complete == 1 // baseline test score, as copied from administrative record by enumerator
gen b_frpl = rbinomial(1, 0.3) if b_complete == 1 // whether student is eligible for free lunch, as copied from administrative record by enumerator
gen b_frpl_use = rbinomial(1, 0.75) if b_complete == 1 & b_frpl == 1 // whether student uses free lunch, as reported by student
gen b_sex = 1+rbinomial(1, .5) if b_complete == 1 // where 1 is female and 2 is male

gen b_bmi = rnormal(18.2, 1.6) if b_complete == 1 // student bmi, as reported by enumerator after physical exam
generate b_bmi_str = string(b_bmi)
replace b_bmi_str = subinstr(b_bmi_str, ".", "", 1) if stud_uniqueid == "008044" | stud_uniqueid == "091065" | stud_uniqueid == "061005"
drop b_bmi
gen b_bmi = real(b_bmi_str)
drop b_bmi_str

gen b_happiness = round(runiform(1, 5)) if b_complete == 1 // student's reported happiness at school (1 being the least happy and 5 being the most happy)
gen b_comfort = round(runiform(1, 5)) if b_complete == 1 // student's reported comfortability at school (1 being the least comfortable and 5 being the most comfortable)
gen b_healthyreport = round(runiform(1, 5)) if b_complete == 1 // health score assigned to student after physical exam by enumerator

// Export as a csv
export delimited simulated_survey_data, replace
