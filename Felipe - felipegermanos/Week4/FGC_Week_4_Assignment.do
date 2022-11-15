********************************************************************************
* Econ 490: Week 4
* Assignment - Data Cleaning in Stata
* Felipe Germanos de Castro
* Sep 30, 2022
********************************************************************************

/* I relied on Aaron's code for questions 2-4, as I struggled to get anything done by myself.
This was increased by Brazil's election this weekend. I did go through all of it and made sure
I always understood what was going on.*/

/*******************************************************************************
0. Setting up Directory and Paths
*******************************************************************************/



cd "/Users/felipe.germanos/Library/CloudStorage/Box-Box/Econ490_Fall2022/Week4/04_assignment"


global wd "/Users/felipe.germanos/Library/CloudStorage/Box-Box/Econ490_Fall2022/Week4/04_assignment"


	clear
	global pixel   "$wd/data/village_pixel"
	global student "$wd/data/psle_student_raw"
	global excel   "$$wd/data/Pakistan_district_table21.xlsx"

	


/*******************************************************************************
1. Q1 - Uploading Data
*******************************************************************************/


*load insurance data
	use "$pixel", clear

codebook


/*******************************************************************************
2. Q1 - A
*******************************************************************************/

/* We can use an average measure to see if a pixel is consistent.
For rows that have an average different than 0 or 1, we find an inconsistent result*/

sort pixel

egen pixel_mean_payout=mean(payout), by(pixel)

/* Now, we can further use this measure to define a dummy variable for consistence*/

gen pixel_consistent=.
replace pixel_consistent = 0
replace pixel_consistent=1 if pixel_mean_payout == 0 | pixel_mean_payout ==1
codebook pixel_consistent
drop pixel_mean_payout


/*******************************************************************************
3. Q1 - B
*******************************************************************************/


/* Since variables are at the village level, we can use the tag function to find all
distinct combinations of village and pixel and see how many pixels are there per village.

The, we recode the variable to */

sort village

egen key_pixel_village = tag(pixel village)

egen pixel_village = total(key_pixel_village), by(village)
recode pixel_village (1=0)
replace pixel_village=1 if .> pixel_village & pixel_village > 1
drop key_pixel_village


/*******************************************************************************
4. Q1 - C
*******************************************************************************/

/* Once again we can use the tag function to create specific combinations of
village and group*/


egen key_village_pixel_combo = tag(payout village) 

egen village_pixel_combo = total(key_village_pixel_combo), by(village)
replace village_pixel_combo=3 if village_pixel_combo > 1
recode village_pixel_combo (1 = 2)
recode village_pixel_combo (0 = 1)


drop key_village_pixel_combo


list hhid if village_pixel_combo==2 






/*******************************************************************************
5. Q2
*******************************************************************************/

/*We start by parsing the long strings into smaller chunks, then we separate 
these into new variables, which we clean heavily with "di" and rename them*/


use "$student", clear

split s, parse(">SUBJECTS") 
split s2, parse("</TD></TR>") gen(var)

gen serial = _n
reshape long var, i(serial) j(j)

split var, parse("</FONT></TD>")


*Keeping only the relevant variables
keep var1 var2 var3 var4 var5

*Dropping empty rows

drop if var2=="" & var3==""


*candidate ID variable

di var1
gen cand_id = substr(var1,-14,.)

*gender
di var3 
gen gender = substr(var3,-1,.)


*Prem Number
di var2
gen len=strlen(var2)
codebook len
gen prem_number =  substr(var2,-11, .) //?
drop len


*Name
di var4
gen name =  substr(var4,strpos(var4, "<P>") +3 , .) 

*Grades
di var5
replace var5 = substr(var5,ustrpos(var5, "LEFT") +6 , .)
di var5
replace var5 = substr(var5,1 , strlen(var5) - 7)
di var5

*Further parsing var5:
split var5, parse(,)

*Renaming variables
rename var51 kiswahili
rename var52 english
rename var53 maarifa
rename var54 hisabati
rename var55 science
rename var56 uraia
rename var57 average
br

*Dropping remaining empty rows
drop var1 var2 var3 var4 var5 

*Extracting the grade
local varlist "kiswahili english maarifa hisabati science uraia average"
foreach subject in `varlist'{
	replace `subject' = usubstr(`subject',-1,1)	
}


/*******************************************************************************
6. Q3
*******************************************************************************/

/*Here we start by setting up a temporary file that will store our cleaned data.
The, we run a loop through all Excel tab*/

clear all

tempfile table21
save `table21', replace emptyok


forvalues i=1/135 {
	import excel "$excel", sheet("Table `i'") clear allstring
	display as error `i'

	keep if regex(A, "18 AND" )==1
	keep in 1 
	foreach var of varlist _all{
		if missing(`var'[1]) drop `var'
	}
	drop A
	local index=0
	foreach var of varlist _all{
		local `index++'
		rename `var' v`index' 
	}
	gen table=`i' 
	tostring(table), replace
	format %8s _all
	append using `table21'
	save `table21', replace 
	use `table21',replace
	br
}


use `table21', clear

format _all %8s

destring(table), replace

sort table
order table
br



/*******************************************************************************
7. Q4
*******************************************************************************/


clear
tempfile rev
save `rev', replace emptyok

forval i=1/3{
	use grant_prop_review_2022.dta, clear
	drop PIName Department AverageScore StandardDeviation
	rename Rewiewer1 R1
	rename Reviewer2 R2
	rename Reviewer3 R3
	rename Review1Score R1S
	rename Reviewer2Score R2S
	rename Reviewer3Score R3S
	codebook R1
	keep proposal_id R`i' R`i'S
	rename R`i' R
	rename R`i'S RS
	append using `rev'
	save `rev', replace
}
use `rev', clear
label var R "Reviewer"
label var RS "Reviewer Score"
sort R
egen rmeanscore= mean(RS), by(R)
egen rstdv= sd(RS), by(R)
gen stand_r_score= (RS-rmeanscore)/rstdv
label var stand_r_score "Standardized Reviewer Score"
drop rmeanscore rstdv

sort proposal_id
egen avg_stand_score=mean(stand_r_score), by(proposal_id)
label var avg_stand_score "Average of Standardized Scores"
gsort -avg_stand_score
gen rank=ceil(_n/3)
label var rank "Proposal Rank: Highest Score=1, Lowest Score=128"


























