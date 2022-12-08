* import_glp_week6.do
*
* 	Imports and aggregates "glp_week6" (ID: glp_week6) data.
*
*	Inputs:  "/Users/geenapanzitta/Desktop/glp_week6_WIDE.csv"
*	Outputs: "/Users/geenapanzitta/Desktop/glp_week6.dta"
*
*	Output by SurveyCTO December 8, 2022 5:45 PM.

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
local csvfile "/Users/geenapanzitta/Desktop/glp_week6_WIDE.csv"
local dtafile "/Users/geenapanzitta/Desktop/glp_week6.dta"
local corrfile "/Users/geenapanzitta/Desktop/glp_week6_corrections.csv"
local note_fields1 ""
local text_fields1 "deviceid subscriberid simid devicephonenum username duration caseid sample_name users pub_to_users last_survey_status num_calls call_num callback_time now_complete survey_status name family_name age"
local text_fields2 "age_months age_days years_with_family months_with_family days_with_family breed_pullcsv breed_other family_member_count family_index_* family_member_name_* other_pet_count other_pets_index_*"
local text_fields3 "other_pet_name_* other_pet_species_other_* activities_done activities_time_count activity_id_* activity_name_* total_hours other_activities reschedule_full reschedule_no_ans instanceid"
local date_fields1 "birth_date adoption_date"
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


	label variable answered_response "Is \${sample_name} available to answer this survey?"
	note answered_response: "Is \${sample_name} available to answer this survey?"
	label define answered_response 1 "Yes, willing and able to respond right now" 2 "Yes, but need to reschedule at a later date" 3 "No, I haven't been able to make contact with them yet" 4 "No, they refused to respond to this follow up survey"
	label values answered_response answered_response

	label variable consent "This is a survey to be answered by household dogs. It will ask you questions abo"
	note consent: "This is a survey to be answered by household dogs. It will ask you questions about personal information. Would you like to continue?"
	label define consent 1 "Yes" 0 "No"
	label values consent consent

	label variable name "What is your (first) name?"
	note name: "What is your (first) name?"

	label variable family_name "What is your family/last name?"
	note family_name: "What is your family/last name?"

	label variable confirmation_name "Your name is \${name} and you are part of the \${family_name} family. Is that co"
	note confirmation_name: "Your name is \${name} and you are part of the \${family_name} family. Is that correct?"
	label define confirmation_name 1 "Yes" 0 "No"
	label values confirmation_name confirmation_name

	label variable birth_date "What is your date of birth?"
	note birth_date: "What is your date of birth?"

	label variable adoption_date "When did you join your household?"
	note adoption_date: "When did you join your household?"

	label variable confirmation_dates_years "You are \${age} years old and you have been with your family for \${years_with_f"
	note confirmation_dates_years: "You are \${age} years old and you have been with your family for \${years_with_family} years. Is that correct?"
	label define confirmation_dates_years 1 "Yes" 0 "No"
	label values confirmation_dates_years confirmation_dates_years

	label variable confirmation_dates_years_months "You are \${age} years old and you have been with your family for about \${months"
	note confirmation_dates_years_months: "You are \${age} years old and you have been with your family for about \${months_with_family} months. Is that correct?"
	label define confirmation_dates_years_months 1 "Yes" 0 "No"
	label values confirmation_dates_years_months confirmation_dates_years_months

	label variable confirmation_dates_years_days "You are \${age} years old and you have been with your family for \${days_with_fa"
	note confirmation_dates_years_days: "You are \${age} years old and you have been with your family for \${days_with_family} days. Is that correct?"
	label define confirmation_dates_years_days 1 "Yes" 0 "No"
	label values confirmation_dates_years_days confirmation_dates_years_days

	label variable confirmation_dates_months "You are about \${age_months} months old and you have been with your family for a"
	note confirmation_dates_months: "You are about \${age_months} months old and you have been with your family for about \${months_with_family} months. Is that correct?"
	label define confirmation_dates_months 1 "Yes" 0 "No"
	label values confirmation_dates_months confirmation_dates_months

	label variable confirmation_dates_months_days "You are about \${age_months} months old and you have been with your family for \"
	note confirmation_dates_months_days: "You are about \${age_months} months old and you have been with your family for \${days_with_family} days. Is that correct?"
	label define confirmation_dates_months_days 1 "Yes" 0 "No"
	label values confirmation_dates_months_days confirmation_dates_months_days

	label variable confirmation_dates_days "You are \${age_days} days old and you have been with your family for \${days_wit"
	note confirmation_dates_days: "You are \${age_days} days old and you have been with your family for \${days_with_family} days. Is that correct?"
	label define confirmation_dates_days 1 "Yes" 0 "No"
	label values confirmation_dates_days confirmation_dates_days

	label variable breed_pullcsv "What breed are you?"
	note breed_pullcsv: "What breed are you?"

	label variable breed_other "What breed are you?"
	note breed_other: "What breed are you?"

	label variable family_members_number "How many (human) family members do you have?"
	note family_members_number: "How many (human) family members do you have?"

	label variable other_pets_inhouse "Are there other pets in your household?"
	note other_pets_inhouse: "Are there other pets in your household?"
	label define other_pets_inhouse 1 "Yes" 0 "No"
	label values other_pets_inhouse other_pets_inhouse

	label variable other_pets_number "How many other pets are in your household?"
	note other_pets_number: "How many other pets are in your household?"

	label variable activities_done "In the past week, which of the following activities have you engaged in?"
	note activities_done: "In the past week, which of the following activities have you engaged in?"

	label variable hours_confirmation_low "There are 128 hours in the week. You recorded \${total_hours} hours spent doing "
	note hours_confirmation_low: "There are 128 hours in the week. You recorded \${total_hours} hours spent doing activites throughout the week. This seems low. Are you sure about your inputted hours?"
	label define hours_confirmation_low 1 "Yes" 0 "No"
	label values hours_confirmation_low hours_confirmation_low

	label variable hours_confirmation_toohigh "You recorded \${total_hours} hours spent doing activites throughout the week. Th"
	note hours_confirmation_toohigh: "You recorded \${total_hours} hours spent doing activites throughout the week. There are only 128 hours in the week. Are you sure about your inputted hours?"
	label define hours_confirmation_toohigh 1 "Yes" 0 "No"
	label values hours_confirmation_toohigh hours_confirmation_toohigh

	label variable hours_confirmation_general "There are 128 hours in the week. You recorded \${total_hours} hours spent doing "
	note hours_confirmation_general: "There are 128 hours in the week. You recorded \${total_hours} hours spent doing activites throughout the week. Does this sound correct?"
	label define hours_confirmation_general 1 "Yes" 0 "No"
	label values hours_confirmation_general hours_confirmation_general

	label variable other_activities_yesno "Have you engaged in other activities this week?"
	note other_activities_yesno: "Have you engaged in other activities this week?"
	label define other_activities_yesno 1 "Yes" 0 "No"
	label values other_activities_yesno other_activities_yesno

	label variable other_activities "What other activities have you engaged in this week?"
	note other_activities: "What other activities have you engaged in this week?"

	label variable trouble "All dogs get in trouble sometimes. How many times in the past week did your huma"
	note trouble: "All dogs get in trouble sometimes. How many times in the past week did your human(s) get mad at you?"

	label variable accidents "Even the goodest dogs have accidents sometimes. How many times in the past week "
	note accidents: "Even the goodest dogs have accidents sometimes. How many times in the past week did you have an accident inside?"

	label variable reschedule "ENUMERATOR, read this out loud: When would you like to reschedule the survey? EN"
	note reschedule: "ENUMERATOR, read this out loud: When would you like to reschedule the survey? ENUMERATOR INSTRUCTIONS: When scheduling the callback, check the calendar to make sure you are available for that time. It may take up to five minutes before the event is published to the calendar."



	capture {
		foreach rgvar of varlist family_member_name_* {
			label variable `rgvar' "What is your family member \${family_index}'s name?"
			note `rgvar': "What is your family member \${family_index}'s name?"
		}
	}

	capture {
		foreach rgvar of varlist family_member_age_* {
			label variable `rgvar' "What is your family member \${family_index}'s age (in years)?"
			note `rgvar': "What is your family member \${family_index}'s age (in years)?"
		}
	}

	capture {
		foreach rgvar of varlist other_pet_name_* {
			label variable `rgvar' "What is other pet \${other_pets_index}'s name?"
			note `rgvar': "What is other pet \${other_pets_index}'s name?"
		}
	}

	capture {
		foreach rgvar of varlist other_pet_age_* {
			label variable `rgvar' "What is other pet \${other_pets_index}'s age (in years)?"
			note `rgvar': "What is other pet \${other_pets_index}'s age (in years)?"
		}
	}

	capture {
		foreach rgvar of varlist other_pet_species_* {
			label variable `rgvar' "What kind of animal is other pet \${other_pets_index}?"
			note `rgvar': "What kind of animal is other pet \${other_pets_index}?"
			label define `rgvar' 1 "Dog" 2 "Cat" 3 "Fish" 4 "Bird" 5 "Snake" 6 "Lizard" 7 "Rabbit" 8 "Hamster" 9 "Guinea pig" 10 "Other"
			label values `rgvar' `rgvar'
		}
	}

	capture {
		foreach rgvar of varlist other_pet_species_other_* {
			label variable `rgvar' "What kind of animal is other pet \${other_pets_index}?"
			note `rgvar': "What kind of animal is other pet \${other_pets_index}?"
		}
	}

	capture {
		foreach rgvar of varlist activity_hours_* {
			label variable `rgvar' "In the past week, how many hours did you spend \${activity_name}?"
			note `rgvar': "In the past week, how many hours did you spend \${activity_name}?"
		}
	}

	capture {
		foreach rgvar of varlist activity_preference_* {
			label variable `rgvar' "Do you wish you had spent more, the same, or less time \${activity_name}?"
			note `rgvar': "Do you wish you had spent more, the same, or less time \${activity_name}?"
			label define `rgvar' 1 "More" 2 "The same" 3 "Less"
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
*   Corrections file path and filename:  /Users/geenapanzitta/Desktop/glp_week6_corrections.csv
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
