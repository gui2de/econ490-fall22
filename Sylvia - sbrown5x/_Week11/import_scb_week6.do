* import_scb_week6.do
*
* 	Imports and aggregates "Sylvia Brown's Week 6 and 7 Survey" (ID: scb_week6) data.
*
*	Inputs:  "/Users/sylviabrown/git/econ490-fall22/Sylvia - sbrown5x/_Week11/Sylvia Brown's Week 6 and 7 Survey_WIDE.csv"
*	Outputs: "/Users/sylviabrown/git/econ490-fall22/Sylvia - sbrown5x/_Week11/Sylvia Brown's Week 6 and 7 Survey.dta"
*
*	Output by SurveyCTO November 20, 2022 4:33 AM.

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
local csvfile "/Users/sylviabrown/git/econ490-fall22/Sylvia - sbrown5x/_Week11/scb_data.csv"
local dtafile "/Users/sylviabrown/git/econ490-fall22/Sylvia - sbrown5x/_Week11/scb_data.dta"
local corrfile "/Users/sylviabrown/git/econ490-fall22/Sylvia - sbrown5x/_Week11/scb_data_corrections.csv"
local note_fields1 ""
local text_fields1 "deviceid subscriberid simid devicephonenum username duration caseid email_data email_new fintech group_fintech_count fintech_id_* fintech_name_* name_fintech_* gender_other race race_other num_calls"
local text_fields2 "current_num_calls last_survey_status up_to_date_email age instanceid"
local date_fields1 "birth_date"
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


	label variable consent "Thank you for your participation in our study! This study will help us gain a va"
	note consent: "Thank you for your participation in our study! This study will help us gain a valuable understanding of how Americans manage their money and will help us advise financial institutions, government, and others on how to design financial products that benefit you and other American consumers. Before you begin, we wanted to remind you of a few features of your participation: 1. You do not have to complete the survey if you are uncomfortable with sharing any information; you may leave the survey at any time. 2. Your responses will not be used for any purpose outside of this specific research project and will not be shared outside of our research team. 3. Your data will be kept secure and confidential. 4. There are no right or wrong answers! The most valuable information to us is your experiences and opinions. Before we begin, do you consent to take this survey?"
	label define consent 1 "Yes" 0 "No" -98 "Did not answer" -99 "Otherwise unable to take the survey"
	label values consent consent

	label variable email "Is your preferred email address still \${email_data}?"
	note email: "Is your preferred email address still \${email_data}?"
	label define email 1 "Yes" 0 "No"
	label values email email

	label variable email_new "What is your preferred email address for our research team to contact you?"
	note email_new: "What is your preferred email address for our research team to contact you?"

	label variable fintech "Which of the following types of financial products have you used in the past 3 m"
	note fintech: "Which of the following types of financial products have you used in the past 3 months?"

	label variable amount_robo "How much money do you currently have invested within your robo-advisor account(s"
	note amount_robo: "How much money do you currently have invested within your robo-advisor account(s)?"

	label variable robo_crypto "Cryptocurrency"
	note robo_crypto: "Cryptocurrency"

	label variable robo_etf "ETF(s)"
	note robo_etf: "ETF(s)"

	label variable robo_stock "Individual stock(s)"
	note robo_stock: "Individual stock(s)"

	label variable robo_ira "IRA(s)"
	note robo_ira: "IRA(s)"

	label variable robo_mm "Money market account(s)"
	note robo_mm: "Money market account(s)"

	label variable robo_mutual_fund "Mutual fund(s)"
	note robo_mutual_fund: "Mutual fund(s)"

	label variable robo_other "Other"
	note robo_other: "Other"

	label variable education "What is the highest degree or level of school you have completed?"
	note education: "What is the highest degree or level of school you have completed?"
	label define education 1 "Less than high school diploma or alternative" 2 "High school diploma or alternative credential (such as GED)" 3 "Some college, no degree" 4 "Associate's degree (for example: AA, AS)" 5 "Bachelor's degree (for example: BA, BS)" 6 "Master's degree (for example: MA, MS, MBA)" 7 "Professional degree (for example: MD, DDS, LLB, JD)" 8 "Doctorate degree (for example: PhD, EdD)"
	label values education education

	label variable employment "Which of the following best describes your current employment status?"
	note employment: "Which of the following best describes your current employment status?"
	label define employment 1 "Employed full-time (35 or more hours per week)" 2 "Employed part-time (fewer than 35 hours per week)" 3 "Unemployed and currently looking for work" 4 "Unemployed and not currently looking for work" 5 "Retired" 6 "Self-employed" 7 "Unable to work"
	label values employment employment

	label variable income "What was your household income in 2021?"
	note income: "What was your household income in 2021?"
	label define income 1 "Less than \$20,000" 2 "\$20,000 to \$39,999" 3 "\$40,000 to \$59,999" 4 "\$60,000 to \$79,999" 5 "\$80,000 to \$99,999" 6 "\$100,000 to \$119,999" 7 "\$120,000 to \$139,999" 8 "\$140,000 to \$159,999" 9 "\$160,000 to \$179,999" 10 "\$180,000 to \$199,999" 11 "\$200,000 or more"
	label values income income

	label variable birth_date "What is your date of birth?"
	note birth_date: "What is your date of birth?"

	label variable gender "Which of the following best describes your gender identity?"
	note gender: "Which of the following best describes your gender identity?"
	label define gender 1 "Female" 2 "Male" 3 "Non-binary" -98 "Prefer to self-identify" -99 "Prefer not to disclose"
	label values gender gender

	label variable gender_other "Please specify your gender identity."
	note gender_other: "Please specify your gender identity."

	label variable race "Which of the following do you identify as?"
	note race: "Which of the following do you identify as?"

	label variable race_other "Please specify your racial identity."
	note race_other: "Please specify your racial identity."

	label variable ethnicity "Do you identify as Hispanic, Latino(a), and/or Chicano(a)?"
	note ethnicity: "Do you identify as Hispanic, Latino(a), and/or Chicano(a)?"
	label define ethnicity 1 "Yes" 0 "No" -99 "Prefer not to disclose"
	label values ethnicity ethnicity



	capture {
		foreach rgvar of varlist name_fintech_* {
			label variable `rgvar' "What is the name (or what are the names) of the \${fintech_name} product(s) that"
			note `rgvar': "What is the name (or what are the names) of the \${fintech_name} product(s) that you have used in the past 3 months?"
		}
	}

	capture {
		foreach rgvar of varlist likert_fintech_* {
			label variable `rgvar' "How satisfied have you been with the \${fintech_name} product(s) that you have u"
			note `rgvar': "How satisfied have you been with the \${fintech_name} product(s) that you have used in the past 3 months?"
			label define `rgvar' 1 "Very unsatisfied" 2 "Unsatisfied" 3 "Neither satisfied nor unsatisfied" 4 "Satisfied" 5 "Very satisfied"
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
*   Corrections file path and filename:  /Users/sylviabrown/git/econ490-fall22/Sylvia - sbrown5x/_Week11/Sylvia Brown's Week 6 and 7 Survey_corrections.csv
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
