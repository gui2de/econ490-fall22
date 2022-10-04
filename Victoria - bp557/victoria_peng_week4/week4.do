*Q1
**a)
clear all
use "village_pixel.dta"
tab pixel payout // We can find that the payout variable is consistent within a pixel
gen pixel_consistent = 0
save "village_pixel_1a).dta", replace
**)b
encode pixel, gen (pixel1) // transfer string to numeric
collapse (count) pixel_number=pixel1, by(village) // count pixel numbers for each village
keep if pixel_number == 1 
list village, nolab // identify those villages within single pixels
use "village_pixel_1a).dta", clear
gen pixel_village = 1 // construct dummy
replace pixel_village = 0 if village==10|village==14|village==17|village==31|village== 33|village== 49|village== 58|village== 61|village== 68|village== 127|village== 130|village== 203|village== 226|village== 238|village== 292|village== 298|village== 316|village== 355|village== 360
save "village_pixel_1b).dta", replace
**)c
collapse (mean) payout_mean=payout, by(village) // calculate payout means for each village
drop if payout_mean == 0 | payout_mean == 1
list village, nolab // identify those villages with inconsistent payouts
use "village_pixel_1b).dta", clear
gen village_payout = 1 // construct dummy
replace village_payout = 0 if village==22|village==25|village==35|village==101|village== 112|village== 123|village== 128|village== 147|village== 192|village== 193|village== 253|village== 274|village== 277|village== 286|village== 317|village== 330|village== 334|village== 339
gen village_pixel_payout = 3 // generate the required dummy
replace village_pixel_payout = 2 if pixel_village == 1 & village_payout == 1
replace village_pixel_payout = 1 if pixel_village == 0
save "village_pixel_1c).dta", replace

*Q2 // it is also okay to not use loop here and directly reshape the dataset
clear all
use "psle_student_raw.dta"

tempfile table2 // create an empty file
save "table2.dta", replace emptyok


gen code = substr(schoolcode, -7, 3)
encode code, gen (code1) 
save "psle_1.dta", replace

forvalues i=1/138 {
	use "psle_1.dta", clear
	keep if code1 == `i'
	split s, parse(">SUBJECTS") // split s based on ">SUBJECTS"
split s2, parse("</TD></TR>") gen(var) // split s2 based on "</TD></TR>" and create new variables
gen serial = _n
reshape long var, i(serial) j(j) // change the "wide" dataset into the "long" dataset
append using "table2.dta" //adding the rows to the tempfile
	save "table2.dta", replace 
	} // loop for each data source
	
use "table2.dta", clear	
	
split var, parse("</FONT></TD>")
keep schoolcode var1 var2 var3 var4 var5 // keep only the relevant variables
drop if var2=="" & var3=="" // dropping first and last rows as they are empty
gen cand_id = substr(var1,-14,.) // candidate ID variable
gen gender = substr(var3,-1,.) // gender
gen prem_number =  substr(var2,strpos(var2, "CENTER") +8, .) // prem number
gen name =  substr(var4,strpos(var4, "<P>") +3 , .) // name
replace var5 = substr(var5,ustrpos(var5, "LEFT") +6 , .) // grades
replace var5 = substr(var5,1 , strlen(var5) - 7)
*all the subject info is in one columns, create separate columns
split var5, parse(,) //use "comma" as the parser.
rename var51 kiswahili // rename variables
rename var52 english
rename var53 maarifa
rename var54 hisabati
rename var55 science
rename var56 uraia
rename var57 average
drop var1 var2 var3 var4 var5 // drop columns that are no longer needed
*extract just the grade
local varlist "kiswahili english maarifa hisabati science uraia average"
foreach v in `varlist'{
	replace `v' = usubstr(`v',-1,1)
}
replace schoolcode = usubstr(schoolcode, 5, 9) // reconstruct schoolcode
replace schoolcode=upper(schoolcode)
save "psle_clean1.dta", replace

*Q3
global excel_t21 "Pakistan_district_table21.xlsx" // update the global
clear
tempfile table21 // create an empty tempfile
save "table21.dta", replace emptyok

*Run a loop through all the excel sheets (135) 
forvalues i=1/135 {
	import excel "$excel_t21", sheet("Table `i'") firstrow clear allstring //import
	display as error `i' //display the loop number

	keep if regex(TABLE21PAKISTANICITIZEN1, "18 AND" )==1 //keep only those rows that have "18 AND"
	
	*keep if TABLE21PAKISTANICITIZEN1== "18 AND" 
	keep in 1 //the first one is the one wanted
	rename TABLE21PAKISTANICITIZEN1 table21

	gen table=`i' //to keep track of the sheet we imported the data from
	append using "table21.dta" //adding the rows to the tempfile
	save "table21.dta", replace //saving the tempfile 
}
use "table21.dta", clear // load the tempfile
format %40s table21 B C D E F G H I J K L M N O P Q R S T U V W X Y  Z AA AB AC // fix column width
replace table21 = "18 AND ABOVE" if table21 != "18 AND ABOVE" // make the first column consistent
rename B v_1 // rename variables
rename C v_2
rename D v_3
rename E v_4
rename F v_5
rename G v_6
rename H v_7
rename I v_8
rename J v_9
rename K v_10
rename L v_11
rename M v_12
rename N v_13
rename O v_14
rename P v_15
rename Q v_16
rename R v_17
rename S v_18
rename T v_19
rename U v_20
rename V v_21
rename W v_22
rename X v_23
rename Y v_24
rename Z v_25
rename AA v_26
rename AB v_27
rename AC v_28
// deal with those weird values
local varlist "v_28 v_27 v_26 v_25 v_24 v_23 v_22 v_21 v_20 v_19 v_18 v_17 v_16 v_15 v_14 v_13 v_12 v_11 v_10 v_9 v_8 v_7 v_6 v_5 v_4 v_3 v_2 v_1"
foreach v in `varlist' {
	replace `v' = "" if `v' == "-                            -                            -" | `v' =="-" | `v' =="1                                     -" | `v' == "-                                 -                                 -" | `v' == "-                              -                                      -" | `v' == "-                     -                       -"
}

// Below are the codes in which I try to create a loop to align the columns. However, when I ran the loop, all values were gone. There may be some other ways to make the alignment automatic.
// try to create a loop to automatically align columns
forvalues i=1/27 {
replace v_`i+1'=v_`i' if v_`i+1'==""
replace v_`i'="" if v_`i'==v_`i+1'
}

// Then I have tried to work on the columns one by one. But it turns out that the coding patterns are not the same between any two columns and the thing becomes complicated as the alignment moves on and goes "deep"
use "table21.dta", clear // load the tempfile
format %40s table21 B C D E F G H I J K L M N O P Q R S T U V W X Y  Z AA AB AC // fix column width
replace table21 = "18 AND ABOVE" if table21 != "18 AND ABOVE" // make the first column consistent
local varlist "B C D E F G H I J K L M N O P Q R S T U V W X Y Z AA AB AC"
foreach v in `varlist' {
	replace `v' = "" if `v' == "-                            -                            -" | `v' =="-" | `v' =="1                                     -" | `v' == "-                                 -                                 -" | `v' == "-                              -                                      -" | `v' == "-                     -                       -"
} // deal with weird values
replace AA=AB if AA=="" // start to align backward and work on the columns one by one

replace Z=AA if Z=="" 
replace AA="" if Z==AA

replace Y=Z if Y=="" // move on 
replace Z="" if Z==Y
replace Z=AA if Z==""

*Q4
clear all
use "grant_prop_review_2022.dta"
egen min_score1=min(Review1Score) // normalize each reviewer's score for each proposal
egen max_score1=max(Review1Score)
gen stand_r1_score = (Review1Score - min_score1) / (max_score1 - min_score1) 
egen min_score2=min(Reviewer2Score)
egen max_score2=max(Reviewer2Score)
gen stand_r2_score = (Reviewer2Score - min_score2) / (max_score2 - min_score2)
egen min_score3=min(Reviewer3Score)
egen max_score3=max(Reviewer3Score)
gen stand_r3_score = (Reviewer3Score - min_score3) / (max_score3 - min_score3)
gen average_stand_score = (stand_r1_score + stand_r2_score +stand_r3_score)/3
drop min_score1 max_score1 min_score2 max_score2 min_score3 max_score3 // select needed variables
gsort -average_stand_score // list the obs in the ascending order of average standardrized scores
gen rank = _n // create rank
sort proposal_id // change the order back
save "grant_prop_review_2022_stand.dta", replace
