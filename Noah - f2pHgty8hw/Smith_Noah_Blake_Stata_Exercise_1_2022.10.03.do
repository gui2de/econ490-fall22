//////////////////////////////
///*** STATA EXERCISE 1 ***///
//////////////////////////////

*Name: Noah Blake Smith

*Date: October 3, 2022

clear

cd "/Users/nbs/Documents/Georgetown/Semester 5/1 Courses/ECON 490/Assignments/Stata Exercise 1/Data" /*User should change current directory to the location of the data files on his/her machine.*/

///////////////////////////
///*** QUESTION 1(a) ***///
///////////////////////////

use "village_pixel.dta", clear

tab pixel payout, m /*Each pixel has only payout of 1 or of 0.*/

gen pixel_consistent = 0 /*Each pixel is consistent, so we can just set the variable to 0.*/

la var pixel_consistent "=0 if payout variable is consistent within pixel"

///////////////////////////
///*** QUESTION 1(b) ***///
///////////////////////////

egen tag = tag(pixel village) /*Tag just one observation in each distinct group defined by pixel and village.*/
la var tag "=1 for first unique pixel value in village"

egen tagtot = sum(tag), by(village) /*Sum tags for each village.*/
la var tagtot "Number of unique pixel value(s) in village"

gen pixel_village = .
replace pixel_village = 0 if tagtot==1 /*Note: tagtot==1 means village households are in exactly one particular pixel.*/
replace pixel_village = 1 if tagtot!=1 /*Note: tagtot!=1 means village households are in more than one particular pixel.*/
la var pixel_village "=0 if village households in exactly one pixel"

tab tagtot pixel_village /*Check for errors. None found.*/

drop tag tagtot /*Temporary variables no longer needed.*/

///////////////////////////
///*** QUESTION 1(c) ***///
///////////////////////////

/*I generate a variable that categorizes villages by payout consistency. As shown in 1(a), payout is either 0 or 1. Accordingly, a village has payout inconsistency iff the maximum and minimum values for payout are not equal within that village.*/

egen payout_max = max(payout), by(village) /*Find maximum payout in each village.*/
egen payout_min = min(payout), by(village) /*Find minimum payout in each village.*/

gen payout_village = .
replace payout_village = 0 if payout_min==payout_max /*The variable is 0 when the minimum payout equals the maximum payout.*/
replace payout_village = 1 if payout_min!=payout_max /*The variable is 1 otherwise.*/
la var payout_village "=0 if payout is consistent across households in village"

drop payout_max payout_min /*Temporary variables no longer needed.*/

gen village_category = . /*This variable categorizes villages by pixel and payout consistency.*/
replace village_category = 1 if pixel_village==0
replace village_category = 2 if pixel_village==1 & payout_village==0
replace village_category = 3 if pixel_village==1 & payout_village==1

la def vcat 1 "One pixel" 2 "Multiple pixels but same payout" 3 "Multiple pixels and payouts" /*Define label for pixel_village variable.*/
la val village_category "vcat"

list hhid if village_category==2 /*List of all hhids in villages with different pixels but same payouts.*/

tab village_category, m /*Check for errors. None found.*/
count if missing(village_category) /*Check for errors. None found.*/

////////////////////////
///*** QUESTION 2 ***///
////////////////////////

use "psle_student_raw.dta", clear

split s, parse(">SUBJECTS") /*Characters before this point not relevant.*/

split s2, parse("</TD></TR>") gen(var) /*Split where line break occurs.*/

gen serial = _n /*Generate a variable for unique identification.*/

reshape long var, i(serial) j(j) /*Reshape data from wide to long format.*/

split var, parse("</FONT></TD>") /*Create new variables by partitioning var at at specified locations.*/ 

keep schoolcode var1 var2 var3 var4 var5 /*Keep only relevant variables.*/

drop if var2=="" & var3=="" /*Drop observations when both var2 and var3 are empty.*/

/*Extract candidate ID variable.*/
gen cand_id = substr(var1,-14,.) /*Relevant characters 14 from end.*/

/*Extract gender variable.*/
gen gender = substr(var3,-1,.) /*Relevant characters 1 from end.*/

/*Extract premium number variable.*/
gen prem_number =  substr(var2,strpos(var2,"CENTER")+8,.)

/*Extract name variable.*/
gen name =  substr(var4,strpos(var4,"<P>")+3,.)

/*Extract grade information.*/
replace var5 = substr(var5,ustrpos(var5,"LEFT")+6,.)
replace var5 = substr(var5,1,strlen(var5)-7)

split var5, parse(,) /*Separate grades from subjects such that each subject has its own grade column.*/

rename var51 kiswahili
rename var52 english
rename var53 maarifa
rename var54 hisabati
rename var55 science
rename var56 uraia
rename var57 average

drop var1 var2 var3 var4 var5 /*No longer needed.*/

/*Extract letter grade for each subject's grade variable.*/
local varlist "kiswahili english maarifa hisabati science uraia average"
foreach subject in `varlist'{
	replace `subject' = usubstr(`subject',-1,1)
}

compress /*Compress to save space.*/

save "plse_student_data_cleaned.dta", replace

////////////////////////
///*** QUESTION 3 ***///
////////////////////////

global excel_t21 "Pakistan_district_table21.xlsx"

clear

tempfile table21 /*Set up empty tempfile.*/

save `table21', replace emptyok

/*Run loop through all 135 sheets of Excel Workbook. This may take a few minutes.*/

forvalues i = 1/135 {
	
	import excel "$excel_t21", sheet("Table `i'") firstrow clear allstring /*Import sheet from Excel Workbook.*/
	
	display as error `i' /*Display loop number in red for ease of reading.*/

	keep if regex(TABLE21PAKISTANICITIZEN1,"18 AND")==1 /*Clean using regex and keep only relevant rows.*/
	
	keep in 1 /*Keep only the first row. Note there are three.*/
	
	/*Drop if variables that are blank in desired row.*/
	foreach j of varlist * {
		if missing(`j'[1]) drop `j'
	}
	
	rename TABLE21PAKISTANICITIZEN1 table21 /*Rename variable for clarity and consistency.*/
	
	/*This loop creates consistent variable names that count up: var1, var2, var3, etc.*/
	local a = -1
	foreach j of varlist * {
		local `++a'
		ren `j' var`a'
	}

	gen table = `i' /*Generate variable to track the sheet from which row was imported.*/
	
	append using `table21' /*Add rows to the tempfile.*/
	
	save `table21', replace /*Save the tempfile to prevent data loss.*/
}

use `table21', clear /*Load tempfile.*/

order table * /*Arrange variables with table on the far left followed by remaining variables in alphabetical order.*/
sort table /*Sort rows by smallest to largest value of table.*/

/*Convert all variables from string to numeric. Label each variable according to its column number in the original Excel Workbook.*/
forval i = 1/12 {
	local j = `i' + 1
	destring var`i', replace force
	la var var`i' "Column `j'"
}

drop var0 /*No longer needed.*/

/*Test that total population equals the sum of the gender populations.*/

gen gender_pop = var4 + var7 + var10 /*Generate sum of males + females + transgenders.*/
gen test = var1 - gender_pop /*Subtract gender population sum from total population.*/ 
tab test, m /*Results show gender population equals total population, save for a few rows with missing variables.*/
drop gender_pop test /*Drop temporary variables.*/

compress /*Compress to save space.*/

save "Pakistan_District_Table21.dta", replace

////////////////////////
///*** QUESTION 4 ***///
////////////////////////

use "grant_prop_review_2022.dta", clear

drop PIName Department AverageScore StandardDeviation /*Drop irrelevant variables.*/

ren proposal_id id /*Rename variable for brevity.*/
la var id "Proposal ID"

ren Rewiewer1 Reviewer1 /*Fix typo in original variable name.*/
ren Review1Score Reviewer1Score /*Fix typo in original variable name.*/


/*Generate a reviewer-score variable for each reviewer of each id.*/
forval i = 1/3 {
	egen rs`i' = concat(Reviewer`i' Reviewer`i'Score), punct("+")
}

drop Reviewer* /*No longer needed.*/

reshape long rs, i(id) j(rev) /*Reshape data from wide to long.*/
drop rev /*No longer needed.*/

split rs, p(+) /*Split the reviewer-score variable into separate reviewer and score variables.*/
drop rs /*No longer needed.*/

ren rs1 r /*Rename reviewer variable for clarity.*/
la var r "Reviewer"

ren rs2 rs /*Rename score variable for clarity.*/
la var rs "Raw score"
destring rs, replace /*Convert from string to numeric.*/

egen mrs = mean(rs), by(r) /*Find the mean raw score for each reviewer.*/
la var mrs "Reviewer's mean raw score"

egen sdrs = sd(rs), by(r) /*Find the standard deviation of the distribution of each reviewer's raw scores.*/
la var sdrs "SD of reviewer's raw scores"

gen ns = (rs - mrs) / sdrs /*Find the normalized score.*/
la var ns "Normalized score"

drop mrs sdrs /*No longer needed.*/

egen mns = mean(ns), by(id) /*Find mean normalized score for each id.*/
la var mns "Proposal's mean normalized score"

/*Generate blank variables for each reviewer, his/her raw score, and his/her normalized score.*/
forval i = 1/3 {
	gen r`i' = ""
	gen r`i'rs = .
	gen r`i'ns = .
}

gen revn = . /*Generate reviewer-number variable.*/
bysort id (r): replace revn = _n /*For each id, define reviewer 1, reviewer 2, and reviewer3.*/
la var revn "Reviewer no"

/*Fill in the reviewer name, raw score, and normalized score by reviewer number and id.*/
forval i = 1/3 {
	replace r`i' = r if revn==`i'
	replace r`i'rs = rs if revn==`i'
	replace r`i'ns = ns if revn==`i'
}

/*Collapse data such that each id has exactly one row.*/
collapse (firstnm) r1* r2* r3* (mean) mns, by(id)

gsort -mns /*Sort ids from highest to lowest mean normalized score.*/
gen rank = _n /*Rank ids by mean normalized score.*/

/*Reapply variable labels, which were lost during the collapse.*/
forval i = 1/3 {
	la var r`i' "Reviewer `i'"
	la var r`i'rs "Reviewer `i''s raw score"
	la var r`i'ns "Reviewer `i''s normalized score"
}
la var mns "Proposal ID's normalized score"
la var rank "Proposal ID's rank"

order id rank mns * /*Rearrange variables in logical order.*/

compress /*Compress to save space.*/

save "grant_prop_review_2022_cleaned.dta", replace
