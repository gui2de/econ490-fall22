//////////////////////////////
///*** STATA EXERCISE 1 ***///
//////////////////////////////

*Name: Noah Blake Smith

*Date: October 3, 2022

cd "/Users/nbs/Documents/Georgetown/Semester 5/1 Courses/ECON 490/Assignments/Stata Exercise 1/Data"

///////////////////////////
///*** QUESTION 1(a) ***///
///////////////////////////

use "/Users/nbs/Documents/Georgetown/Semester 5/1 Courses/ECON 490/Assignments/Stata Exercise 1/Data/village_pixel.dta", clear

ssc install recol
recol *

tab pixel payout, m /*Each pixel has only payout of 1 or of 0.*/

gen pixel_consistent = 0 /*Each pixel is consistent, so we can just set the variable to 0.*/

la var pixel_consistent "=0 if payout variable is consistent within pixel"

///////////////////////////
///*** QUESTION 1(b) ***///
///////////////////////////

egen tag = tag(pixel village)
la var tag "=1 for first unique pixel value in village"

egen tagtot = sum(tag), by(village)
la var tagtot "Number of unique pixel value(s) in village"

gen pixel_village = .
replace pixel_village = 0 if tagtot==1
replace pixel_village = 1 if tagtot!=1
la var pixel_village "=0 if village households in exactly one pixel"

tab tagtot pixel_village /*Check for errors. None found.*/

drop tag tagtot

///////////////////////////
///*** QUESTION 1(c) ***///
///////////////////////////

gen village_category = .
replace village_category = 1 if pixel_village==0
replace village_category = 2 if pixel_village==1 & pixel_consistent==0
replace village_category = 3 if pixel_village==1 & pixel_consistent==1

la def vcat 1 "One pixel" 2 "Multiple pixels but same payout" 3 "Multiple pixels and payouts"
la val village_category "vcat"

tab village_category, m
count if missing(village_category) /*Check for errors. None found.*/

////////////////////////
///*** QUESTION 2 ***///
////////////////////////

use "/Users/nbs/Documents/Georgetown/Semester 5/1 Courses/ECON 490/Assignments/Stata Exercise 1/Data/psle_student_raw.dta", clear

split s, parse(">SUBJECTS") /*Characters before this point not relevant.*/

split s2, parse("</TD></TR>") gen(var) /*Split where line break occurs.*/

gen serial = _n

reshape long var, i(serial) j(j)

split var, parse("</FONT></TD>")

keep schoolcode var1 var2 var3 var4 var5 /*Keep only relevant variables.*/

drop if var2=="" & var3==""

*Candidate ID
gen cand_id = substr(var1,-14,.) /*Relevant characters 14 from end.*/

*Gender
gen gender = substr(var3,-1,.) /*Relevant characters 1 from end.*/

*Prem umber
gen prem_number =  substr(var2,strpos(var2,"CENTER")+8,.)

*Name
gen name =  substr(var4,strpos(var4,"<P>")+3,.)

*Grades
replace var5 = substr(var5,ustrpos(var5,"LEFT")+6,.)
replace var5 = substr(var5,1,strlen(var5)-7)

split var5, parse(,)

rename var51 kiswahili
rename var52 english
rename var53 maarifa
rename var54 hisabati
rename var55 science
rename var56 uraia
rename var57 average

drop var1 var2 var3 var4 var5 

*Extract grade
local varlist "kiswahili english maarifa hisabati science uraia average"

foreach subject in `varlist'{
	replace `subject' = usubstr(`subject',-1,1)
}

compress

save "plse_student_data_cleaned.dta", replace

////////////////////////
///*** QUESTION 3 ***///
////////////////////////

global excel_t21 "/Users/nbs/Documents/Georgetown/Semester 5/1 Courses/ECON 490/Assignments/Stata Exercise 1/Data/Pakistan_district_table21.xlsx"

clear

tempfile table21

save `table21', replace emptyok

forvalues i = 1/135 {
	
	import excel "$excel_t21", sheet("Table `i'") firstrow clear allstring
	
	display as error `i'

	keep if regex(TABLE21PAKISTANICITIZEN1,"18 AND")==1
	
	keep in 1
	
	foreach j of varlist * {
		if missing(`j'[1]) drop `j'
	}
	
	rename TABLE21PAKISTANICITIZEN1 table21
	
	local a = -1
	foreach j of varlist * {
		local `++a'
		ren `j' var`a'
	}

	gen table = `i'
	
	append using `table21'
	
	save `table21', replace
}

use `table21', clear

order table *
sort table

forval i = 1/12 {
	local j = `i' + 1
	*destring var`i', replace force
	la var var`i' "Column `j'"
}

drop var0

ssc install recol
recol *

compress

save "/Users/nbs/Documents/Georgetown/Semester 5/1 Courses/ECON 490/Assignments/Stata Exercise 1/Data/Pakistan_District_Table21.dta", replace

////////////////////////
///*** QUESTION 4 ***///
////////////////////////

use "/Users/nbs/Documents/Georgetown/Semester 5/1 Courses/ECON 490/Assignments/Stata Exercise 1/Data/grant_prop_review_2022.dta", clear

drop PIName Department AverageScore StandardDeviation

ren proposal_id id
la var id "Proposal ID"

ren Rewiewer1 Reviewer1
ren Review1Score Reviewer1Score

forval i = 1/3 {
	egen rs`i' = concat(Reviewer`i' Reviewer`i'Score), punct("+")
}

drop Reviewer*

reshape long rs, i(id) j(rev)
drop rev

split rs, p(+)
drop rs

ren rs1 r
la var r "Reviewer"

ren rs2 rs
la var rs "Raw score"
destring rs, replace

egen mrs = mean(rs), by(r)
la var mrs "Reviewer's mean raw score"

egen sdrs = sd(rs), by(r)
la var sdrs "SD of reviewer's raw scores"

gen ns = (rs - mrs) / sdrs
la var ns "Normalized score"

drop mrs sdrs

egen mns = mean(ns), by(id)
la var mns "Proposal's mean normalized score"

forval i = 1/3 {
	gen r`i' = ""
	gen r`i'rs = .
	gen r`i'ns = .
}

gen revn = .
bysort id (r): replace revn = _n
la var revn "Reviewer no"

forval i = 1/3 {
	replace r`i' = r if revn==`i'
	replace r`i'rs = rs if revn==`i'
	replace r`i'ns = ns if revn==`i'
}

collapse (firstnm) r1* r2* r3* (mean) mns, by(id)

gsort -mns
gen rank = _n

forval i = 1/3 {
	la var r`i' "Reviewer `i'"
	la var r`i'rs "Reviewer `i''s raw score"
	la var r`i'ns "Reviewer `i''s normalized score"
}
la var mns "Proposal ID's normalized score"
la var rank "Proposal ID's rank"

order id rank mns *

compress

save "grant_prop_review_2022_cleaned.dta", replace
