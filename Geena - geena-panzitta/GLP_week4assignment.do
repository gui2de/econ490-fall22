********************************************************************************
* Econ 490: Week 4
* Week 4 Assignment
* Geena Panzitta
* October 2, 2022
********************************************************************************

set more off
clear

//change working directory here
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

gen pixel_consistent = .
label variable pixel_consistent "Are payouts consistent without pixel?"

bysort pixel: egen pixel_payout_min = min(payout)
bysort pixel: egen pixel_payout_max = max(payout)
label variable pixel_payout_min "Maximum payout within pixel"
label variable pixel_payout_max "Maximum payout within pixel"

replace pixel_consistent = 0 if pixel_payout_min == pixel_payout_max
replace pixel_consistent = 1 if pixel_payout_min != pixel_payout_max
label define pixel_consistent 0 "Payouts are consistent within pixel." 1 "Payouts are not consistent within pixel."

tab pixel_consistent

//The payout is consistent within each pixel.

}
/*******************************************************************************
Q1. b
*******************************************************************************/
{

gen pixel_numerical = substr(pixel,3,.)
destring(pixel_numerical), replace


gen pixel_village = .
label variable pixel_village "Is the village within one pixel?"

bysort village: egen pixel_min = min(pixel_numerical)
bysort village: egen pixel_max = max(pixel_numerical)
label variable pixel_min "Minimum pixel within village"
label variable pixel_max "Maximum pixel within village"

replace pixel_village = 0 if pixel_min == pixel_max
replace pixel_village = 1 if pixel_min != pixel_max
label define pixel_village 0 "Village is within one pixel." 1 "Village is in multiple pixels."

}
/*******************************************************************************
Q1. c
*******************************************************************************/
{

gen village_consistent = .
label variable village_consistent "Which category does the village fall into?"

bysort village: egen village_payout_min = min(payout)
bysort village: egen village_payout_max = max(payout)
label variable pixel_payout_min "Minimum payout within village"
label variable pixel_payout_max "Maximum payout within village"

replace village_consistent = 1 if pixel_village == 0
replace village_consistent = 2 if pixel_village == 1 & village_payout_min == village_payout_max
replace village_consistent = 3 if pixel_village == 1 & village_payout_min != village_payout_max
label define village_consistent 1 "Village is within one pixel." 2 "Village is in multiple pixels and payouts are consistent within village." 3 "Village is in multiple pixels and payouts are not consistent within village."

list hhid if village_consistent == 2

}
/*******************************************************************************
Q2.
*******************************************************************************/
{

clear

tempfile allstudents
save `allstudents', replace emptyok

forvalues i=1/138 {
	display as error `i'
	use psle_student_raw.dta, clear
	keep in `i'
	//begin: code from hint_q2
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
	//end: code from hint_q2
	append using `allstudents'
	save `allstudents', replace
}

use `allstudents', clear

}
/*******************************************************************************
Q3.
*******************************************************************************/
{
	
global excel_t21 "Pakistan_district_table21.xlsx"

clear

tempfile table21
save `table21', replace emptyok

forvalues i=1/135 {
	//begin: code from hint_q3
	display as error `i'
	import excel "$excel_t21", sheet("Table `i'") firstrow clear allstring
	keep if regex(TABLE21PAKISTANICITIZEN1, "18 AND" ) == 1
	keep in 1
	rename TABLE21PAKISTANICITIZEN1 table21
	gen table = `i'
	//end: code from hint_q3
	
	//fixing errors
	if table == 36 | table == 106 | table == 126 | table == 133 { //tables with "- - -" in one column
		replace U = "-"
		replace V = "-"
		replace W = "-"
	}
	if table == 115 { //table with "1 -" in one column
		replace W = "1"
		replace X = "-"
	}
	
	//dropping columns with missing values
	if table == 34 | table == 105 | table == 110 | table == 117 { //tables with missing last value
		foreach col of varlist table21-W table {
			if missing(`col') {
			drop `col'
			}
		}
	}
	if table == 124 { //table with missing last value and extra blank
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
	
	//making sure columns names are consistent
	local varnum = 1
	foreach col of var _all {
		rename `col' var_`varnum'
		local varnum = `varnum' + 1
	}

	//making columns with "-" or negative numbers blank
	tostring var_14, replace //to make regex work
	foreach col of varlist _all {
		if regex(`col', "-" ) == 1 {
			replace `col' = ""
		}
	}

	append using `table21'
	save `table21', replace
}

use `table21', clear

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

order table
sort table

}
/*******************************************************************************
Q4.
*******************************************************************************/
{
	
clear

use grant_prop_review_2022.dta, clear

global students ahs103 am3944 ass95 ato12 bp557 fg443 ft227 glp38 mp1792 nbs56 nd549 oo140 sa1600 scb136 yc577 ynd3

rename (Rewiewer1 Review1Score) (Reviewer1 Reviewer1Score)

foreach i in $students {
	gen score_`i' = .
	gen mean_`i' = .
	gen sd_`i' = .
}

foreach i in $students {
	forvalues j = 1/3 {
		replace score_`i' = Reviewer`j'Score if Reviewer`j' == "`i'"
	}
}

foreach i in $students {
	quietly sum score_`i' if score_`i' != .
	replace mean_`i' = r(mean)
	replace sd_`i' = r(sd)
}

forvalues j = 1/3 {
	gen stand_r`j'_score = .
}

foreach i in $students {
	forvalues j = 1/3 {
		if Reviewer`j' == "`i'" {
			replace stand_r`j'_score = (Reviewer`j'Score - mean_`i')/sd_`i'
		}
	}
}

gen average_stand_score = (stand_r1_score + stand_r2_score + stand_r3_score) / 3

foreach i in $students {
	drop score_`i' mean_`i' sd_`i'
}

egen rank = rank(-average_stand_score)

}
