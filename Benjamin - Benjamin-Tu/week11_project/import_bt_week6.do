* import_bt_week6.do
*
* 	Imports and aggregates "bt_week6" (ID: bt_week6) data.
*
*	Inputs:  "bt_week6_WIDE.csv"
*	Outputs: "bt_week6.dta"
*
*	Output by SurveyCTO November 22, 2022 3:08 AM.

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
local csvfile "/Users/benjamintu/Downloads/week10_project/bt_week6_WIDE.csv"
local dtafile "bt_week6.dta"
local corrfile "bt_week6_corrections.csv"
local note_fields1 ""
local text_fields1 "deviceid subscriberid simid devicephonenum username duration caseid sample_name sample_email users pub_to_users last_survey_status num_calls call_num callback_time now_complete survey_status name"
local text_fields2 "email continent_pullcsv country_pullcsv club_re_count club_index_* club_name_* club_commitment_* reschedule_full reschedule_no_ans instanceid"
local date_fields1 ""
local datetime_fields1 "submissiondate starttime endtime reschedule"

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
	label define answered_response 1 "Yes, willing and able to respond right now" 2 "Yes, but need to reschedule at a later date" 3 "No, I haven't been able to make contact with them yet" 4 "No, they refused to respond to this follow up survey"
	label values answered_response answered_response

	label variable consent "This form will ask you individual questions to demonstrate an example of survey "
	note consent: "This form will ask you individual questions to demonstrate an example of survey in class. Would you like to continue and fill it out?"
	label define consent 1 "yes" 0 "no"
	label values consent consent

	label variable name "user_name"
	note name: "user_name"

	label variable email "user_email"
	note email: "user_email"

	label variable continent_pullcsv "What continent are you from?"
	note continent_pullcsv: "What continent are you from?"

	label variable country_pullcsv "What country are you from?"
	note country_pullcsv: "What country are you from?"

	label variable club "Are you part of any club this semester?"
	note club: "Are you part of any club this semester?"
	label define club 1 "yes" 0 "no"
	label values club club

	label variable club_number "How many clubs do you join this semester?"
	note club_number: "How many clubs do you join this semester?"

	label variable reschedule "ENUMERATOR, read this out loud: When would you like to reschedule the survey? EN"
	note reschedule: "ENUMERATOR, read this out loud: When would you like to reschedule the survey? ENUMERATOR INSTRUCTIONS: When scheduling the callback, check the calendar to make sure you are available for that time. It may take up to five minutes before the event is published to the calendar."



	capture {
		foreach rgvar of varlist club_name_* {
			label variable `rgvar' "club_name"
			note `rgvar': "club_name"
		}
	}

	capture {
		foreach rgvar of varlist club_label_* {
			label variable `rgvar' "Do you agree that \${club_name} has ....?"
			note `rgvar': "Do you agree that \${club_name} has ....?"
			label define `rgvar' 1 "yes" 0 "no"
			label values `rgvar' `rgvar'
		}
	}

	capture {
		foreach rgvar of varlist has_meeting_* {
			label variable `rgvar' "Weekly Meeting?"
			note `rgvar': "Weekly Meeting?"
			label define `rgvar' 1 "yes" 0 "no"
			label values `rgvar' `rgvar'
		}
	}

	capture {
		foreach rgvar of varlist has_event_* {
			label variable `rgvar' "Monthly Event?"
			note `rgvar': "Monthly Event?"
			label define `rgvar' 1 "yes" 0 "no"
			label values `rgvar' `rgvar'
		}
	}

	capture {
		foreach rgvar of varlist has_teamwork_* {
			label variable `rgvar' "Collaboration?"
			note `rgvar': "Collaboration?"
			label define `rgvar' 1 "yes" 0 "no"
			label values `rgvar' `rgvar'
		}
	}

	capture {
		foreach rgvar of varlist club_time_* {
			label variable `rgvar' "How many hours do you spend each week at \${club_name}?"
			note `rgvar': "How many hours do you spend each week at \${club_name}?"
		}
	}

	capture {
		foreach rgvar of varlist club_sensitive_agree_* {
			label variable `rgvar' "How many of the following statement do you agree?"
			note `rgvar': "How many of the following statement do you agree?"
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
*   Corrections file path and filename:  bt_week6_corrections.csv
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
