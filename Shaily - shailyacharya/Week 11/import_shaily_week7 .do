* import_shaily_week7.do
*
* 	Imports and aggregates "Shaily_week7" (ID: shaily_week7) data.
*
*	Inputs:  "Shaily_week7_WIDE.csv"
*	Outputs: "Shaily_week7.dta"
*
*	Output by SurveyCTO December 9, 2022 7:05 AM.

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
local csvfile "Shaily_week7_WIDE.csv"
local dtafile "Shaily_week7.dta"
local corrfile "Shaily_week7_corrections.csv"
local note_fields1 ""
local text_fields1 "deviceid subscriberid simid devicephonenum username duration caseid firstname lastname email race continent_pullcsv corereqs core_repeat1_count core_id1_* core_name1_* classname_* coursecode_* prof_*"
local text_fields2 "creditcount creditaccuracy instanceid"
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


	label variable consent "This form will ask you individual questions about your classes at Georgetown. Wo"
	note consent: "This form will ask you individual questions about your classes at Georgetown. Would you like to continue and fill it out?"
	label define consent 1 "Yes" 0 "No"
	label values consent consent

	label variable firstname "What is your first name?"
	note firstname: "What is your first name?"

	label variable lastname "What is your last name?"
	note lastname: "What is your last name?"

	label variable email "What is your email address?"
	note email: "What is your email address?"

	label variable school "What undergraduate school are you in?"
	note school: "What undergraduate school are you in?"
	label define school 1 "SFS" 2 "COL" 3 "MSB" 4 "SOH" 5 "SON"
	label values school school

	label variable gender "What is your gender?"
	note gender: "What is your gender?"
	label define gender 1 "Male" 2 "Female" 3 "Non-binary" 4 "Other"
	label values gender gender

	label variable race "What is your race?"
	note race: "What is your race?"

	label variable continent_pullcsv "What continent are you from?"
	note continent_pullcsv: "What continent are you from?"

	label variable age "What is your age?"
	note age: "What is your age?"

	label variable corereqs "Select which core curriculum requirements you are fulfilling through your classe"
	note corereqs: "Select which core curriculum requirements you are fulfilling through your classes this semester."

	label variable classcount "How many classes are you in?"
	note classcount: "How many classes are you in?"

	label variable creditaccuracy "On average, classes at Georgetown are 3 credits each. Based on the average, you "
	note creditaccuracy: "On average, classes at Georgetown are 3 credits each. Based on the average, you are enrolled in \${creditcount} credits. Is this correct?"

	label variable opinion "Please select one of the following options, reflecting your opinion on the core "
	note opinion: "Please select one of the following options, reflecting your opinion on the core curriculum at Georgetown."
	label define opinion 1 "I strongly dislike the core curriculum" 2 "I dislike the core curriculum" 3 "I am neutral about the core curriculum" 4 "I enjoy the core curriculum" 5 "I strongly enjoy the core curriculum"
	label values opinion opinion

	label variable sensitive "Did you vote in the Georgetown undergraduate Student Association (GUSA) election"
	note sensitive: "Did you vote in the Georgetown undergraduate Student Association (GUSA) election this year?"
	label define sensitive 1 "I did not vote" 2 "I thought about voting this time but didn’t" 3 "I usually vote but didn’t this time" 4 "I am sure I voted."
	label values sensitive sensitive



	capture {
		foreach rgvar of varlist classname_* {
			label variable `rgvar' "What is the name of the class you are taking to fulfill \${core_name1}?"
			note `rgvar': "What is the name of the class you are taking to fulfill \${core_name1}?"
		}
	}

	capture {
		foreach rgvar of varlist coursecode_* {
			label variable `rgvar' "What is the course code for the class listed above?"
			note `rgvar': "What is the course code for the class listed above?"
		}
	}

	capture {
		foreach rgvar of varlist prof_* {
			label variable `rgvar' "Who is the professor for this class?"
			note `rgvar': "Who is the professor for this class?"
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
*   Corrections file path and filename:  Shaily_week7_corrections.csv
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
