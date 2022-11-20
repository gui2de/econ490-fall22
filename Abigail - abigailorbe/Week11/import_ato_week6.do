* import_ato_week6.do
*
* 	Imports and aggregates "ATO Week6" (ID: ato_week6) data.
*
*	Inputs:  "/Users/abigailorbe/Documents/repos/econ490-fall22/Abigail - abigailorbe/Week 11/ATO Week6_WIDE.csv"
*	Outputs: "/Users/abigailorbe/Documents/repos/econ490-fall22/Abigail - abigailorbe/Week 11/ATO Week6.dta"
*
*	Output by SurveyCTO November 20, 2022 10:24 PM.

* initialize Stata
clear all
set more off
set mem 100m

* initialize workflow-specific parameters
*	Set overwrite_old_data to 1 if you use the review and correction
*	workflow and allow un-approving of submissions. If you do this,
*	incoming data will overwrite old data, so you won't want to make
*	changes to data in your local .dta file (such changes can be
*	overwritten with each new import).
local overwrite_old_data 0

* initialize form-specific parameters
local csvfile "/Users/abigailorbe/Documents/repos/econ490-fall22/Abigail - abigailorbe/Week 11/ATO Week6_WIDE.csv"
local dtafile "/Users/abigailorbe/Documents/repos/econ490-fall22/Abigail - abigailorbe/Week 11/ATO Week6.dta"
local corrfile "/Users/abigailorbe/Documents/repos/econ490-fall22/Abigail - abigailorbe/Week 11/ATO Week6_corrections.csv"
local note_fields1 ""
local text_fields1 "deviceid subscriberid simid devicephonenum username duration caseid name users num_calls pub_to_users call_nums now_complete survey_status livestate hsstate collegestate attendstate1 state_grades_1"
local text_fields2 "statesplit_test_count attendstate_* state_grades_* randomizer community_involved community_considered inv_schoolboard inv_pta inv_schoolvol inv_otherschool inv_localgov inv_neighborhood"
local text_fields3 "inv_commservice inv_youthsports inv_church inv_otherlocal inv_stategov inv_stateadv inv_fedgov inv_fedadv inv_none invtype_schoolboard invtype_pta invtype_otherschool invtype_localgov"
local text_fields4 "invtype_neighborhood invtype_commservice invtype_youthsports invtype_church invtype_otherlocal invtype_stategov invtype_stateadv invtype_fedgov invtype_fedadv race instanceid"
local date_fields1 ""
local datetime_fields1 "submissiondate starttime endtime"

disp
disp "Starting import of: `csvfile'"
disp

* import data from primary .csv file
insheet using "`csvfile'", names clear

* drop extra table-list columns
cap drop reserved_name_for_field_*
cap drop generated_table_list_lab*

* continue only if there's at least one row of data to import
if _N>0 {
	* drop note fields (since they don't contain any real data)
	forvalues i = 1/100 {
		if "`note_fields`i''" ~= "" {
			drop `note_fields`i''
		}
	}
	
	* format date and date/time fields
	forvalues i = 1/100 {
		if "`datetime_fields`i''" ~= "" {
			foreach dtvarlist in `datetime_fields`i'' {
				cap unab dtvarlist : `dtvarlist'
				if _rc==0 {
					foreach dtvar in `dtvarlist' {
						tempvar tempdtvar
						rename `dtvar' `tempdtvar'
						gen double `dtvar'=.
						cap replace `dtvar'=clock(`tempdtvar',"MDYhms",2025)
						* automatically try without seconds, just in case
						cap replace `dtvar'=clock(`tempdtvar',"MDYhm",2025) if `dtvar'==. & `tempdtvar'~=""
						format %tc `dtvar'
						drop `tempdtvar'
					}
				}
			}
		}
		if "`date_fields`i''" ~= "" {
			foreach dtvarlist in `date_fields`i'' {
				cap unab dtvarlist : `dtvarlist'
				if _rc==0 {
					foreach dtvar in `dtvarlist' {
						tempvar tempdtvar
						rename `dtvar' `tempdtvar'
						gen double `dtvar'=.
						cap replace `dtvar'=date(`tempdtvar',"MDY",2025)
						format %td `dtvar'
						drop `tempdtvar'
					}
				}
			}
		}
	}

	* ensure that text fields are always imported as strings (with "" for missing values)
	* (note that we treat "calculate" fields as text; you can destring later if you wish)
	tempvar ismissingvar
	quietly: gen `ismissingvar'=.
	forvalues i = 1/100 {
		if "`text_fields`i''" ~= "" {
			foreach svarlist in `text_fields`i'' {
				cap unab svarlist : `svarlist'
				if _rc==0 {
					foreach stringvar in `svarlist' {
						quietly: replace `ismissingvar'=.
						quietly: cap replace `ismissingvar'=1 if `stringvar'==.
						cap tostring `stringvar', format(%100.0g) replace
						cap replace `stringvar'="" if `ismissingvar'==1
					}
				}
			}
		}
	}
	quietly: drop `ismissingvar'


	* consolidate unique ID into "key" variable
	replace key=instanceid if key==""
	drop instanceid


	* label variables
	label variable key "Unique submission ID"
	cap label variable submissiondate "Date/time submitted"
	cap label variable formdef_version "Form version used on device"
	cap label variable review_status "Review status"
	cap label variable review_comments "Comments made during review"
	cap label variable review_corrections "Corrections made during review"


	label variable contact "ENUMERATOR: Is the participant able to complete the survey at this time?"
	note contact: "ENUMERATOR: Is the participant able to complete the survey at this time?"
	label define contact 1 "Yes, willing and able to respond right now" 2 "Yes, but need to reschedule at a later date" 3 "No, I haven't been able to make contact with them yet" 4 "No, they refused to respond to this follow up survey"
	label values contact contact

	label variable consent "Participant consented"
	note consent: "Participant consented"
	label define consent 1 "Yes" 0 "No"
	label values consent consent

	label variable attainment "Highest level of education completed"
	note attainment: "Highest level of education completed"
	label define attainment 0 "Did not complete high school" 1 "High school diploma or equivalent" 2 "Some college, no degree" 3 "Associate's degree, certification, or equivalent" 4 "Bachelor's degree" 5 "Advanced degree"
	label values attainment attainment

	label variable foreigned "Completed schooling outside the U.S."
	note foreigned: "Completed schooling outside the U.S."
	label define foreigned 1 "Yes" 0 "No"
	label values foreigned foreigned

	label variable gradyear "Year of high school graduation"
	note gradyear: "Year of high school graduation"

	label variable livestate "State of current residence"
	note livestate: "State of current residence"

	label variable hsstate "State of high school graduation"
	note hsstate: "State of high school graduation"

	label variable collegestate "State of college attendance"
	note collegestate: "State of college attendance"

	label variable samestate "Complete all K-12 education in same state"
	note samestate: "Complete all K-12 education in same state"
	label define samestate 1 "Yes" 0 "No"
	label values samestate samestate

	label variable numattendstate "Number of states their K-12 education was split between"
	note numattendstate: "Number of states their K-12 education was split between"

	label variable attendstate1 "First state where they attended K-12 school"
	note attendstate1: "First state where they attended K-12 school"

	label variable state_grades_1 "Grades attended in \${attendstate}"
	note state_grades_1: "Grades attended in \${attendstate}"

	label variable value_label "How important do you find it to keep up-to-date with..."
	note value_label: "How important do you find it to keep up-to-date with..."
	label define value_label 1 "Not at all important" 2 "Minimally important" 3 "Somewhat important" 4 "Very important"
	label values value_label value_label

	label variable value_localed "Importance of staying informed on local education policy"
	note value_localed: "Importance of staying informed on local education policy"
	label define value_localed 1 "Not at all important" 2 "Minimally important" 3 "Somewhat important" 4 "Very important"
	label values value_localed value_localed

	label variable value_stateed "Importance of staying informed on state education policy"
	note value_stateed: "Importance of staying informed on state education policy"
	label define value_stateed 1 "Not at all important" 2 "Minimally important" 3 "Somewhat important" 4 "Very important"
	label values value_stateed value_stateed

	label variable value_feded "Importance of staying informed on federal education policy"
	note value_feded: "Importance of staying informed on federal education policy"
	label define value_feded 1 "Not at all important" 2 "Minimally important" 3 "Somewhat important" 4 "Very important"
	label values value_feded value_feded

	label variable support_civics "How many do you support: dummies + civics courses"
	note support_civics: "How many do you support: dummies + civics courses"

	label variable support_dummy "How many do you support: dummies"
	note support_dummy: "How many do you support: dummies"

	label variable support_commservice "How many do you support: dummies + community service requirement"
	note support_commservice: "How many do you support: dummies + community service requirement"

	label variable community_involved "Current community involvements"
	note community_involved: "Current community involvements"

	label variable community_considered "Future community involvements"
	note community_considered: "Future community involvements"

	label variable invtype_schoolboard "How you've been involved: School board"
	note invtype_schoolboard: "How you've been involved: School board"

	label variable invtype_pta "How you've been involved: PTA"
	note invtype_pta: "How you've been involved: PTA"

	label variable invtype_otherschool "How you've been involved: Other school org"
	note invtype_otherschool: "How you've been involved: Other school org"

	label variable invtype_localgov "How you've been involved: Local government"
	note invtype_localgov: "How you've been involved: Local government"

	label variable invtype_neighborhood "How you've been involved: Neighborhood council"
	note invtype_neighborhood: "How you've been involved: Neighborhood council"

	label variable invtype_commservice "How you've been involved: Community service"
	note invtype_commservice: "How you've been involved: Community service"

	label variable invtype_youthsports "How you've been involved: Youth sports"
	note invtype_youthsports: "How you've been involved: Youth sports"

	label variable invtype_church "How you've been involved: Church group"
	note invtype_church: "How you've been involved: Church group"

	label variable invtype_otherlocal "How you've been involved: Other local org"
	note invtype_otherlocal: "How you've been involved: Other local org"

	label variable invtype_stategov "How you've been involved: State government"
	note invtype_stategov: "How you've been involved: State government"

	label variable invtype_stateadv "How you've been involved: State-wide advocacy"
	note invtype_stateadv: "How you've been involved: State-wide advocacy"

	label variable invtype_fedgov "How you've been involved: Federal government"
	note invtype_fedgov: "How you've been involved: Federal government"

	label variable invtype_fedadv "How you've been involved: Nationwide advocacy"
	note invtype_fedadv: "How you've been involved: Nationwide advocacy"

	label variable time_schoolboard "Time spent in last 30 days on: School board"
	note time_schoolboard: "Time spent in last 30 days on: School board"

	label variable time_pta "Time spent in last 30 days on: PTA"
	note time_pta: "Time spent in last 30 days on: PTA"

	label variable time_schoolvol "Time spent in last 30 days on: Volunteering in school"
	note time_schoolvol: "Time spent in last 30 days on: Volunteering in school"

	label variable time_otherschool "Time spent in last 30 days on: Other school org"
	note time_otherschool: "Time spent in last 30 days on: Other school org"

	label variable time_localgov "Time spent in last 30 days on: Local government"
	note time_localgov: "Time spent in last 30 days on: Local government"

	label variable time_neighborhood "Time spent in last 30 days on: Neighborhood council"
	note time_neighborhood: "Time spent in last 30 days on: Neighborhood council"

	label variable time_commservice "Time spent in last 30 days on: Community service"
	note time_commservice: "Time spent in last 30 days on: Community service"

	label variable time_youthsports "Time spent in last 30 days on: Youth sports"
	note time_youthsports: "Time spent in last 30 days on: Youth sports"

	label variable time_church "Time spent in last 30 days on: Church group"
	note time_church: "Time spent in last 30 days on: Church group"

	label variable time_otherlocal "Time spent in last 30 days on: Other local org"
	note time_otherlocal: "Time spent in last 30 days on: Other local org"

	label variable time_stategov "Time spent in last 30 days on: State government"
	note time_stategov: "Time spent in last 30 days on: State government"

	label variable time_stateadv "Time spent in last 30 days on: State-wide advocacy"
	note time_stateadv: "Time spent in last 30 days on: State-wide advocacy"

	label variable time_fedgov "Time spent in last 30 days on: Federal government"
	note time_fedgov: "Time spent in last 30 days on: Federal government"

	label variable time_fedadv "Time spent in last 30 days on: Nationwide advocacy"
	note time_fedadv: "Time spent in last 30 days on: Nationwide advocacy"

	label variable gender "Gender identity"
	note gender: "Gender identity"
	label define gender 1 "Cisgender man" 2 "Cisgender woman" 3 "Transgender man" 4 "Transgender woman" 5 "Non-binary" 6 "Other"
	label values gender gender

	label variable hispanic "Hispanic, Latino, or Spanish origin"
	note hispanic: "Hispanic, Latino, or Spanish origin"
	label define hispanic 1 "Yes" 0 "No"
	label values hispanic hispanic

	label variable race "Self-described race"
	note race: "Self-described race"

	label variable child "Has children under their care"
	note child: "Has children under their care"
	label define child 1 "Yes" 0 "No"
	label values child child



	capture {
		foreach rgvar of varlist attendstate_* {
			label variable `rgvar' "Additional state where they attended K-12 school"
			note `rgvar': "Additional state where they attended K-12 school"
		}
	}

	capture {
		foreach rgvar of varlist state_grades_* {
			label variable `rgvar' "Grades attended in \${attendstate}"
			note `rgvar': "Grades attended in \${attendstate}"
		}
	}




	* append old, previously-imported data (if any)
	cap confirm file "`dtafile'"
	if _rc == 0 {
		* mark all new data before merging with old data
		gen new_data_row=1
		
		* pull in old data
		append using "`dtafile'"
		
		* drop duplicates in favor of old, previously-imported data if overwrite_old_data is 0
		* (alternatively drop in favor of new data if overwrite_old_data is 1)
		sort key
		by key: gen num_for_key = _N
		drop if num_for_key > 1 & ((`overwrite_old_data' == 0 & new_data_row == 1) | (`overwrite_old_data' == 1 & new_data_row ~= 1))
		drop num_for_key

		* drop new-data flag
		drop new_data_row
	}
	
	* save data to Stata format
	save "`dtafile'", replace

	* show codebook and notes
	codebook
	notes list
}

disp
disp "Finished import of: `csvfile'"
disp

* OPTIONAL: LOCALLY-APPLIED STATA CORRECTIONS
*
* Rather than using SurveyCTO's review and correction workflow, the code below can apply a list of corrections
* listed in a local .csv file. Feel free to use, ignore, or delete this code.
*
*   Corrections file path and filename:  /Users/abigailorbe/Documents/repos/econ490-fall22/Abigail - abigailorbe/Week 11/ATO Week6_corrections.csv
*
*   Corrections file columns (in order): key, fieldname, value, notes

capture confirm file "`corrfile'"
if _rc==0 {
	disp
	disp "Starting application of corrections in: `corrfile'"
	disp

	* save primary data in memory
	preserve

	* load corrections
	insheet using "`corrfile'", names clear
	
	if _N>0 {
		* number all rows (with +1 offset so that it matches row numbers in Excel)
		gen rownum=_n+1
		
		* drop notes field (for information only)
		drop notes
		
		* make sure that all values are in string format to start
		gen origvalue=value
		tostring value, format(%100.0g) replace
		cap replace value="" if origvalue==.
		drop origvalue
		replace value=trim(value)
		
		* correct field names to match Stata field names (lowercase, drop -'s and .'s)
		replace fieldname=lower(subinstr(subinstr(fieldname,"-","",.),".","",.))
		
		* format date and date/time fields (taking account of possible wildcards for repeat groups)
		forvalues i = 1/100 {
			if "`datetime_fields`i''" ~= "" {
				foreach dtvar in `datetime_fields`i'' {
					* skip fields that aren't yet in the data
					cap unab dtvarignore : `dtvar'
					if _rc==0 {
						gen origvalue=value
						replace value=string(clock(value,"MDYhms",2025),"%25.0g") if strmatch(fieldname,"`dtvar'")
						* allow for cases where seconds haven't been specified
						replace value=string(clock(origvalue,"MDYhm",2025),"%25.0g") if strmatch(fieldname,"`dtvar'") & value=="." & origvalue~="."
						drop origvalue
					}
				}
			}
			if "`date_fields`i''" ~= "" {
				foreach dtvar in `date_fields`i'' {
					* skip fields that aren't yet in the data
					cap unab dtvarignore : `dtvar'
					if _rc==0 {
						replace value=string(clock(value,"MDY",2025),"%25.0g") if strmatch(fieldname,"`dtvar'")
					}
				}
			}
		}

		* write out a temp file with the commands necessary to apply each correction
		tempfile tempdo
		file open dofile using "`tempdo'", write replace
		local N = _N
		forvalues i = 1/`N' {
			local fieldnameval=fieldname[`i']
			local valueval=value[`i']
			local keyval=key[`i']
			local rownumval=rownum[`i']
			file write dofile `"cap replace `fieldnameval'="`valueval'" if key=="`keyval'""' _n
			file write dofile `"if _rc ~= 0 {"' _n
			if "`valueval'" == "" {
				file write dofile _tab `"cap replace `fieldnameval'=. if key=="`keyval'""' _n
			}
			else {
				file write dofile _tab `"cap replace `fieldnameval'=`valueval' if key=="`keyval'""' _n
			}
			file write dofile _tab `"if _rc ~= 0 {"' _n
			file write dofile _tab _tab `"disp"' _n
			file write dofile _tab _tab `"disp "CAN'T APPLY CORRECTION IN ROW #`rownumval'""' _n
			file write dofile _tab _tab `"disp"' _n
			file write dofile _tab `"}"' _n
			file write dofile `"}"' _n
		}
		file close dofile
	
		* restore primary data
		restore
		
		* execute the .do file to actually apply all corrections
		do "`tempdo'"

		* re-save data
		save "`dtafile'", replace
	}
	else {
		* restore primary data		
		restore
	}

	disp
	disp "Finished applying corrections in: `corrfile'"
	disp
}
