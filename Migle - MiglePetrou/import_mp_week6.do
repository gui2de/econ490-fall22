* import_mp_week6.do
*
* 	Imports and aggregates "mp_week6" (ID: mp_week6) data.
*
*	Inputs:  "mp_week6_WIDE.csv"
*	Outputs: "mp_week6.dta"
*
*	Output by SurveyCTO December 7, 2022 2:57 AM.

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
local csvfile "mp_week6_WIDE.csv"
local dtafile "mp_week6.dta"
local corrfile "mp_week6_corrections.csv"
local note_fields1 ""
local text_fields1 "deviceid subscriberid simid devicephonenum username duration caseid sample_name sample_email users pub_to_users last_survey_status num_calls call_num callback_time now_complete survey_status name"
local text_fields2 "email total_shower_time habit_selection n_habits usage_habits_count habit_index_* habit_i_* habit_label_* fin_sources continent_pullcsv race other zip reschedule_full reschedule_no_ans instanceid"
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

	label variable name "What is your name?"
	note name: "What is your name?"

	label variable email "What is your email address?"
	note email: "What is your email address?"

	label variable age "What is your age?"
	note age: "What is your age?"

	label variable heating "How do you typically heat your home?"
	note heating: "How do you typically heat your home?"
	label define heating 1 "Electricity" 2 "Gas" 3 "Oil" 4 "Renewable sources (geothermal, solar, wood, heat pump)" 5 "Don't know / prefer not to say"
	label values heating heating

	label variable heating_expenses "What were your heating expenses last month?"
	note heating_expenses: "What were your heating expenses last month?"
	label define heating_expenses 1 "Less than \$20" 2 "\$20–75" 3 "\$76–125" 4 "\$126–200" 5 "More than \$200" 99 "Not sure / Prefer not to say"
	label values heating_expenses heating_expenses

	label variable transport_expenses "How much money did you spend on gas for driving last month?"
	note transport_expenses: "How much money did you spend on gas for driving last month?"
	label define transport_expenses 1 "Less than \$5" 2 "\$5–25" 3 "\$26–75" 4 "\$76–125" 5 "\$126–175" 6 "\$176–225" 7 "More than \$225"
	label values transport_expenses transport_expenses

	label variable roundtrips "How many roundtrip flights did you take between January 2021 and January 2022?"
	note roundtrips: "How many roundtrip flights did you take between January 2021 and January 2022?"
	label define roundtrips 1 "0" 2 "1" 3 "2" 4 "3 or 4" 5 "5 to 7" 6 "8 to 14" 7 "15 or more"
	label values roundtrips roundtrips

	label variable beef "How often do you eat beef?"
	note beef: "How often do you eat beef?"
	label define beef 1 "Never" 2 "Less than once a week" 3 "One to four times a week" 4 "Almost or at least daily"
	label values beef beef

	label variable commute "What is your primary mode of transportation for commuting to work/university?"
	note commute: "What is your primary mode of transportation for commuting to work/university?"
	label define commute 1 "Car or motorbike" 2 "Public transport (e.g., bus, tram, metro)" 3 "Carpool" 4 "Bike or walking" 99 "None of the above"
	label values commute commute

	label variable groceries "What is your primary mode of transportation to go grocery shopping?"
	note groceries: "What is your primary mode of transportation to go grocery shopping?"
	label define groceries 1 "Car or motorbike" 2 "Public transport (e.g., bus, tram, metro)" 3 "Carpool" 4 "Bike or walking" 99 "None of the above"
	label values groceries groceries

	label variable leisure "What is your primary mode of transportation for leisure activities?"
	note leisure: "What is your primary mode of transportation for leisure activities?"
	label define leisure 1 "Car or motorbike" 2 "Public transport (e.g., bus, tram, metro)" 3 "Carpool" 4 "Bike or walking" 99 "None of the above"
	label values leisure leisure

	label variable access "How do you rate public transport accessibility where you live?"
	note access: "How do you rate public transport accessibility where you live?"
	label define access 1 "Very poor" 2 "Poor" 3 "Fair" 4 "Good" 5 "Excellent" 99 "There are no public transport options near me"
	label values access access

	label variable shower_time "How many hours a week do you spend in the shower?"
	note shower_time: "How many hours a week do you spend in the shower?"

	label variable habit_selection "How many of the following did you engage in last week?"
	note habit_selection: "How many of the following did you engage in last week?"

	label variable cchange_real "Please take your time and tell us how many of the following statements you agree"
	note cchange_real: "Please take your time and tell us how many of the following statements you agree with. We do not need to know which ones, just how many: (1) It is important to presevere the Earth's ecosystems (2) Low-lying countries and island nations would be threatened if sea levels were rising (3) Climate change (beyond regular weather fluctuations) is real (4) Illegal deforestation in the Brazilian Amazonia should be stopped"

	label variable cchange "How often do you think or talk with people about climate change?"
	note cchange: "How often do you think or talk with people about climate change?"
	label define cchange 1 "Almost never" 2 "Several times a year" 3 "Several times a month"
	label values cchange cchange

	label variable human_activity "What part of climate change do you think is due to human activity?"
	note human_activity: "What part of climate change do you think is due to human activity?"
	label define human_activity 1 "None" 2 "A little" 3 "Some" 4 "A lot" 5 "Most"
	label values human_activity human_activity

	label variable cchange_important "Do you agree or disagree that climate change is an important problem?"
	note cchange_important: "Do you agree or disagree that climate change is an important problem?"
	label define cchange_important 1 "Strongly disagree" 2 "Disagree" 3 "Neither agree nor disagree" 4 "Agree" 5 "Strongly agree"
	label values cchange_important cchange_important

	label variable knoweldgeable "How knowledgeable do you consider yourself to be about climate change?"
	note knoweldgeable: "How knowledgeable do you consider yourself to be about climate change?"
	label define knoweldgeable 1 "Not at all" 2 "A little" 3 "Moderately" 4 "Greatly" 99 "Unsure"
	label values knoweldgeable knoweldgeable

	label variable personal_life "To what extent do you think climate change already affects or will affect your p"
	note personal_life: "To what extent do you think climate change already affects or will affect your personal life negatively?"
	label define personal_life 1 "Not at all" 2 "A little" 3 "Moderately" 4 "Greatly" 99 "Unsure"
	label values personal_life personal_life

	label variable halting "To what extent do you think that it is technically feasible to stop greenhouse g"
	note halting: "To what extent do you think that it is technically feasible to stop greenhouse gas emissions by the end of the century while maintaining satisfactory standards of living in the U.S.?"
	label define halting 1 "Not at all" 2 "A little" 3 "Moderately" 4 "Greatly" 99 "Unsure"
	label values halting halting

	label variable effect_us_economy "If we decide to halt climate change through ambitious policies, what would be th"
	note effect_us_economy: "If we decide to halt climate change through ambitious policies, what would be the effects on the U.S economy and employment?"
	label define effect_us_economy 1 "Very negative" 2 "Somewhat negative" 3 "No noticeable effects" 4 "Somewhat positive" 5 "Very positive"
	label values effect_us_economy effect_us_economy

	label variable effect_lifestyle "If we decide to halt climate change through ambitious policies, to what extent d"
	note effect_lifestyle: "If we decide to halt climate change through ambitious policies, to what extent do you think it would negatively affect your lifestyle?"
	label define effect_lifestyle 1 "Not at all" 2 "A little" 3 "Moderately" 4 "Greatly" 99 "Unsure"
	label values effect_lifestyle effect_lifestyle

	label variable behavscale_fly "Limit flying"
	note behavscale_fly: "Limit flying"
	label define behavscale_fly 1 "Not at all" 2 "A little" 3 "Moderately" 4 "Greatly" 99 "Unsure"
	label values behavscale_fly behavscale_fly

	label variable behavscale_drive "Limit driving"
	note behavscale_drive: "Limit driving"
	label define behavscale_drive 1 "Not at all" 2 "A little" 3 "Moderately" 4 "Greatly" 99 "Unsure"
	label values behavscale_drive behavscale_drive

	label variable behavscale_ev "Switch to a fuel-efficient or electric vehicle"
	note behavscale_ev: "Switch to a fuel-efficient or electric vehicle"
	label define behavscale_ev 1 "Not at all" 2 "A little" 3 "Moderately" 4 "Greatly" 99 "Unsure"
	label values behavscale_ev behavscale_ev

	label variable behavscale_beef "Limit beef consumption"
	note behavscale_beef: "Limit beef consumption"
	label define behavscale_beef 1 "Not at all" 2 "A little" 3 "Moderately" 4 "Greatly" 99 "Unsure"
	label values behavscale_beef behavscale_beef

	label variable behavscale_home "Limit heating or cooling your home"
	note behavscale_home: "Limit heating or cooling your home"
	label define behavscale_home 1 "Not at all" 2 "A little" 3 "Moderately" 4 "Greatly" 99 "Unsure"
	label values behavscale_home behavscale_home

	label variable importancescale_pol "Ambitious climate policies"
	note importancescale_pol: "Ambitious climate policies"
	label define importancescale_pol 1 "Not at all" 2 "A little" 3 "Moderately" 4 "Greatly" 99 "Unsure"
	label values importancescale_pol importancescale_pol

	label variable importancescale_fin "Having enough financial support"
	note importancescale_fin: "Having enough financial support"
	label define importancescale_fin 1 "Not at all" 2 "A little" 3 "Moderately" 4 "Greatly" 99 "Unsure"
	label values importancescale_fin importancescale_fin

	label variable importancescale_beh "People around you also changing their behavior"
	note importancescale_beh: "People around you also changing their behavior"
	label define importancescale_beh 1 "Not at all" 2 "A little" 3 "Moderately" 4 "Greatly" 99 "Unsure"
	label values importancescale_beh importancescale_beh

	label variable importancescale_wealth "The wealthiest also changing their behavior"
	note importancescale_wealth: "The wealthiest also changing their behavior"
	label define importancescale_wealth 1 "Not at all" 2 "A little" 3 "Moderately" 4 "Greatly" 99 "Unsure"
	label values importancescale_wealth importancescale_wealth

	label variable financial_loss_low "Low income earners"
	note financial_loss_low: "Low income earners"
	label define financial_loss_low 1 "Lose a lot" 2 "Mostly lose" 3 "Neither lose nor win" 4 "Mostly win" 5 "Win a lot"
	label values financial_loss_low financial_loss_low

	label variable financial_loss_mi "The middle class"
	note financial_loss_mi: "The middle class"
	label define financial_loss_mi 1 "Lose a lot" 2 "Mostly lose" 3 "Neither lose nor win" 4 "Mostly win" 5 "Win a lot"
	label values financial_loss_mi financial_loss_mi

	label variable financial_loss_hi "High income earners"
	note financial_loss_hi: "High income earners"
	label define financial_loss_hi 1 "Lose a lot" 2 "Mostly lose" 3 "Neither lose nor win" 4 "Mostly win" 5 "Win a lot"
	label values financial_loss_hi financial_loss_hi

	label variable financial_loss_rural "Those living in rural areas"
	note financial_loss_rural: "Those living in rural areas"
	label define financial_loss_rural 1 "Lose a lot" 2 "Mostly lose" 3 "Neither lose nor win" 4 "Mostly win" 5 "Win a lot"
	label values financial_loss_rural financial_loss_rural

	label variable financial_loss_you "Do you think that your household would win or lose financially from a green infr"
	note financial_loss_you: "Do you think that your household would win or lose financially from a green infrastructure program?"
	label define financial_loss_you 1 "Lose a lot" 2 "Mostly lose" 3 "Neither lose nor win" 4 "Mostly win" 5 "Win a lot"
	label values financial_loss_you financial_loss_you

	label variable fair "Do you agree or disagree that a green infrastructure program is fair?"
	note fair: "Do you agree or disagree that a green infrastructure program is fair?"
	label define fair 1 "Strongly disagree" 2 "Disagree" 3 "Neither agree nor disagree" 4 "Agree" 5 "Strongly agree"
	label values fair fair

	label variable support "Do you support or oppose a green infrastructure program?"
	note support: "Do you support or oppose a green infrastructure program?"
	label define support 1 "Strongly oppose" 2 "Oppose" 3 "Neither oppose nor support" 4 "Support" 5 "Strongly support"
	label values support support

	label variable fin_sources "Until now, we have considered that a green infrastructure program would be finan"
	note fin_sources: "Until now, we have considered that a green infrastructure program would be financed by public debt, but other sources of funding are possible. What sources of funding do you find appropriate for public investments in green infrastructure?"

	label variable continent_pullcsv "What continent are you from?"
	note continent_pullcsv: "What continent are you from?"

	label variable gender "Please select your gender."
	note gender: "Please select your gender."
	label define gender 1 "Female" 2 "Male" 3 "Other"
	label values gender gender

	label variable race "What is your race or ethnicity?"
	note race: "What is your race or ethnicity?"

	label variable other "Please specify your race or ethnicity if you chose 'other'"
	note other: "Please specify your race or ethnicity if you chose 'other'"

	label variable marital_status "What is your marital status?"
	note marital_status: "What is your marital status?"
	label define marital_status 1 "Single" 2 "Married" 3 "Divorced or legally separated" 4 "Widowed"
	label values marital_status marital_status

	label variable zip "Please type in the ZIP code of the area where you live"
	note zip: "Please type in the ZIP code of the area where you live"

	label variable homeowner "Are you a homeowner?"
	note homeowner: "Are you a homeowner?"
	label define homeowner 1 "Yes" 0 "No" 999 "Not sure"
	label values homeowner homeowner

	label variable employment_status "What is your current employment status?"
	note employment_status: "What is your current employment status?"
	label define employment_status 1 "Working full-time" 2 "Working part-time" 3 "Self-employed" 4 "Student" 5 "Retired" 6 "Unemployed (looking for opportunities)" 7 "Unemployed (not currently looking for opportunities)"
	label values employment_status employment_status

	label variable income "Which of these describes your personal annual income last year?"
	note income: "Which of these describes your personal annual income last year?"
	label define income 1 "0" 2 "\$1 to \$9 999" 3 "\$10 000 to \$24 999" 4 "\$25 000 to 49 999" 5 "\$50 000 to 74 999" 6 "\$75 000 to 99 999" 7 "\$100 000 to 149 999" 8 "\$150 000 to 200 000" 9 "\$200 000 or greater" 99 "Prefer not to answer"
	label values income income

	label variable hh_wealth "What was your total household income last year?"
	note hh_wealth: "What was your total household income last year?"
	label define hh_wealth 1 "0" 2 "\$1 to \$9 999" 3 "\$10 000 to \$24 999" 4 "\$25 000 to 49 999" 5 "\$50 000 to 74 999" 6 "\$75 000 to 99 999" 7 "\$100 000 to 149 999" 8 "\$150 000 to 200 000" 9 "\$200 000 or greater" 99 "Prefer not to answer"
	label values hh_wealth hh_wealth

	label variable education "Which category best describes the highest level of education you have completed?"
	note education: "Which category best describes the highest level of education you have completed?"
	label define education 1 "No schooling completed" 2 "Primary school" 3 "Secondary school" 4 "High school" 5 "Vocational degree" 6 "College degree" 7 "Master’s degree or above" 99 "Prefer not to say"
	label values education education

	label variable political_leanings "Which do you identify as the most?"
	note political_leanings: "Which do you identify as the most?"
	label define political_leanings 1 "Very liberal" 2 "Liberal" 3 "Moderate" 4 "Conservative" 5 "Very conservative" 6 "Prefer not to say"
	label values political_leanings political_leanings

	label variable economic_leanings "On economic policy matters, where do you see yourself on the liberal/conservativ"
	note economic_leanings: "On economic policy matters, where do you see yourself on the liberal/conservative spectrum?"
	label define economic_leanings 1 "Very liberal" 2 "Liberal" 3 "Moderate" 4 "Conservative" 5 "Very conservative" 6 "Prefer not to say"
	label values economic_leanings economic_leanings

	label variable vote_past "How did you vote in the last selection?"
	note vote_past: "How did you vote in the last selection?"
	label define vote_past 1 "Democrat" 2 "Republican" 3 "Independent" 4 "Did/Could not vote or did not have the right vote" 99 "Prefer not to answer"
	label values vote_past vote_past

	label variable vote_future "How do you intend to vote in the upcoming election?"
	note vote_future: "How do you intend to vote in the upcoming election?"
	label define vote_future 1 "Democrat" 2 "Republican" 3 "Independent" 4 "I don't know" 5 "I don't intend to vote or do not have the right vote" 99 "Prefer not to answer"
	label values vote_future vote_future

	label variable reschedule "ENUMERATOR, read this out loud: When would you like to reschedule the survey? EN"
	note reschedule: "ENUMERATOR, read this out loud: When would you like to reschedule the survey? ENUMERATOR INSTRUCTIONS: When scheduling the callback, check the calendar to make sure you are available for that time. It may take up to ten minutes before the event is published to the calendar."



	capture {
		foreach rgvar of varlist habit_limit_* {
			label variable `rgvar' "Do you think limiting '\${habit_label}' would affect you negatively?"
			note `rgvar': "Do you think limiting '\${habit_label}' would affect you negatively?"
			label define `rgvar' 1 "Yes" 0 "No" 999 "Not sure"
			label values `rgvar' `rgvar'
		}
	}

	capture {
		foreach rgvar of varlist habit_giveup_* {
			label variable `rgvar' "Do you think it is realistic for you to give up '\${habit_label}' entirely?"
			note `rgvar': "Do you think it is realistic for you to give up '\${habit_label}' entirely?"
			label define `rgvar' 1 "Yes" 0 "No" 999 "Not sure"
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
*   Corrections file path and filename:  mp_week6_corrections.csv
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
