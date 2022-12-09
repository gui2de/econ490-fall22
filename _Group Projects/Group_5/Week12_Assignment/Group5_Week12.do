//////////////////////////////
///*** ECON 490 WEEK 12 ***///
//////////////////////////////

*Group: 5
*Name: Noah Blake Smith
*Date: December 5, 2022

///////////////////
///*** Setup ***///
///////////////////

clear all
set seed 12345
cd "/Users/nbs/Desktop" // User should change to appropriate path
local file_name "week12_output.xlsx" // User should change to appropriate file name

///////////////////////////
///*** Simulate Data ***///
///////////////////////////

set obs 100

///*** enumerator_id ***///

gen enumerator_id = _n // Assume each enumerator surveys exactly one respondent
la var enumerator_id "Enumerator ID number"

///*** date ***///

gen date = mdy(11,5,2022)
format date %td
la var date "Date of survey"

///*** survey_start ***///

gen survey_start = 1

forval i = 2/100 { // Space out by 7 minutes
	local j = `i' - 1
	replace survey_start = 20 * 60 * survey_start + survey_start[`j'] if survey_start==survey_start[`i']
}

replace survey_start = survey_start - 1201
la var survey_start "Survey start time (seconds since 9:00 a.m. local time)"

///*** respondent_id ***///

gen respondent_id = runiformint(1,750) // Stand-in for name
la var respondent_id "Respondent ID number"

///*** respondent_phone ***///

gen respondent_phone = runiformint(1234560000,1234999999) // Random range of phone numbers
format respondent_phone %12.0g
la var respondent_phone "Respondent phone number (excl. country code)"

///*** consent_start ***///

gen consent_start = survey_start + 60
replace consent_start = round(abs(rnormal(consent_start,1))) // Normal distribution with mean 60 seconds after survey start and SD of 1
la var consent_start "Start time of consent question (seconds since 9:00 a.m. local time)"

///*** consent ***///

gen consent = runiform(0,1)
replace consent = 0 if consent<0.5
replace consent = 1 if consent>=0.5
la var consent "=1 if consented"

///*** consent_end ***///

gen consent_end = consent_start + 40
replace consent_end = round(abs(rnormal(consent_end,5))) // Normal distribution with SD of 5
la var consent_end "End time of consent question (seconds since 9:00 a.m. local time)"

///*** age ***///

gen age = .
replace age = round(abs(rnormal(30,4))) if consent==1
la var age "Age of respondent (years)"

///*** survey_end ***///

gen survey_end = consent_end + 60
replace survey_end = round(abs(rnormal(survey_end,5))) // Normal distribution with SD of 5
la var survey_end "Survey end time (seconds since 9:00 a.m. local time)"

/////////////////////////////////
///*** Check 1: Duplicates ***///
/////////////////////////////////

/* ALI FEEDBACK:
	- replace respondent_id with real first and last names, randomly mixed and matched
	- then create an identity index with name, age, sex, phone number, and GPS coordinate
	- replace check 1.1 with a checking looking for index duplicates
	- explain how to interpret output in readme file
*/

*Identify duplicates by respondent_id
duplicates tag respondent_id, gen(respondent_id_duplicates)
la var respondent_id_duplicates "# duplicates of respondent_id"

*Identify duplicates by respondent_phone
duplicates tag respondent_phone, gen(respondent_phone_duplicates)
la var respondent_phone_duplicates "# duplicates of respondent_phone"

///*** Check 1.1: Duplicates of respondent_id ***///

*Export title to Excel file
gen title = "Respondent ID Duplicates"
local title "`=title[1]'"
export excel title in 1/1 using "`file_name'", cell(A1) sheet("`title'")
drop title

*Export duplicates to Excel file
sort respondent_id
qui ds
export excel `r(varlist)' if respondent_id_duplicates!=0 using "`file_name'", sheetmodify firstrow(varlabels) cell(A2) sheet("`title'")

///*** Check 1.2: Duplicates of respondent_phone ***///

*Export title to Excel file
gen title = "Respondent Phone Duplicates"
local title "`=title[1]'"
export excel title in 1/1 using "`file_name'", cell(A1) sheet("`title'")
drop title

*Export duplicates to Excel file
sort respondent_phone
qui ds
export excel `r(varlist)' if respondent_phone_duplicates!=0 using "`file_name'", sheetmodify firstrow(varlabels) cell(A2) sheet("`title'")

////////////////////////////////////////////////
///*** Check 2: Consent Question Duration ***///
////////////////////////////////////////////////

/*ALI FEEDBACK:
	- create audio files with names corresponding to ids (leave them blank for now, but explain how field manager would do this with SurveyCTO)
	- transcribe how many words the recording is and compare to actual consent statement
*/

*Calculate consent question duration
gen consent_duration = consent_end - consent_start
la var consent_duration "Duration of consent question (seconds)"

*Generate duration flag
gen consent_duration_flag = 0
replace consent_duration_flag = 1 if consent_duration<30 // Assume it takes at least 30 seconds to read prompt
la var consent_duration_flag "=1 if consent question duration <30 seconds"

*Export title to Excel file
gen title = "Consent Question Duration Flag"
local title "`=title[1]'"
export excel title in 1/1 using "`file_name'", cell(A1) sheet("`title'")
drop title

*Export flagged observations to Excel file
sort enumerator_id
qui ds
export excel `r(varlist)' if consent_duration_flag==1 using "`file_name'", sheetmodify firstrow(varlabels) cell(A2) sheet("`title'")

//////////////////////////////////////
///*** Check 3: Survey Duration ***///
//////////////////////////////////////

/*ALI FEEDBACK:
	- this is a bad check; do something else that is more creative
*/

*Calculate survey duration
gen survey_duration = survey_end - survey_start
la var survey_duration "Total Duration of survey (seconds)"

*Generate duration flag
gen survey_duration_flag = 0
replace survey_duration_flag = 1 if survey_duration<(2.5 * 60) & consent==1 // Assume it takes at least 2.5 minutes to complete survey if respondent consented

*Export title to Excel file
gen title = "Survey Duration Flag"
local title "`=title[1]'"
export excel title in 1/1 using "`file_name'", cell(A1) sheet("`title'")
drop title

*Export flagged observations to Excel file
sort enumerator_id
qui ds
export excel `r(varlist)' if survey_duration_flag==1 using "`file_name'", sheetmodify firstrow(varlabels) cell(A2) sheet("`title'")
