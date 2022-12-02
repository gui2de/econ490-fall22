* import_am_week11.do
*
* 	Imports and aggregates "Antonio_week11survey" (ID: am_week11) data.
*
*	Inputs:  "Antonio_week11survey_WIDE.csv"
*	Outputs: "Antonio_week11survey.dta"
*
*	Output by SurveyCTO December 2, 2022 3:49 AM.

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
local csvfile "Antonio_week11survey_WIDE.csv"
local dtafile "Antonio_week11survey.dta"
local corrfile "Antonio_week11survey_corrections.csv"
local note_fields1 ""
local text_fields1 "deviceid subscriberid simid devicephonenum username duration caseid sample_name num_calls last_survey_status call_num survey_status state race age travel_to habits_by_destination_count dest_id_*"
local text_fields2 "dest_name_* other_mode_* what_changes instanceid"
local date_fields1 "birthday"
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


	label variable consent "consent"
	note consent: "consent"
	label define consent 1 "yes" 2 "another_time" 3 "no" 4 "no_contact"
	label values consent consent

	label variable vehicle "own_vehicle"
	note vehicle: "own_vehicle"
	label define vehicle 1 "yes" 0 "no"
	label values vehicle vehicle

	label variable state "state"
	note state: "state"

	label variable birthday "What is your date of birth?"
	note birthday: "What is your date of birth?"

	label variable gender "gender"
	note gender: "gender"
	label define gender 1 "female" 2 "male" 3 "non-binary" 0 "no_answer"
	label values gender gender

	label variable race "race"
	note race: "race"

	label variable demographics_check "demographics_check"
	note demographics_check: "demographics_check"
	label define demographics_check 1 "yes" 0 "no"
	label values demographics_check demographics_check

	label variable travel_to "destinations"
	note travel_to: "destinations"

	label variable serv_freq "serv_freq"
	note serv_freq: "serv_freq"
	label define serv_freq 1 "much_less" 2 "slightly_less" 3 "same" 4 "slightly_more" 5 "much_more"
	label values serv_freq serv_freq

	label variable serv_reliability "serv_reliability"
	note serv_reliability: "serv_reliability"
	label define serv_reliability 1 "much_less" 2 "slightly_less" 3 "same" 4 "slightly_more" 5 "much_more"
	label values serv_reliability serv_reliability

	label variable serv_cov "serv_cov"
	note serv_cov: "serv_cov"
	label define serv_cov 1 "much_less" 2 "slightly_less" 3 "same" 4 "slightly_more" 5 "much_more"
	label values serv_cov serv_cov

	label variable fare_reduction "fare_reduction"
	note fare_reduction: "fare_reduction"
	label define fare_reduction 1 "much_less" 2 "slightly_less" 3 "same" 4 "slightly_more" 5 "much_more"
	label values fare_reduction fare_reduction

	label variable less_crowding "less_crowding"
	note less_crowding: "less_crowding"
	label define less_crowding 1 "much_less" 2 "slightly_less" 3 "same" 4 "slightly_more" 5 "much_more"
	label values less_crowding less_crowding

	label variable police "police"
	note police: "police"
	label define police 1 "much_less" 2 "slightly_less" 3 "same" 4 "slightly_more" 5 "much_more"
	label values police police

	label variable facilities "facilities"
	note facilities: "facilities"
	label define facilities 1 "much_less" 2 "slightly_less" 3 "same" 4 "slightly_more" 5 "much_more"
	label values facilities facilities

	label variable congestion "congestion"
	note congestion: "congestion"
	label define congestion 1 "much_less" 2 "slightly_less" 3 "same" 4 "slightly_more" 5 "much_more"
	label values congestion congestion

	label variable lose_vehicle "lose_vehicle"
	note lose_vehicle: "lose_vehicle"
	label define lose_vehicle 1 "yes" 0 "no"
	label values lose_vehicle lose_vehicle

	label variable what_changes "You answered that changes to the public transit system might cause you to get ri"
	note what_changes: "You answered that changes to the public transit system might cause you to get rid of your personal vehicle. We would love to hear what changes would have such a great impact on our travel habits."



	capture {
		foreach rgvar of varlist dest_freq_* {
			label variable `rgvar' "dest_freq"
			note `rgvar': "dest_freq"
			label define `rgvar' 1 "once_month" 2 "once_week" 3 "three_week" 4 "five_week"
			label values `rgvar' `rgvar'
		}
	}

	capture {
		foreach rgvar of varlist veh_freq_* {
			label variable `rgvar' "veh_freq"
			note `rgvar': "veh_freq"
			label define `rgvar' 1 "never" 2 "rarely" 3 "half" 4 "usually" 5 "always"
			label values `rgvar' `rgvar'
		}
	}

	capture {
		foreach rgvar of varlist other_mode_* {
			label variable `rgvar' "other_mode"
			note `rgvar': "other_mode"
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
*   Corrections file path and filename:  Antonio_week11survey_corrections.csv
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
