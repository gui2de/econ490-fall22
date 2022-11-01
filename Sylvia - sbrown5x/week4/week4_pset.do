/* --------------------------------

BEFORE RUNNING THIS CODE: CHANGE DIRECTORY BELOW TO THE FILEPATH TO YOUR VERSION OF THE BOX FOLDER IN YOUR LAPTOP

 --------------------------------*/

clear
cd "/Users/sylviabrown/Library/CloudStorage/Box-Box/Econ490_Fall2022/Week4/04_assignment"
* ^^^^^^^^^^^^^^^^ THIS IS WHERE YOU NEED TO UPDATE THE FILE PATH ^^^^^^^^^^^^^^^^

/* ------------

QUESTION 1

 -------------*/

use "data/village_pixel.dta", clear /// load in data

*-----Question 1a): Determine if the payout variable is consistent within a pixel-----
bysort pixel: egen pixel_consistent_min = min(payout) // find minimum payout value within each pixel
bysort pixel: egen pixel_consistent_max = max(payout) // find maximum payout value within each pixel
gen pixel_consistent = 0 if pixel_consistent_min == pixel_consistent_max // generate a dummy for if payouts are consistent within pixels
replace pixel_consistent = 1 if pixel_consistent_min ~= pixel_consistent_max // replace dummy with 1 if payout is not consistent within pixel
label define pixel_consistent 0 "payouts are consistent within pixel type" 1 "payouts are not consistent within pixel type" // add labels to dummy variable
tab pixel_consistent // check that payout is indeed consistent within pixel by tabulating our new dummy variable

display "RESULT: Payout is indeed consistent within each pixel"

*-----Question 1b): Determine if the households within a particular village are always within the same pixel-----
gen pixel_new = substr(pixel, 3, 4) // extract just numerical component of pixel
destring pixel_new, replace // turn new pixel variable into numeric variable
bysort village: egen pixel_village_min = min(pixel_new) // find minimum pixel value within village
bysort village: egen pixel_village_max = max(pixel_new) // find maximum pixel value within village
gen pixel_village = 0 if pixel_village_min == pixel_village_max // generate a dummy for if households from village are in more than one pixel
replace pixel_village = 1 if pixel_village_min ~= pixel_village_max // replace dummy with 1 if households in village appear in more than one pixel
label define pixel_village 0 "village appears in a single pixel" 1 "village appears in more than one pixel" // add labels to dummy variable 
tab pixel_village // check if all households in any given village appear within a single pixel

display "RESULT: Not all households in any given village appear within a single pixel"

*-----Question 1c): create new variable that divides households into three categories-----
bysort village: egen village_payout_min = min(payout) // find minimum payout value within each village
bysort village: egen village_payout_max = max(payout) // find maximum payout value within each village
gen village_payout_consistent = 0 if village_payout_min == village_payout_max // generate a dummy for if payouts are consistent within villages
replace village_payout_consistent = 1 if village_payout_min ~= village_payout_max // replace dummy with 1 if payout is not consistent within village
label define village_payout_consistent 0 "payouts are consistent within village" 1 "payouts are not consistent within village" // add labels to dummy variable 

gen villages_pixels_payout = 3 if village_payout_consistent == 1 & pixel_village == 1 // create variable with value 3 where village is in different pixels and has different payout statuses within the village
replace villages_pixels_payout = 2 if village_payout_consistent == 0 & pixel_village == 1 // create variable with value 2 where village is in different pixels and has same payout status within the village
replace villages_pixels_payout = 1 if village_payout_consistent == 0 & pixel_village == 0 // create variable with value 1 where village is in same pixel and has same payout status within the village
label define villages_pixels_payout 1 "within village - same pixel, same payout status" 2 "within village - different pixels, same payout status" 3 "within village - different pixels, different payout statuses" // add labels to new variable 
tab villages_pixels_payout // confirm that new villages_pixels_payout variable is mutually exclusive and completely exhaustive

* Generate list of household IDs for households in villages where the village is in different pixels AND every household in village has the same payout status 
tab hhid if villages_pixels_payout == 2

/* ------------

QUESTION 2

 -------------*/
 
clear

* create a tempfile
tempfile question2
save `question2', replace emptyok

* loop through and clean every school webpage
forvalues i=1/138 {
	use "data/psle_student_raw.dta", clear // load data
	keep in `i' // keep ith observation (where each observation is a separate webpage with test results)
	
	split s, parse(">SUBJECTS") // get rid of the code before "Subjects," as determined by eyeballing the data
	drop s s1 // drop unnecessary variables
	split s2, parse("</TD></TR>") gen(var) // parse data so that each student represents a new columns/variable in the data
	
	gen serial = _n // create a variable that is length of the data set
	reshape long var, i(serial) j(j) // reshape the data so that each observation is a student
	
	* drop first and last observations, which do not contain student information
	drop in 1
	drop in L
	
	split var, parse("</FONT>") // separate var into columns separated by "</FONT>" so that each columns on the webpage has its own column for the data
	keep schoolcode var1 var2 var3 var4 var5 // keep only the necessary variables
	
	replace var1 = substr(var1,-14,.) // clean string with candidate number to keep only the candidate number
	
	replace var2 = substr(var2,-11,.) // clean string with premium number to keep only the premium number
	
	replace var3 = substr(var3,-1,.) // clean string with sex to keep only the sex
	
	replace var4 = substr(var4,70,.) // clean string with candidate name to keep only the candidate name
	
	replace var5 = substr(var5,84,.) // clean string with candidate grades to keep only the grade information
	
	split var5, parse(", ") // separate grades for separate classes so that they are each in their own variable/column
	drop var5 // drop unnecessary variable that we have just split into new variables
	
	* drop name of course from grade information variables
	forvalues i=1/7{
		replace var5`i' = substr(var5`i',-1,.)
	}
	
	* rename all variables to something more easily interpretable
	rename var1 candidate_num
	rename var2 prem_num
	rename var3 sex
	rename var4 candidate_name
	rename var51 kiswahili
	rename var52 english
	rename var53 maarifa
	rename var54 hisabati
	rename var55 science
	rename var56 uraia
	rename var57 average_grade
	
	* append new students to tempfile
	append using `question2'
	save `question2', replace
}

* view completed tempfile with all students across school webpages
use `question2', clear
 
 /* ------------

QUESTION 3

 -------------*/

clear
global excel_t21 "data/Pakistan_district_table21.xlsx" // set global data as Excel data

* setting up an empty tempfile
tempfile table21
save `table21', replace emptyok

* run a loop through all the excel sheets and append cleaned data to tempfile
forvalues i=1/135 {
	local j = 1
	import excel "$excel_t21", sheet("Table `i'") firstrow clear allstring //import Excel table
	display as error `i' //display the loop number

	keep if regex(TABLE21PAKISTANICITIZEN1, "18 AND") == 1 //keep only those rows that have "18 AND"
	keep in 1 // keep only the first row that mentions "18 AND"
	
	* drop variables with no values
	foreach var of varlist _all {
		if missing(`var') {
        drop `var'
		}
	}
	
	* after dropping empty variables, rename variables so that names follow sequentially
	foreach var of varlist _all {
		rename `var' v_`j'
		local j = `j' + 1
	}	
	
	* rename first variable as table21
	rename v_1 table21
	
	* replace variables where only value is "-" to empty values
	foreach var of varlist _all {
		if strpos(`var', "- ") | `var' == "-" {
			replace `var' = ""
		}
	}

	gen table=`i' //to keep track of the sheet we imported the data from
	append using `table21' //adding the rows to the tempfile
	save `table21', replace //saving the tempfile so that we don't lose any data
}
*load the tempfile
use `table21', clear

* ------ spot cleaning (chosen based on eyeballing and tabulating the data) ------
replace v_12 = "1" if table == 115
replace v_13 = "" if table == 115

replace v_12 = "" if v_12 == "-1"
replace v_13 = "1" if v_12 == "-1"

replace v_12 = "" if v_12 == "-4"
replace v_13 = "4" if v_12 == "-4"

replace table21 = "18 AND ABOVE" if strpos(table21, "OVERALL") > 0 | table21 == "18 OR ABOV" | table21 == "18 OR ABOVE" | table21 == "18 AND ABOV"

* ------ Final Steps ------
* turn numeric variable into string
tostring table, replace

* fix column width issue so that it's easy to eyeball the data
format %40s table21 v_2 v_3 v_4 v_5 v_6 v_7 v_8 v_9 v_10 v_11 v_12 v_13 table

* add labels to variables
label variable v_2 "all sexes - total population"
label variable v_3 "all sexes - cni card obtained"
label variable v_4 "all sexes - cni card not obtained"
label variable v_5 "male - total population"
label variable v_6 "male - cni card obtained"
label variable v_7 "male - cni card not obtained"
label variable v_8 "female - total population"
label variable v_9 "female - cni card obtained"
label variable v_10 "female - cni card not obtained"
label variable v_11 "transgender - total population"
label variable v_12 "transgender - cni card obtained"
label variable v_13 "transgender - cni card not obtained"
 
* save final version of file 
save `table21', replace

* load the tempfile
use `table21', clear

 /* ------------

QUESTION 4

 -------------*/
clear

use "data/grant_prop_review_2022.dta", clear // upload data

* rename variable names with typos
rename Rewiewer1 Reviewer1
rename Review1Score Reviewer1Score

local students ahs103 am3944 ass95 ato12 bp557 fg443 ft227 glp38 mp1792 nbs56 nd549 oo140 sa1600 scb136 yc577 ynd3 // generate local macro with list of student reviewer IDs
local reviewers Reviewer1 Reviewer2 Reviewer3 // generate local macro with list of reviewer names

* create variable for each student reviewer's ratings (empty, with ratings to be added at a later step)
foreach name in `students'{
	gen `name' = .
}

* create new standardized score variables (empty, to be calculated at a later step)
foreach reviewer in `reviewers'{
	gen stand_`reviewer'_score = .
}

* add ratings for each student reviewer to student reviewer's variable
foreach name in `students' {
		foreach reviewer in `reviewers' {
		replace `name' = `reviewer'Score if `reviewer' == "`name'"
	}
}

* calculate standardized scores
foreach name in `students'{
	foreach reviewer in `reviewers'{
		quietly summarize `name'
		replace stand_`reviewer'_score = (`reviewer'Score - r(mean))/r(sd) if `reviewer' == "`name'"
	}
}

* drop variables for each student reviewer, because they are no longer needed
drop `students'

* generate variable with average standardized score
gen average_stand_score = (stand_Reviewer1_score + stand_Reviewer2_score + stand_Reviewer3_score)/3

* rename variables to names requested in assignment document
rename stand_Reviewer1_score stand_r1_score
rename stand_Reviewer2_score stand_r2_score
rename stand_Reviewer3_score stand_r3_score

* create rank variable based on average standardized score
egen rank = rank(-average_stand_score)

