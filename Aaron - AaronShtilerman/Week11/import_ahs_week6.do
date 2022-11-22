* import_ahs_week6.do
*
* 	Imports and aggregates "ahs_week6" (ID: ahs_week6) data.
*
*	Inputs:  ""C:/Users/15162/Desktop/GU Semesters/Georgetown 2022 FALL/Research Fieldwork/Week11"/ahs_week6_WIDE.csv"
*	Outputs: ""C:/Users/15162/Desktop/GU Semesters/Georgetown 2022 FALL/Research Fieldwork/Week11"/ahs_week6.dta"
*
*	Output by SurveyCTO November 18, 2022 9:30 PM.

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
local csvfile "C:/Users/15162/Desktop/GU Semesters/Georgetown 2022 FALL/Research Fieldwork/Week11/ahs_week6_WIDE.csv"
local dtafile "C:/Users/15162/Desktop/GU Semesters/Georgetown 2022 FALL/Research Fieldwork/Week11/ahs_week6.dta"
local corrfile "C:/Users/15162/Desktop/GU Semesters/Georgetown 2022 FALL/Research Fieldwork/Week11/ahs_week6_corrections.csv"
local note_fields1 ""
local text_fields1 "deviceid subscriberid simid devicephonenum username duration caseid sample_name sample_email users pub_to_users last_survey_status num_calls call_num now_complete survey_status class_count"
local text_fields2 "class_index_* class_name_* total_class_hours_* total_school_hours email state target_department target_class instanceid"
local date_fields1 ""
local datetime_fields1 "submissiondate starttime endtime reschedule_datetime"

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


	label variable answered_response "Is \${sample_name} available to answer this follow up survey?"
	note answered_response: "Is \${sample_name} available to answer this follow up survey?"
	label define answered_response 1 "responding" 2 "rescheduling" 3 "nocontact" 4 "refused"
	label values answered_response answered_response

	label variable consent "This survey will ask you questions regarding your personal and academic informat"
	note consent: "This survey will ask you questions regarding your personal and academic information. Do you consent to having your responses be used for research purposes?"
	label define consent 1 "Yes" 0 "No"
	label values consent consent

	label variable class_num "number of classes"
	note class_num: "number of classes"

	label variable confirm_totalhours "Your total time in your classes or studying for your classes is \${total_school_"
	note confirm_totalhours: "Your total time in your classes or studying for your classes is \${total_school_hours}, which is pretty high. Is this correct?"
	label define confirm_totalhours 1 "Yes" 0 "No"
	label values confirm_totalhours confirm_totalhours

	label variable cheatingwork "times cheated on work"
	note cheatingwork: "times cheated on work"
	label define cheatingwork 1 "1 times" 2 "1-3 times" 3 "4-6 times" 4 "7+ times" 999 "Prefer not to answer"
	label values cheatingwork cheatingwork

	label variable cheatingexam "times cheated on exams"
	note cheatingexam: "times cheated on exams"
	label define cheatingexam 1 "1 times" 2 "1-3 times" 3 "4-6 times" 4 "7+ times" 999 "Prefer not to answer"
	label values cheatingexam cheatingexam

	label variable email "email"
	note email: "email"

	label variable education "What is your current grade?"
	note education: "What is your current grade?"
	label define education 1 "Freshman" 2 "Sophomore" 3 "Junior" 4 "Senior"
	label values education education

	label variable state "state"
	note state: "state"

	label variable target_department "(=1) taking math/accounting class"
	note target_department: "(=1) taking math/accounting class"

	label variable target_class "class code"
	note target_class: "class code"

	label variable followup "Would you be willing to be contacted for further questions?"
	note followup: "Would you be willing to be contacted for further questions?"
	label define followup 1 "Yes" 0 "No"
	label values followup followup

	label variable reschedule_datetime "What date and time would you be available to reschedule?"
	note reschedule_datetime: "What date and time would you be available to reschedule?"



	capture {
		foreach rgvar of varlist class_name_* {
			label variable `rgvar' "class \${class_index} name"
			note `rgvar': "class \${class_index} name"
		}
	}

	capture {
		foreach rgvar of varlist class_hours_* {
			label variable `rgvar' "class \${class_index} hours"
			note `rgvar': "class \${class_index} hours"
		}
	}

	capture {
		foreach rgvar of varlist study_hours_* {
			label variable `rgvar' "class \${class_index} study hours"
			note `rgvar': "class \${class_index} study hours"
		}
	}

	capture {
		foreach rgvar of varlist class_preference_* {
			label variable `rgvar' "class \${class_index} rating"
			note `rgvar': "class \${class_index} rating"
			label define `rgvar' 1 "1" 2 "2" 3 "3" 4 "4" 5 "5"
			label values `rgvar' `rgvar'
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
*   Corrections file path and filename:  "C:/Users/15162/Desktop/GU Semesters/Georgetown 2022 FALL/Research Fieldwork/Week11"/ahs_week6_corrections.csv
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
