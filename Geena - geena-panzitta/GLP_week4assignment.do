********************************************************************************
* Econ 490: Week 4
* Week 4 Assignment
* Geena Panzitta
* October 2, 2022
********************************************************************************

set more off
clear

*Change working directory here
cd "/Users/geenapanzitta/Library/CloudStorage/Box-Box/Econ490_Fall2022/Week4/04_assignment/data"

/*******************************************************************************
Q1.
*******************************************************************************/
{
	
use village_pixel.dta, clear

}
/*******************************************************************************
Q1. a
*******************************************************************************/
{

*Make a dummy variable for whether the payouts are consistent
gen pixel_consistent = .
label variable pixel_consistent "Are payouts consistent without pixel?"

*Generate the minimum and maximum payout for each pixel
bysort pixel: egen pixel_payout_min = min(payout)
bysort pixel: egen pixel_payout_max = max(payout)
label variable pixel_payout_min "Maximum payout within pixel"
label variable pixel_payout_max "Maximum payout within pixel"

*Compare the minimum and maximum to see if they're consistent
replace pixel_consistent = 0 if pixel_payout_min == pixel_payout_max
replace pixel_consistent = 1 if pixel_payout_min != pixel_payout_max
label define pixel_consistent 0 "Payouts are consistent within pixel." 1 "Payouts are not consistent within pixel."

*Tabulate to see if there are any pixels with inconsistent payouts
tab pixel_consistent

*The payout is consistent within each pixel.

}
/*******************************************************************************
Q1. b
*******************************************************************************/
{

*Make a numerical version of pixel so min/max can be found
gen pixel_numerical = substr(pixel,3,.)
destring(pixel_numerical), replace

*Make a dummy for whether the village is within one pixel
gen pixel_village = .
label variable pixel_village "Is the village within one pixel?"

*Generate the minimum and maximum pixel for each village
bysort village: egen pixel_min = min(pixel_numerical)
bysort village: egen pixel_max = max(pixel_numerical)
label variable pixel_min "Minimum pixel within village"
label variable pixel_max "Maximum pixel within village"

*Compare the minimum and maximum to see if they're consistent
replace pixel_village = 0 if pixel_min == pixel_max
replace pixel_village = 1 if pixel_min != pixel_max
label define pixel_village 0 "Village is within one pixel." 1 "Village is in multiple pixels."

}
/*******************************************************************************
Q1. c
*******************************************************************************/
{

*Make a dummy for which category the village falls into
gen village_consistent = .
label variable village_consistent "Which category does the village fall into?"

*Generate the minimum and maximum payout for each village
bysort village: egen village_payout_min = min(payout)
bysort village: egen village_payout_max = max(payout)
label variable pixel_payout_min "Minimum payout within village"
label variable pixel_payout_max "Maximum payout within village"

*Put villages that are within one pixel into category
replace village_consistent = 1 if pixel_village == 0
*Compare the minimum and maximum to see if they're consistent
replace village_consistent = 2 if pixel_village == 1 & village_payout_min == village_payout_max
replace village_consistent = 3 if pixel_village == 1 & village_payout_min != village_payout_max
label define village_consistent 1 "Village is within one pixel." 2 "Village is in multiple pixels and payouts are consistent within village." 3 "Village is in multiple pixels and payouts are not consistent within village."

*Make list of IDs in villages in category 2
list hhid if village_consistent == 2

}
/*******************************************************************************
Q2.
*******************************************************************************/
{

clear

*Create tempfile to hold student data
tempfile allstudents
save `allstudents', replace emptyok

*Loop through each school/each row in dataset
forvalues i=1/138 {
	*Display loop number
	display as error `i'
	*Load dataset and keep just one row
	use psle_student_raw.dta, clear
	keep in `i'
	*Begin: code from hint_q2
	split s, parse(">SUBJECTS")
	split s2, parse("</TD></TR>") gen(var)
	gen serial = _n
	reshape long var, i(serial) j(j)
	split var, parse("</FONT></TD>")
	keep var1 var2 var3 var4 var5 schoolcode
	drop if var2=="" & var3==""
	gen cand_id = substr(var1,-14,.)
	gen gender = substr(var3,-1,.)
	gen prem_number =  substr(var2,strpos(var2, "CENTER") +8, .)
	gen name =  substr(var4,strpos(var4, "<P>") +3 , .)
	replace var5 = substr(var5,ustrpos(var5, "LEFT") +6 , .)
	replace var5 = substr(var5,1 , strlen(var5) - 7)
	split var5, parse(,)
	rename var51 kiswahili
	rename var52 english
	rename var53 maarifa
	rename var54 hisabati
	rename var55 science
	rename var56 uraia
	rename var57 average
	drop var1 var2 var3 var4 var5 
	local varlist "kiswahili english maarifa hisabati science uraia average"
	foreach subject in `varlist'{
		replace `subject' = usubstr(`subject',-1,1)
	}
	*End: code from hint_q2
	*Add data to tempfile
	append using `allstudents'
	save `allstudents', replace
}

*Load tempfile
use `allstudents', clear

}
/*******************************************************************************
Q3.
*******************************************************************************/
{

*Begin: code from hint_q3
global excel_t21 "Pakistan_district_table21.xlsx"

clear

tempfile table21
save `table21', replace emptyok
*End: code from hint_q3

*Loop through each excel sheet
*Begin: code from hint_q3
forvalues i=1/135 {
	display as error `i'
	import excel "$excel_t21", sheet("Table `i'") firstrow clear allstring
	keep if regex(TABLE21PAKISTANICITIZEN1, "18 AND" ) == 1
	keep in 1
	rename TABLE21PAKISTANICITIZEN1 table21
	gen table = `i'
	*End: code from hint_q3
	
	*fixing errors - found during debugging
	if table == 36 | table == 106 | table == 126 | table == 133 { //tables with "- - -" in one column
		replace U = "-"
		replace V = "-"
		replace W = "-"
	}
	if table == 115 { //table with "1 -" in one column
		replace W = "1"
		replace X = "-"
	}
	
	*dropping columns with missing values
	if table == 34 | table == 105 | table == 110 | table == 117 { //tables with missing last value - found during debugging
		foreach col of varlist table21-W table {
			if missing(`col') {
			drop `col'
			}
		}
	}
	if table == 124 { //table with missing last value and extra blank - found during debugging
		foreach col of varlist table21-X table {
			if missing(`col') {
			drop `col'
			}
		}
	}
	if table != 34 & table != 105 & table != 110 & table != 117 & table != 124 { //all other tables
		foreach col of varlist _all {
			if missing(`col') {
			drop `col'
			}
		}
	}
	
	*making sure columns names are consistent
	*Make local variable to count each variable
	local varnum = 1
	foreach col of var _all {
		rename `col' var_`varnum'
		local varnum = `varnum' + 1
	}

	*making columns with "-" or negative numbers blank
	tostring var_14, replace //to make regex work
	foreach col of varlist _all {
		*Check if the column contains "-"
		if regex(`col', "-" ) == 1 {
			replace `col' = ""
		}
	}

	*Add to tempfile of all tables
	append using `table21'
	save `table21', replace
}

*Load tempfile
use `table21', clear

*Drop "18 years and older" in all rows
drop var_1
rename (var_2 var_3 var_4 var_5 var_6 var_7 var_8 var_9 var_10 var_11 var_12 var_13 var_14) (fm_total fm_obtained fm_notobtained m_total m_obtained m_notobtained f_total f_obtained f_notobtained t_total t_obtained t_notobtained table)

label variable table "table number"
label variable fm_total "all sexes, total population"
label variable fm_obtained "all sexes, CNI card obtained"
label variable fm_notobtained "all sexes, CNI card not obtained"
label variable m_total "male, total population"
label variable m_obtained "male, CNI card obtained"
label variable m_notobtained "male, CNI card not obtained"
label variable f_total "female, total population"
label variable f_obtained "female, CNI card obtained"
label variable f_notobtained "female, CNI card not obtained"
label variable t_total "transgender, total population"
label variable t_obtained "transgender, CNI card obtained"
label variable t_notobtained "transgender, CNI card not obtained"

foreach col of varlist _all {
	destring `col', replace
}

*Put table number at the beginning and sort rows by table
order table
sort table

}
/*******************************************************************************
Q4.
*******************************************************************************/
{
	
clear

use grant_prop_review_2022.dta, clear

*Make macro of all students
global students ahs103 am3944 ass95 ato12 bp557 fg443 ft227 glp38 mp1792 nbs56 nd549 oo140 sa1600 scb136 yc577 ynd3

*Rename variables so they're consistent with other variables
rename (Rewiewer1 Review1Score) (Reviewer1 Reviewer1Score)

*Generate a variable to hold the score a student gave a proposal, if they reviewed it, regardless of which reviewer they were
foreach i in $students {
	gen score_`i' = .
	forvalues j = 1/3 {
		replace score_`i' = Reviewer`j'Score if Reviewer`j' == "`i'"
	}
}

*Find the mean and standard deviation by student of all scores
foreach i in $students {
	quietly sum score_`i' if score_`i' != .
	gen mean_`i' = r(mean)
	gen sd_`i' = r(sd)
}

*Generate new variables for standardized scores
forvalues j = 1/3 {
	gen stand_r`j'_score = .
}

*Find standardized scores for each proposal
foreach i in $students {
	forvalues j = 1/3 {
		if Reviewer`j' == "`i'" {
			replace stand_r`j'_score = (Reviewer`j'Score - mean_`i')/sd_`i'
		}
	}
}

*Take the average of the standardized scores
gen average_stand_score = (stand_r1_score + stand_r2_score + stand_r3_score) / 3

*Drop the student variables generated
foreach i in $students {
	drop score_`i' mean_`i' sd_`i'
}

*Generated rank variable by average standardized score
egen rank = rank(-average_stand_score)

}
