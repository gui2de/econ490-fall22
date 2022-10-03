********************************************************************************
* Econ 490: Week 4
* Stata Homework Assignment
* Shaily Acharya
* Oct 2, 2022
********************************************************************************

set more off
clear
cd "/Users/shailyacharya/Box/Econ490_Fall2022/Week4/04_assignment/data"


/*******************************************************************************
Q1: KENYA CROP INSURANCE
*******************************************************************************/
use village_pixel.dta, clear

*looking at the data
describe 
codebook 

***PART A***
tab payout pixel
*we confirm that payout is consistent within a pixel, since there is no pixel that has a payout value of both 1 and 0. 
sort pixel payout
gen pixel_consistent = 1
replace pixel_consistent = 0 if pixel[_n]==pixel[_n+1] & payout[_n]==payout[_n+1]
replace pixel_consistent =0 if  pixel[_n]==pixel[_n-1] & payout[_n]==payout[_n-1]
*by using row numbers after sorting the data, we ensure that payouts are consistent within pixels 

***PART B***
sort village pixel
gen pixel_village = 1 
replace pixel_village = 0 if pixel[_n]==pixel[_n+1] & village[_n]==village[_n+1]
replace pixel_village =0 if  pixel[_n]==pixel[_n-1] & village[_n]==village[_n-1]
tab village
label list village
*manually made pixel_village=1 when the sample only has one household from a certain village. there must be a more efficient way...
replace pixel_village = 0 if  village == 10 | village == 14 | village == 17 | village == 31 | village == 33 | village == 49 | village == 58 | village == 61 | village == 68 | village == 127 | village == 130 | village == 203 | village == 226 | village == 238 | village == 292 | village == 298 | village == 316 | village == 355 | village == 360

***PART C***
*make a new variable to see if payouts are consistent within each village
sort village payout 
gen village_consistent = 1 
replace village_consistent = 0 if village[_n]==village[_n+1] & payout[_n]==payout[_n+1]
replace village_consistent =0 if  village[_n]==village[_n-1] & payout[_n]==payout[_n-1]
*now finding which households are in different pixels and have different payout statuses
gen village_pixel_payout = .
replace village_pixel_payout = 1 if pixel_village == 0 
replace village_pixel_payout = 2 if pixel_village == 1 & village_consistent == 0
replace village_pixel_payout = 3 if pixel_village == 1 & village_consistent == 1
count if village_pixel_payout == 2
list hhid if village_pixel_payout == 2
count if village_pixel_payout == 3
list hhid if village_pixel_payout == 3


/*******************************************************************************
Q2: PSLE TANZANIA DATA CLEANING
*******************************************************************************/
use psle_student_raw.dta, clear

split s, parse(">SUBJECTS")
*right now all the data is in the same row, we need to convert so each row is a unique student
split s2, parse("</TD></TR>") gen(var) //

gen serial = _n

save psle_full_edited, replace

*run loop over each row (school)
forvalue i=1/138{
	use psle_full_edited.dta, clear
	keep if serial == `i'
	display as error `i'
	reshape long var, i(serial) j(j)
	split var, parse("</FONT></TD>")
	*keep only the relevant variables
	keep var1 var2 var3 var4 var5
	*dropping first and last rows as they are empty
	drop if var2=="" & var3==""
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
	*School Code
	gen schoolcode = `i'
	
	*all the subject info is in one column, create separate columns
	split var5, parse(,) 
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
	local varlist kiswahili english maarifa hisabati science uraia average
	foreach subject in `varlist'{
		replace `subject' = usubstr(`subject',-1,1)
		}
	
	*unsure about this part
	tempfile school`i'
	save `school`i''
	append using `school`i''
	save psle_final, replace
}

/*******************************************************************************
Q3: PAKISTAN NATIONAL ID
*******************************************************************************/
global excel_t21 "/Users/shailyacharya/Box/Econ490_Fall2022/Week4/04_assignment/data/Pakistan_district_table21.xlsx"
*update the global

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

	gen table=`i' //to keep track of the sheet we imported the data from
	append using `table21' //adding the rows to the tempfile
	save `table21', replace //saving the tempfile so that we don't lose any data
}
*load the tempfile
use `table21', clear
*fix column width issue so that it's easy to eyeball the data
format %40s table21 B C D E F G H I J K L M N O P Q R S T U V W X Y Z AA AB AC

local varlist table21 B C D E F G H I J K L M N O P Q R S T U V W X Y Z AA AB AC

*left-aliging everything 
foreach v of varlist `varlist' {
    
        local f : format `v'
        
        local ff = regexr("`f'", "%~?\-?","")
        
        if regexm("`f'", "%.+s") local cmd cap format %-`ff' `v'
        
        if "`: value label `v''" != "" & "`label'" != "" ///
            local cmd cap format %-`ff' `v'
        
        if "`all'" != "" local cmd cap format %-`ff' `v'
        
        `cmd'
        
        local ff : format `v'
        if "`ff'" != "`f'" local vlist `vlist' `v'

    }
    
    if "`vlist'" != "" des `vlist'
	
sort table 
order table, before(table21)
drop table21 //this column is useless
drop AC //this column has no observations

*now combine columns and rename according to how they appear in PDF
*could I make any of the below into a loop?
gen totalpop = (B + C)
gen cni_obtained = (D+E)
gen no_cni = (F+G)

gen m_totalpop = (H+I)
gen m_cni_obtained = (J+K)
gen m_no_cni = (L+M)

gen f_totalpop = (N+O)
gen f_cni_obtained = (P+Q)
gen f_no_cni = (R+S)

gen t_totalpop = (T+U)
gen t_cni_obtained = (V+W)
gen t_no_cni = (AA+AB+Z+X+Y)

drop B C D E F G H I J K L M N O P Q R S T U V W X Y Z AA AB

destring(totalpop t_totalpop t_no_cni t_cni_obtained no_cni m_totalpop m_no_cni m_cni_obtained f_totalpop f_no_cni f_cni_obtained cni_obtained), replace
encode m_no_cni, gen(m_no_cni1)
encode f_totalpop, gen(f_totalpop1)
encode f_cni_obtained, gen(f_cni_obtained1)
encode t_totalpop, gen(t_totalpop1)
encode t_cni_obtained, gen(t_cni_obtained1)

drop m_no_cni f_totalpop f_cni_obtained t_totalpop t_cni_obtained
 
ren m_no_cni1 m_no_cni
ren f_totalpop1 f_totalpop
ren f_cni_obtained1 f_cni_obtained
ren t_totalpop1 t_totalpop
ren t_cni_obtained1 t_cni_obtained
*now, each row represents a district and contains the 12 variables for national id information
save 18andolder_Pakistan_NID, replace


/*******************************************************************************
Q4: GRANT SCORES
*******************************************************************************/
use grant_prop_review_2022.dta, clear
ren Rewiewer1 Reviewer1
bysort Reviewer1: egen score1_mean_shaily = mean(Review1Score) if Reviewer1 == "sa1600"
bysort Reviewer2: egen score2_mean_shaily = mean(Reviewer2Score) if Reviewer2 == "sa1600"
bysort Reviewer3: egen score3_mean_shaily = mean(Reviewer3Score) if Reviewer3 == "sa1600"

*I spent a lot of time thinking about this problem, and ultimately decided that the best approach would be to see if I could generate the necessary results just based on one reviewer (I chose myselff to be the test case). I was able to generate my own average scores from when I was in the position of all three reviewers, but could not figure out how to average these three scores to generate my actual average score. Once I figure this out, I am hoping to convert this into a loop in order to do the same process to all 16 reviewers, but I also could not figure out how to write this loop since all of the reviewer names are strings and not necessarily in the same order for the 3 reviewer categories. 




