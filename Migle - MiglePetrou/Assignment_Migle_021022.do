*** Setting up globals for wd

global wd "/Users/miglepetrauskaite/Library/CloudStorage/Box-Box/"
	global pixel_data "$wd//Econ490_Fall2022/Week4/04_assignment/data/village_pixel.dta"
	global psle_raw "$wd/Econ490_Fall2022/Week4/04_assignment/data/psle_student_raw.dta"
	global grants "$wd/Econ490_Fall2022/Week4/04_assignment/data/grant_prop_review_2022.dta"
	


************************* Question 1 *******************************

* Load pixel data
	use "$pixel_data", clear

	
* Question 1A

***** Checking payout consistency
describe
tab pixel payout // The pixels are consistent: all villages within a particular pixel either take a payout value of 0 or 1.


***** Creating a dummy
bysort pixel: egen mean_payout = mean(payout) // The idea here is that if we have full consistency, the mean value per each pixel group should be either 1 or 0, as opposed to 0.12, etc.
gen pixel_consistent = 0
replace pixel_consistent = 1 if mean_payout != 0 & mean_payout != 1 // Keeping the value of 0 in case of full consistency, otherwise this new dummy will take the value of 1.
label var pixel_consistent "0=Consistent; 1=Inconsistent payout per pixel"  


* Question 1B

***** Converting pixel to a numerical var
encode pixel, gen(pixel_n) 

tab pixel_n, nol // This shows us which encoded numerical value (1–6) each pixel corresponds to

bysort village: egen mean_pixel = mean(pixel_n) // Generating the mean for the numerical pixel variable at the village level will show us if there are any values like 4.86 or 1.66667, etc., which would in turn mean that some villages are in more than one pixel.

gen pixel_village = 1 // creating the dummy
replace pixel_village = 0 if inlist(mean_pixel, 1,2,3,4,5,6) // Replacing dummy with 0 if the village falls fully within one of the 6 pixels, and with 1 otherwise.

label var pixel_village "0=all village hh in one pixel; 1=hh in a village are in more than one pixel"


* Question 1C
bysort village: egen mean_villpay = mean(payout)
order village payout mean_villpay

* Villages that are in different pixels AND have same payout status
gen hhdiv =2
order hhdiv village payout mean_villpay

* Villages that are entirely in a particular pixel:
forvalues i=1/6 {
	replace hhdiv =1 if mean_pixel==`i'
}

*Villages that are in different pixels AND have different payout status

replace hhdiv =3 if mean_villpay !=1 & mean_villpay !=0
sort mean_villpay
order village hhdiv mean_pixel mean_villpay 

* Listing households
gsort -hhdiv
list hhid in 75/120

tab hhdiv



************************* Question 2 *******************************

* Load PSLE data
	use "$psle_raw", clear

split s, parse(">SUBJECTS") //we need to get rid of part before "Subject", I figured this out by eyeballing the data

*right now all the data is in the same row
*Objective: each row is a unique student

*Identify any pattern => new line
*eyeball the data/website. There's a new line after subject grades. 
*Fairly certain "</TD></TR>" is where a new line starts.
split s2, parse("</TD></TR>") gen(var)

*Still every student info is in the same row,we can get to 1 row = 1 student info by using reshape command
gen serial = _n
reshape long var, i(serial) j(j)

split var, parse("</FONT></TD>")
*keep only the relevant variables
keep var1 var2 var3 var4 var5

*dropping first and last rows as they are empty
drop if var2=="" & var3==""
br

*candidate ID variable
gen cand_id = substr(var1,-14,.)

*gender
gen gender = substr(var3,-1,.)


*Prem Number
gen prem_number =  substr(var2,strpos(var2, "CENTER") +8, .)

*Name
gen name =  substr(var4,strpos(var4, "<P>") +3 , .)

*grades
replace var5 = substr(var5,ustrpos(var5, "LEFT") +6 , .)
replace var5 = substr(var5,1 , strlen(var5) - 7)

*all the subject info is in one columns, create separate columns
split var5, parse(,) //use "comma" as the parser.


*rename variables
rename var51 kiswahili
rename var52 english
rename var53 maarifa
rename var54 hisabati
rename var55 science
rename var56 uraia
rename var57 average

*drop columns that are no longer needed.
drop var1 var2 var3 var4 var5 

*extract just the grade
local varlist "kiswahili english maarifa hisabati science uraia average"
foreach subject in `varlist'{
	replace `subject' = usubstr(`subject',-1,1)
}

sort cand_id

* Generating a school_id variable
gen school_id = cand_id

replace school_id = substr(school_id,1,9)

order school_id cand_id


save "/Users/miglepetrauskaite/Documents/ECON-490/W4_assignment/Q2_final.dta"




************************* Question 3 ***************************************

global excel_t21 "$wd//Econ490_Fall2022/Week4/04_assignment/data/Pakistan_district_table21.xlsx"

* Update the global

clear

* Setting up an empty tempfile
tempfile table21
save `table21', replace emptyok

* Run a loop through all the excel sheets (135) this will take 2-10 mins because it has to import all 135 sheets, one by one
forvalues i=1/135 {
	import excel "$excel_t21", sheet("Table `i'") clear firstrow allstring

	gen district = TABLE21PAKISTANICITIZEN1[4] + B[4] + C[4] + D[4] + E[4] + F[4] +G[4] + H[4] + I[4] + J[4] + K[4] + L[4] 
	
	//import
	display as error `i' //display the loop number

	keep if regex(TABLE21PAKISTANICITIZEN1, "18 AND" )==1 //keep only those rows that have "18 AND"
	*I'm using regex because the following code won't work if there are any trailing/leading blanks
	*keep if TABLE21PAKISTANICITIZEN1== "18 AND" 
	keep in 1 //there are 3 of them, but we want the first one
	rename TABLE21PAKISTANICITIZEN1 table21

	gen table=`i' // To keep track of the sheet we imported the data from
	append using `table21' // Adding the rows to the tempfile
	save `table21', replace // Saving the tempfile so that we don't lose any data
}


* Destringing vars

destring, replace
replace M = "" if M=="-"
replace N = "" if N=="-"
replace O = "" if O=="-"
replace Q = "" if Q=="-"
replace U = "" if strpos(U, "-")
replace W = "" if W== "1                                     -"
destring, replace


preserve 
	keep district table 
	save "/Users/miglepetrauskaite/Documents/ECON-490/W4_assignment/district_mapping.dta", replace 
restore

drop district

* Running a loop to rename all variables to make reshaping easier

vl create letters = (B C D E F G H I J K L M N O P Q R S T U V W X Y Z AA AB AC)
foreach x of varlist $letters {
	local i = `i' + 1
	rename `x' X`i'
}

* Reshape and align data

reshape long X, i(table)
drop if missing(X)
bysort table (_j) : gen j = _n
drop _j
reshape wide X, i(table) j(j)


* Renaming variables again 

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


* Cleaning up

br
replace trans_cni = abs(trans_cni)
drop table21
merge 1:1 table using "/Users/miglepetrauskaite/Documents/ECON-490/W4_assignment/district_mapping.dta"

drop _merge
order table district 



************************* Question 4 *******************************

use "$grants", clear

br

* Renaming vars...
rename Rewiewer1 Reviewer1
rename Review1Score Reviewer_score1
rename Reviewer2Score Reviewer_score2
rename Reviewer3Score Reviewer_score3
drop PIN Depart

* Standardizing
reshape long Reviewer Reviewer_score, i(proposal_id) j(reviewer_no)
bysort Reviewer: egen stand_score_r = std(Reviewer_score)
reshape wide Reviewer stand_score_r Reviewer_score, i(proposal_id) j(reviewer_no)
gen average_stand_score = (stand_score_r1 + stand_score_r2 + stand_score_r3)/3

* Sorting and listing out top 50 highest-scoring proposals
gsort -average_stand_score 
list propo in 1/50
