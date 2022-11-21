* import_victoria_week6.do
*
* 	Imports and aggregates "Victoria Week6" (ID: victoria_week6) data.
*
*	Inputs:  "/Users/victoriapeng/Desktop/490 Research Field/Week11/Victoria Week6_WIDE.csv"
*	Outputs: "/Users/victoriapeng/Desktop/490 Research Field/Week11/Victoria Week6.dta"
*
*	Output by SurveyCTO November 21, 2022 3:11 AM.

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
local csvfile "/Users/victoriapeng/Desktop/490 Research Field/Week11/Victoria Week6_WIDE.csv"
local dtafile "/Users/victoriapeng/Desktop/490 Research Field/Week11/Victoria Week6.dta"
local corrfile "/Users/victoriapeng/Desktop/490 Research Field/Week11/Victoria Week6_corrections.csv"
local note_fields1 ""
local text_fields1 "deviceid subscriberid simid devicephonenum username caseid sample_name sample_email users pub_to_users last_survey_status num_calls call_num callback_time now_complete survey_status id email"
local text_fields2 "calculate_age continent families_member_count family_index_* families_name_* sum_timeuse sum_timeuse_check1_why monthly_income reschedule_full reschedule_no_ans instanceid"
local date_fields1 "dob"
local datetime_fields1 "submissiondate starttime endtime reschedule_date"

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
	label define answered_response 1 "Yes, willing and able to respond right now." 2 "Yes, but need to reschedule at a later date" 3 "No, I haven't been able to make contact with them yet" 4 "No, they refused to respond to this follow up survey"
	label values answered_response answered_response

	label variable id "What is your full name?"
	note id: "What is your full name?"

	label variable email "What is your email address?"
	note email: "What is your email address?"

	label variable gender "What is your gender?"
	note gender: "What is your gender?"
	label define gender 1 "Male" 0 "Female"
	label values gender gender

	label variable dob "What is your date of birth?"
	note dob: "What is your date of birth?"

	label variable continent "What continent are you from?"
	note continent: "What continent are you from?"

	label variable families_yn "Do you have any immediate family members?"
	note families_yn: "Do you have any immediate family members?"
	label define families_yn 1 "Yes" 0 "No"
	label values families_yn families_yn

	label variable family_n "How many immediate family members do you have?"
	note family_n: "How many immediate family members do you have?"

	label variable timeuse_label "-"
	note timeuse_label: "-"
	label define timeuse_label 1 "Yes" 0 "No"
	label values timeuse_label timeuse_label

	label variable timeuse_golf "Spending any time playing golf at driving range or golf course?"
	note timeuse_golf: "Spending any time playing golf at driving range or golf course?"
	label define timeuse_golf 1 "Yes" 0 "No"
	label values timeuse_golf timeuse_golf

	label variable timeuse_studying "Spending any time studying?"
	note timeuse_studying: "Spending any time studying?"
	label define timeuse_studying 1 "Yes" 0 "No"
	label values timeuse_studying timeuse_studying

	label variable timeuse_dineout "Spending any time dining out?"
	note timeuse_dineout: "Spending any time dining out?"
	label define timeuse_dineout 1 "Yes" 0 "No"
	label values timeuse_dineout timeuse_dineout

	label variable timeuse_shopping "Spending any time shopping?"
	note timeuse_shopping: "Spending any time shopping?"
	label define timeuse_shopping 1 "Yes" 0 "No"
	label values timeuse_shopping timeuse_shopping

	label variable timeuse_sleeping "Spending any time sleeping?"
	note timeuse_sleeping: "Spending any time sleeping?"
	label define timeuse_sleeping 1 "Yes" 0 "No"
	label values timeuse_sleeping timeuse_sleeping

	label variable timeuse_working "Spending any time working?"
	note timeuse_working: "Spending any time working?"
	label define timeuse_working 1 "Yes" 0 "No"
	label values timeuse_working timeuse_working

	label variable timeuse_golf_hours "Spending any time playing golf at driving range or golf course?"
	note timeuse_golf_hours: "Spending any time playing golf at driving range or golf course?"

	label variable timeuse_studying_hours "Spending any time studying?"
	note timeuse_studying_hours: "Spending any time studying?"

	label variable timeuse_dineout_hours "Spending any time dining out?"
	note timeuse_dineout_hours: "Spending any time dining out?"

	label variable timeuse_sleeping_hours "Spending any time sleeping?"
	note timeuse_sleeping_hours: "Spending any time sleeping?"

	label variable timeuse_shopping_hours "Spending any time shopping?"
	note timeuse_shopping_hours: "Spending any time shopping?"

	label variable timeuse_working_hours "Spending any time working?"
	note timeuse_working_hours: "Spending any time working?"

	label variable sum_timeuse_check1 "The total number of hours spent doing any activity listed above comes out to \${"
	note sum_timeuse_check1: "The total number of hours spent doing any activity listed above comes out to \${sum_timeuse}. This number seems very low. Please double-check the answers in the previous screen. If they seem correct despite being low, please continue. If they seem incorrect, please go back and correct them. Remember : 7 days (including nights) equals to 168 hours. Normally, most night hours should be allocated to sleeping. For reference, sleeping 6 hours every night means 42 hours over 7 days, sleeping 8 hours every night means 56 hours over 7 days. For reference, a full time job takes about 40 hours on average over 7 days (8 hours over 5 days of work). Does \${sum_timeuse} seem correct even if it is pretty low?"
	label define sum_timeuse_check1 1 "Yes" 0 "No"
	label values sum_timeuse_check1 sum_timeuse_check1

	label variable sum_timeuse_check1_why "Please explain why the timeuse allocation is correct despite being very low. Wha"
	note sum_timeuse_check1_why: "Please explain why the timeuse allocation is correct despite being very low. What activities that take respondent's time are not captured in the previous timeuse table?"

	label variable moneyspent "What percent of your annual income did you spend on golf practice (in the course"
	note moneyspent: "What percent of your annual income did you spend on golf practice (in the course and driving range) including golf equipment (clubs, bags, other clothing, and accessories) in 2021?"

	label variable annual_income "What is your personal annual income in 2021?"
	note annual_income: "What is your personal annual income in 2021?"
	label define annual_income 1 "\$0-\$30,000" 2 "\$31,000-\$60,000" 3 "\$61,000-\$90,000" 4 "\$91,000-\$120,000" 5 "\$120,000+" 6 "Prefer not to answer"
	label values annual_income annual_income

	label variable practice_without_paying "Have you ever been on an unsupervised golf course and practiced without paying?"
	note practice_without_paying: "Have you ever been on an unsupervised golf course and practiced without paying?"
	label define practice_without_paying 1 "Yes" 0 "No"
	label values practice_without_paying practice_without_paying

	label variable satisfaction_label "-"
	note satisfaction_label: "-"
	label define satisfaction_label 1 "Very Satisfied" 2 "Somewhat Satisfied" 3 "Neutral" 4 "Somewhat dissatisfied" 5 "Very dissatisfied" 6 "N/A"
	label values satisfaction_label satisfaction_label

	label variable tee_time "Scheduling a tee time"
	note tee_time: "Scheduling a tee time"
	label define tee_time 1 "Very Satisfied" 2 "Somewhat Satisfied" 3 "Neutral" 4 "Somewhat dissatisfied" 5 "Very dissatisfied" 6 "N/A"
	label values tee_time tee_time

	label variable confirmation "Tee time confirmation"
	note confirmation: "Tee time confirmation"
	label define confirmation 1 "Very Satisfied" 2 "Somewhat Satisfied" 3 "Neutral" 4 "Somewhat dissatisfied" 5 "Very dissatisfied" 6 "N/A"
	label values confirmation confirmation

	label variable checkin "Check-in"
	note checkin: "Check-in"
	label define checkin 1 "Very Satisfied" 2 "Somewhat Satisfied" 3 "Neutral" 4 "Somewhat dissatisfied" 5 "Very dissatisfied" 6 "N/A"
	label values checkin checkin

	label variable condition "Overall Condition of the Course"
	note condition: "Overall Condition of the Course"
	label define condition 1 "Very Satisfied" 2 "Somewhat Satisfied" 3 "Neutral" 4 "Somewhat dissatisfied" 5 "Very dissatisfied" 6 "N/A"
	label values condition condition

	label variable food_beverage "Overall food and beverage"
	note food_beverage: "Overall food and beverage"
	label define food_beverage 1 "Very Satisfied" 2 "Somewhat Satisfied" 3 "Neutral" 4 "Somewhat dissatisfied" 5 "Very dissatisfied" 6 "N/A"
	label values food_beverage food_beverage

	label variable value "Overall value for the money"
	note value: "Overall value for the money"
	label define value 1 "Very Satisfied" 2 "Somewhat Satisfied" 3 "Neutral" 4 "Somewhat dissatisfied" 5 "Very dissatisfied" 6 "N/A"
	label values value value

	label variable staff "Staff Friendliness"
	note staff: "Staff Friendliness"
	label define staff 1 "Very Satisfied" 2 "Somewhat Satisfied" 3 "Neutral" 4 "Somewhat dissatisfied" 5 "Very dissatisfied" 6 "N/A"
	label values staff staff

	label variable experience "Overall Experience"
	note experience: "Overall Experience"
	label define experience 1 "Very Satisfied" 2 "Somewhat Satisfied" 3 "Neutral" 4 "Somewhat dissatisfied" 5 "Very dissatisfied" 6 "N/A"
	label values experience experience

	label variable reschedule_date "What date and time would you be available to reschedule?"
	note reschedule_date: "What date and time would you be available to reschedule?"



	capture {
		foreach rgvar of varlist families_name_* {
			label variable `rgvar' "What is your family member \${family_index} name?"
			note `rgvar': "What is your family member \${family_index} name?"
		}
	}

	capture {
		foreach rgvar of varlist families_age_* {
			label variable `rgvar' "What is your family member \${family_index} age?"
			note `rgvar': "What is your family member \${family_index} age?"
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
*   Corrections file path and filename:  /Users/victoriapeng/Desktop/490 Research Field/Week11/Victoria Week6_corrections.csv
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
