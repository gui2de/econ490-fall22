* import_ynd_week6.do
*
* 	Imports and aggregates "ynd_week6" (ID: ynd_week6) data.
*
*	Inputs:  "ynd_week6_WIDE.csv"
*	Outputs: "ynd_week6.dta"
*
*	Output by SurveyCTO November 28, 2022 3:53 PM.

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
local csvfile "ynd_week6_WIDE.csv"
local dtafile "ynd_week6.dta"
local corrfile "ynd_week6_corrections.csv"
local note_fields1 ""
local text_fields1 "deviceid subscriberid simid devicephonenum username duration caseid enum_name no_consent name email_data email_new province county total_utility_expenses total_maintenance_expenses"
local text_fields2 "total_utilmaint_expenses add_exp_name earning_member_count earning_member_index_* earning_member_name_* member_earnings_total_* hh_earnings_total total_hh_income additional_finance_source random_num"
local text_fields3 "unreported_jnc support_village_head deposit_savings hh_own hh_rent last_survey_status up_to_date_email num_calls instanceid"
local date_fields1 "date"
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
						cap replace `dtvar'=clock(`tempdtvar',"DMYhms",2025)
						* automatically try without seconds, just in case
						cap replace `dtvar'=clock(`tempdtvar',"DMYhm",2025) if `dtvar'==. & `tempdtvar'~=""
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
						cap replace `dtvar'=date(`tempdtvar',"DMY",2025)
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


	label variable date "Date"
	note date: "Date"

	label variable enum_name "Enumerator name"
	note enum_name: "Enumerator name"

	label variable consent "Do you consent to complete the survey?"
	note consent: "Do you consent to complete the survey?"
	label define consent 1 "Yes" 0 "No"
	label values consent consent

	label variable no_consent "Why do you not consent to be surveyed?"
	note no_consent: "Why do you not consent to be surveyed?"

	label variable name "What is your name?"
	note name: "What is your name?"

	label variable age "What is your age?"
	note age: "What is your age?"

	label variable email "Is your preferred email address still \${email_data}?"
	note email: "Is your preferred email address still \${email_data}?"
	label define email 1 "Yes" 0 "No"
	label values email email

	label variable email_new "What is your preferred email address for our research team to contact you?"
	note email_new: "What is your preferred email address for our research team to contact you?"

	label variable province "What province are you from?"
	note province: "What province are you from?"

	label variable county "What county are you from?"
	note county: "What county are you from?"

	label variable construct_type "What is nature of this construction?"
	note construct_type: "What is nature of this construction?"
	label define construct_type 1 "Multifamily residential building" 2 "Individual house" 3 "Lamella/Block of house/Duplex" 4 "Part of house" 5 "Prefabricated building" 6 "Non-residential building being used as residence (school, barrack, temp, tent)" 7 "Other"
	label values construct_type construct_type

	label variable construct_year "In what year was this dwelling constructed?"
	note construct_year: "In what year was this dwelling constructed?"

	label variable construct_area "What is the area used by the household?"
	note construct_area: "What is the area used by the household?"

	label variable rooms_used "How many rooms are used by the household?"
	note rooms_used: "How many rooms are used by the household?"

	label variable labels "Does this household have a ..?"
	note labels: "Does this household have a ..?"
	label define labels 1 "Yes" 0 "No"
	label values labels labels

	label variable has_sep_kitchen "Separate kitchen"
	note has_sep_kitchen: "Separate kitchen"
	label define has_sep_kitchen 1 "Yes" 0 "No"
	label values has_sep_kitchen has_sep_kitchen

	label variable has_bathroom "Internal bathroom and toilet"
	note has_bathroom: "Internal bathroom and toilet"
	label define has_bathroom 1 "Yes" 0 "No"
	label values has_bathroom has_bathroom

	label variable has_toilet "Toilet"
	note has_toilet: "Toilet"
	label define has_toilet 1 "Yes" 0 "No"
	label values has_toilet has_toilet

	label variable has_drinking_water "Drinking water supply"
	note has_drinking_water: "Drinking water supply"
	label define has_drinking_water 1 "Yes" 0 "No"
	label values has_drinking_water has_drinking_water

	label variable has_hot_water "Hot water"
	note has_hot_water: "Hot water"
	label define has_hot_water 1 "Yes" 0 "No"
	label values has_hot_water has_hot_water

	label variable has_electric_power "Electric power"
	note has_electric_power: "Electric power"
	label define has_electric_power 1 "Yes" 0 "No"
	label values has_electric_power has_electric_power

	label variable has_sewerage_system "Sewerage system"
	note has_sewerage_system: "Sewerage system"
	label define has_sewerage_system 1 "Yes" 0 "No"
	label values has_sewerage_system has_sewerage_system

	label variable has_heating "Heating"
	note has_heating: "Heating"
	label define has_heating 1 "Yes" 0 "No"
	label values has_heating has_heating

	label variable has_mobile_phone "Mobile Phone"
	note has_mobile_phone: "Mobile Phone"
	label define has_mobile_phone 1 "Yes" 0 "No"
	label values has_mobile_phone has_mobile_phone

	label variable has_garbage "Garbage"
	note has_garbage: "Garbage"
	label define has_garbage 1 "Yes" 0 "No"
	label values has_garbage has_garbage

	label variable has_attic "Attic"
	note has_attic: "Attic"
	label define has_attic 1 "Yes" 0 "No"
	label values has_attic has_attic

	label variable has_balcony "Balcony"
	note has_balcony: "Balcony"
	label define has_balcony 1 "Yes" 0 "No"
	label values has_balcony has_balcony

	label variable has_garden "Garden"
	note has_garden: "Garden"
	label define has_garden 1 "Yes" 0 "No"
	label values has_garden has_garden

	label variable has_shanty "Shanty"
	note has_shanty: "Shanty"
	label define has_shanty 1 "Yes" 0 "No"
	label values has_shanty has_shanty

	label variable other "Other"
	note other: "Other"
	label define other 1 "Yes" 0 "No"
	label values other other

	label variable water_appliance "If hot water is available, what kind of installation or appliance you mainly use"
	note water_appliance: "If hot water is available, what kind of installation or appliance you mainly use?"
	label define water_appliance 1 "Electric boiler" 2 "Gas-fired boiler" 3 "Outside water heating system" 4 "Other"
	label values water_appliance water_appliance

	label variable heat_source "In what way is heat supplied to this dwelling?"
	note heat_source: "In what way is heat supplied to this dwelling?"
	label define heat_source 1 "Central heating by heating plant" 2 "Self-provided heating by the dwelling" 3 "Single equipment-apparatus" 4 "Other"
	label values heat_source heat_source

	label variable fuels_used "What fuels are used for heating in this dwelling?"
	note fuels_used: "What fuels are used for heating in this dwelling?"
	label define fuels_used 1 "Mazut, heating fuel or other liquid combustible" 2 "Gas by city network" 3 "Gas in gas cylinders" 4 "Electricity" 5 "Coal, firewood and other solid materials" 6 "Other"
	label values fuels_used fuels_used

	label variable util_exp_electric_power "How much did you pay for your last monthly bill for electric power?"
	note util_exp_electric_power: "How much did you pay for your last monthly bill for electric power?"

	label variable util_exp_gas "How much did you pay for your last monthly bill for gas?"
	note util_exp_gas: "How much did you pay for your last monthly bill for gas?"

	label variable util_exp_mobile_services "How much did you pay for your last monthly bill for mobile phone services?"
	note util_exp_mobile_services: "How much did you pay for your last monthly bill for mobile phone services?"

	label variable util_exp_heating "How much did you pay for your last monthly bill for heating?"
	note util_exp_heating: "How much did you pay for your last monthly bill for heating?"

	label variable util_exp_water_and_sewerage "How much did you pay for your last monthly bill for water and sewerage?"
	note util_exp_water_and_sewerage: "How much did you pay for your last monthly bill for water and sewerage?"

	label variable util_exp_common "How much did you pay for your last monthly bill for common expenditures?"
	note util_exp_common: "How much did you pay for your last monthly bill for common expenditures?"

	label variable util_exp_waste_removal "How much did you pay for your last monthly bill for waste removal?"
	note util_exp_waste_removal: "How much did you pay for your last monthly bill for waste removal?"

	label variable maint_exp_paint "How much did you pay for your last monthly bill for painting-related maintenance"
	note maint_exp_paint: "How much did you pay for your last monthly bill for painting-related maintenance expenditures?"

	label variable maint_exp_sanitary "How much did you pay for your last monthly bill for painting-related maintenance"
	note maint_exp_sanitary: "How much did you pay for your last monthly bill for painting-related maintenance expenditures?"

	label variable maint_exp_elec_heat "How much did you pay for your last monthly bill for electricity- and heating-rel"
	note maint_exp_elec_heat: "How much did you pay for your last monthly bill for electricity- and heating-related maintenance expenditures?"

	label variable maint_exp_internal "How much did you pay for your last monthly bill for internal works-related maint"
	note maint_exp_internal: "How much did you pay for your last monthly bill for internal works-related maintenance expenditures?"

	label variable maint_exp_external "How much did you pay for your last monthly bill for external works-related maint"
	note maint_exp_external: "How much did you pay for your last monthly bill for external works-related maintenance expenditures?"

	label variable maint_exp_other "How much did you pay for your last monthly bill for other maintenance expenditur"
	note maint_exp_other: "How much did you pay for your last monthly bill for other maintenance expenditures?"

	label variable confirmation_2 "Was your total utility- and maintenance-related monthly expenditure last month w"
	note confirmation_2: "Was your total utility- and maintenance-related monthly expenditure last month was approximately \${total_util-maint_expenses} Kenyan shilling?"
	label define confirmation_2 1 "Yes" 0 "No"
	label values confirmation_2 confirmation_2

	label variable add_exp_name "For what else did you make utility- and maintenance-related expenditures in the "
	note add_exp_name: "For what else did you make utility- and maintenance-related expenditures in the last month?"

	label variable add_exp_sum "What was the total sum of the expenditure(s)?"
	note add_exp_sum: "What was the total sum of the expenditure(s)?"

	label variable satisf_overall "On a scale of 1-10, how satisfied are you with your dwelling's overall facilitie"
	note satisf_overall: "On a scale of 1-10, how satisfied are you with your dwelling's overall facilities?"
	label define satisf_overall 1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6" 7 "7" 8 "8" 9 "9" 10 "10"
	label values satisf_overall satisf_overall

	label variable satisf_hydrosan "On a scale of 1-10, how satisfied are you with your dwelling's hydro-sanitary fa"
	note satisf_hydrosan: "On a scale of 1-10, how satisfied are you with your dwelling's hydro-sanitary facilities?"
	label define satisf_hydrosan 1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6" 7 "7" 8 "8" 9 "9" 10 "10"
	label values satisf_hydrosan satisf_hydrosan

	label variable satisf_elecheat "On a scale of 1-10, how satisfied are you with your dwelling's electrical and he"
	note satisf_elecheat: "On a scale of 1-10, how satisfied are you with your dwelling's electrical and heating facilities?"
	label define satisf_elecheat 1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6" 7 "7" 8 "8" 9 "9" 10 "10"
	label values satisf_elecheat satisf_elecheat

	label variable satisf_gas "On a scale of 1-10, how satisfied are you with your dwelling's gas facilities?"
	note satisf_gas: "On a scale of 1-10, how satisfied are you with your dwelling's gas facilities?"
	label define satisf_gas 1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6" 7 "7" 8 "8" 9 "9" 10 "10"
	label values satisf_gas satisf_gas

	label variable satisf_dwellstruc "On a scale of 1-10, how satisfied are you with your dwelling's structural soundn"
	note satisf_dwellstruc: "On a scale of 1-10, how satisfied are you with your dwelling's structural soundness?"
	label define satisf_dwellstruc 1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6" 7 "7" 8 "8" 9 "9" 10 "10"
	label values satisf_dwellstruc satisf_dwellstruc

	label variable earning_mem_number "How many members monetarily contribute to household expenditures?"
	note earning_mem_number: "How many members monetarily contribute to household expenditures?"

	label variable earning_hh_rent_land "How much did the household earn through renting out its land and property last m"
	note earning_hh_rent_land: "How much did the household earn through renting out its land and property last month?"

	label variable earning_hh_rent_other "How much did the household earn through rents from other equipment like cattle, "
	note earning_hh_rent_other: "How much did the household earn through rents from other equipment like cattle, machinery, etc. last month?"

	label variable earning_hh_invst "How much did the household earn in interest from savings and dividends last mont"
	note earning_hh_invst: "How much did the household earn in interest from savings and dividends last month?"

	label variable additional_finance_source "How did you fund the remaining utility- and maitenance-related expenses last mon"
	note additional_finance_source: "How did you fund the remaining utility- and maitenance-related expenses last month?"

	label variable additional_finance_amt "What was the total amount of this additional funding to meet your utility- and m"
	note additional_finance_amt: "What was the total amount of this additional funding to meet your utility- and maitenance-related expenses last month?"

	label variable unreported_jnc "I have declared all my income sources in this survey"
	note unreported_jnc: "I have declared all my income sources in this survey"

	label variable support_village_head "I voted for the incumbent village head in the last election"
	note support_village_head: "I voted for the incumbent village head in the last election"

	label variable deposit_savings "I deposited some of my income into a saving accounts in the last six months"
	note deposit_savings: "I deposited some of my income into a saving accounts in the last six months"

	label variable hh_own "I own the establishment in which I am currently residing"
	note hh_own: "I own the establishment in which I am currently residing"

	label variable hh_rent "I have not defaulted on my rent payment in the last six months"
	note hh_rent: "I have not defaulted on my rent payment in the last six months"

	label variable sensitive_hidden_inc "Please select how many of the statements above apply to you."
	note sensitive_hidden_inc: "Please select how many of the statements above apply to you."



	capture {
		foreach rgvar of varlist earning_member_name_* {
			label variable `rgvar' "Earning member \${earning_member_index} name:"
			note `rgvar': "Earning member \${earning_member_index} name:"
		}
	}

	capture {
		foreach rgvar of varlist earning_member_age_* {
			label variable `rgvar' "Earning member \${earning_member_index} age:"
			note `rgvar': "Earning member \${earning_member_index} age:"
		}
	}

	capture {
		foreach rgvar of varlist earning_member_salary_* {
			label variable `rgvar' "How much did \${earning_member_name} earn from salaried work last month?"
			note `rgvar': "How much did \${earning_member_name} earn from salaried work last month?"
		}
	}

	capture {
		foreach rgvar of varlist earning_member_other_* {
			label variable `rgvar' "How much did \${earning_member_name} earn in other income last month?"
			note `rgvar': "How much did \${earning_member_name} earn in other income last month?"
		}
	}

	capture {
		foreach rgvar of varlist earning_member_social_ass_* {
			label variable `rgvar' "How much did \${earning_member_name} receive in social assistance last month?"
			note `rgvar': "How much did \${earning_member_name} receive in social assistance last month?"
		}
	}

	capture {
		foreach rgvar of varlist earning_member_self_* {
			label variable `rgvar' "How much did \${earning_member_name} earn from self-employed work last month?"
			note `rgvar': "How much did \${earning_member_name} earn from self-employed work last month?"
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
*   Corrections file path and filename:  ynd_week6_corrections.csv
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
						replace value=string(clock(value,"DMYhms",2025),"%25.0g") if strmatch(fieldname,"`dtvar'")
						* allow for cases where seconds haven't been specified
						replace value=string(clock(origvalue,"DMYhm",2025),"%25.0g") if strmatch(fieldname,"`dtvar'") & value=="." & origvalue~="."
						drop origvalue
					}
				}
			}
			if "`date_fields`i''" ~= "" {
				foreach dtvar in `date_fields`i'' {
					* skip fields that aren't yet in the data
					cap unab dtvarignore : `dtvar'
					if _rc==0 {
						replace value=string(clock(value,"DMY",2025),"%25.0g") if strmatch(fieldname,"`dtvar'")
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
