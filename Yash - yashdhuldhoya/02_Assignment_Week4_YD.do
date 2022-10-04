********************************************************************************
* Econ 490: Assignment 4
* Yash Dhuldhoya 
* Sep 29, 2022
********************************************************************************


************************* Question 1 ***************************************
** Part A

* Setting working directory 
cd "/Users/devakid/Library/CloudStorage/Box-Box/Econ490_Fall2022/Week4/04_assignment/data"
* Opening data set 
use "/Users/devakid/Library/CloudStorage/Box-Box/Econ490_Fall2022/Week4/04_assignment/data/village_pixel.dta", clear
* Creating the dummy  
bysort pixel: egen pixel_mean_payout = mean(payout)
gen pixel_consistent = 0 
replace pixel_consistent = 1 if pixel_mean_payout != 0 & pixel_mean_payout != 1
* Identifying village names 
tab pixel pixel_mean_payout
/* Payout is consistent with each pixel */


** Part B
* convert pixel variable to categorical variable + inspect categories
encode pixel, generate(pixel_n) 
tab pixel_n, nolabel
* creating the dummy 
bysort village: egen mode_pixel = mode(pixel_n), maxmode
gen pixel_household = 0
replace pixel_household = 1 if mode_pixel != pixel_n
bysort village: egen pixel_village = mean(pixel_household)
replace pixel_village = 1 if pixel_village > 0 
tab pixel_village


** Part C
* creating dummy for consistency in village payout
bysort village: egen village_mean_payout = mean(payout)
gen village_consistent = 1 
replace village_consistent = 0 if village_mean_payout != 0 & village_mean_payout != 1
* creating categorical variable  
gen household_status = 1 if pixel_village == 0
replace household_status = 2 if pixel_village == 1 & village_consistent == 1
replace household_status = 3 if pixel_village == 1 & village_consistent == 0
tab household_status
* label values of categorical variables 
label define household_status 1 "Villages that are entirely in a particular pixel" ///
2 " Villages that are in different pixels with same payout status" ///
3 "Villages that are in different pixels and different payout status"
* List HHID if household_status = 2
list hhid if household_status == 2


************************* Question 2 ***************************************
*Loading the dataset
global wd "/Users/devakid/Library/CloudStorage/Box-Box/"
global psle "$wd/Econ490_Fall2022/Week4/04_assignment/data/psle_student_raw.dta"
use "$psle", clear
levelsof schoolcode, local(code) 		// This generates a list of distinct values in a variable and places them into a local macro 
local y = 0 							// Generating another local macro to help with the appending 

foreach x of local code { 				// creating a loop 
	local y = `y' + 1  
	clear
	use "$psle", clear
	keep if schoolcode == "`x'" 		// keeping only one school code at a time to run the loop slightly more efficiently 
	

*Running Ali's commands 
	split s, parse(">SUBJECTS") 
	split s2, parse("</TD></TR>") gen(var) 
	gen serial = _n
	reshape long var, i(serial) j(j)
	split var, parse("</FONT></TD>")
	keep var1 var2 var3 var4 var5
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

*Saving and appending the file + closing the loop
if `y' == 1 { 							// where z = 1 (for the first school) this creates a temporary file 
	tempfile week_4
	save `week_4', replace
}
	else {								// where z > 1 (for the remaining 137 schools) this appends the file initial temporary file. Saves us the hassle of individually appending each file  
		append using `week_4'
		save `week_4', replace
	}		
}										// end of loop 

use `week_4', clear
split cand_id, p(-)						// generating the school code and candidate id  
rename cand_id1 SchoolCode
rename cand_id2 Cand_id
order SchoolCode Cand_id
browse 


************************* Question 3 ***************************************
global excel_t21 "Pakistan_district_table21.xlsx"
clear
*setting up an empty tempfile
tempfile table21
save `table21', replace emptyok

*Run a loop through all the excel sheets (135) this will take 2-10 mins because it has to import all 135 sheets, one by one
forvalues i=1/135 {
	import excel "$excel_t21", sheet("Table `i'") firstrow clear allstring //import
	
	display as error `i' //display the loop number

	keep if regex(TABLE21PAKISTANICITIZEN1, "18 AND" )==1 //keep only those rows that have "18 AND"
	*I'm using regex because the following code won't work if there are any trailing/leading blanks
	*keep if TABLE21PAKISTANICITIZEN1== "18 AND" 
	keep in 1 //there are 3 of them, but we want the first one
	rename TABLE21PAKISTANICITIZEN1 table21
	
	** Cleaning each table 
	destring, replace 
	foreach x in B C D E F G H I J K L M N O P Q R S T U V W X Y Z AA AB AC {
	cap sum `x'
		if _rc == 0 {
			if r(N) == 0 {
				drop `x'
			}
		}
	}
		
	gen table=`i' //to keep track of the sheet we imported the data from
	append using `table21' //adding the rows to the tempfile
	save `table21', replace //saving the tempfile so that we don't lose any data
}

*load the tempfile
format %40s table21 
use `table21', clear


foreach var in B C D E F G H I J K L M N O P Q R S T U V W X Y Z AA AB  {
	replace `var'=abs(`var')
}
replace table21 = "18 AND ABOVE" if strpos(table21, "OVERALL") > 0 ///
| table21 == "18 OR ABOV" | table21 == "18 OR ABOVE" | table21 == "18 AND ABOV"

*** Renaming variables to facilitate re-shaping 
foreach var in B C D E F G H I J K L M N O P Q R S T U V W X Y Z AA AB  {
	local y = `y' + 1
	rename `var' X`y'
}

*** Reshaping 
reshape long X, i(table)
drop if missing(X)
bysort table (_j) : gen j = _n
drop _j
reshape wide X, i(table) j(j)

*** Renaming per excel sheet
rename X1 all_total_population
rename X2 all_cni
rename X3 all_nocni
rename X4 male_total_population
rename X5 male_cni
rename X6 male_nocni
rename X7 female_total_population
rename X8 female_cni
rename X9 female_nocni
rename X10 trans_total_population
rename X11 trans_cni
rename X12 trans_nocni

*** Final check 
*fix column width issue so that it's easy to eyeball the data
drop table21
order table 
browse


************************* Question 4 ***************************************


use"/Users/devakid/Library/CloudStorage/Box-Box/Econ490_Fall2022/Week4/04_assignment/data/grant_prop_review_2022.dta", clear
/* Standardise variable names. I did this because it made running the reshape 
commands easier. If there's another way to get around this, I'd be happy to use 
that approach*/ 
rename Rewiewer1 Reviewer1
rename Review1Score Reviewer_Score1
rename Reviewer2Score Reviewer_Score2
rename Reviewer3Score Reviewer_Score3
reshape long Reviewer Reviewer_Score, i(proposal_id) j(reviewer_number) // converting the data to long format makes it possible to get all the reviewer names and scores in a single column and side by side. 
bysort Reviewer: egen stand_score_r = std(Reviewer_Score) 				// generating the z-score for each reviewer 
reshape wide Reviewer stand_score_r Reviewer_Score, i(proposal_id) j(reviewer_number) // converting the data back to wide format to calculate the average standardised score 
gen average_stand_score = (stand_score_r1 + stand_score_r2 + stand_score_r3) / 3 // calculating the average standardised score
gsort -average_stand_score 												// Order the standardised scores in descending order 
gen rank=_n 															// Ranking the scores where the highest score is rank and the lowest is rank 128
list proposal_id in 1/50 												// seeing the top 50 ranks 
