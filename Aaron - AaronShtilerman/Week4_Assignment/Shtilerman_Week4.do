*Aaron Shtilerman Week 4 Assignment


////PLEASE READ////
global username "C:\Users\15162" // REVIEWER: Change "15162"to your username, then the rest of the code should run. Q2 will take a LONG time to run because of the reshape command. For Q2, my work mainly mirrors the hint file, with a couple display commands of the variables to see what's going on with the scraping. Comments in parentheses are my comments to Q2.






*Q1: You are working on a crop insurance project in Kenya. For each household, we have the following information: village name, pixel and payout status.

cd "$username\Box\Econ490_Fall2022\Week4\04_assignment\data\"

use village_pixel.dta, clear
br
sort pixel
codebook payout
*a
egen pixel_mean_payout=mean(payout), by(pixel) //Finds average payout for each pixel (We expect to be either 0 or 1 if the pixel is consistent) 
gen pixel_consistent=1
replace pixel_consistent=0 if pixel_mean_payout==1 | pixel_mean_payout ==0 //The pixel is consistent if the mean payout is 1 or 0 for the pixel
label define consistency 1 "Not Consistent" 0 "Consistent" 
label values pixel_consistent "consistency"
codebook pixel_consistent
drop pixel_mean_payout

*b
sort village
egen tag = tag(pixel village) // Finds one obs for each group made by each pixel/village intersection
egen distinct = total(tag), by(village)
gen pixel_village=0
replace pixel_village=1 if distinct > 1 //If there is more than 1 pixel/village intersection for a village, the village is in multiple pixels
label define pixel_v 1 "Village in multiple pixels" 0 "Village in one pixel" 
label values pixel_village "pixel_v"
drop tag
drop distinct

*c
gen village_group=2
replace village_group=1 if pixel_village==0
egen tag = tag(payout village) // Finds one obs for each group made by each payout/village intersection
egen distinct = total(tag), by(village)
replace village_group=3 if distinct > 1 // Villages with internal different payouts
label define vgrp 1 "One pixel" 2 "Different pixels, same payout" 3 "Different pixels, different payout"
label values village_group "vgrp"
drop tag
drop distinct

list hhid if village_group==2 //Displays all farmer ids with villages containing different pixels but the same payouts



*Q2: This task involves string cleaning and data wrangling. We downloaded the PSLE information of students of 138 schools in Arusha District in Tanzania (psle_student_raw.dta). Unfortunately the format of the data is a mess. Your task is to create a student level dataset (see string cleaning example) with the following variables: schoolcode, cand_id, gender, prem_number, name, grade variables for: kiswahili english maarifa hisabati science uraia average.
use psle_student_raw.dta, clear
br
display s
split s, parse(">SUBJECTS") //we need to get rid of part before "Subject"
*Identify any pattern => new line
*eyeball the data/website. There's a new line after subject grades. 
display s2
*Fairly certain "</TD></TR>" is where a new line starts.
split s2, parse("</TD></TR>") gen(var)

gen serial = _n
reshape long var, i(serial) j(j)

split var, parse("</FONT></TD>")
*keep only the relevant variables
keep var1 var2 var3 var4 var5

*dropping first and last rows as they are empty
drop if var2=="" & var3==""


*candidate ID variable
di var1 //(relevant info 14 from back, consistent)
gen cand_id = substr(var1,-14,.)

*gender
di var3 //(relevant info 1 from back)
gen gender = substr(var3,-1,.)


*Prem Number
di var2
gen len=strlen(var2)
codebook len
gen prem_number =  substr(var2,-11, .) 
drop len

*Name
di var4 //(names will have different lengths)
gen name =  substr(var4,strpos(var4, "<P>") +3 , .)

*grades
di var5
replace var5 = substr(var5,ustrpos(var5, "LEFT") +6 , .)
di var5
replace var5 = substr(var5,1 , strlen(var5) - 7)
di var5 //(cuts the scraping remnant)

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
br
*drop columns that are no longer needed.
drop var1 var2 var3 var4 var5 

*extract just the grade
local varlist "kiswahili english maarifa hisabati science uraia average"
foreach subject in `varlist'{
	replace `subject' = usubstr(`subject',-1,1)	
}



*Q3: We have the information of adults that have computerized national ID card in the following pdf: Pakistan_district_table21.pdf. This pdf has 135 tables (one for each district.) We extracted data through an OCR software but unfortunately it wasn't very accurate. We need to extract column 2-13 from the first row ("18 and above") from each table. Create a dataset where each row contains information for a particular district

global excel_t21 "$username\Box\Econ490_Fall2022\Week4\04_assignment\data\Pakistan_district_table21.xlsx"
*update the global

clear
*setting up an empty tempfile
tempfile table21
save `table21', replace emptyok

*Run a loop through all the excel sheets (135) this will take 2-10 mins because it has to import all 135 sheets, one by one
forvalues i=1/135 {
	import excel "$excel_t21", sheet("Table `i'") clear allstring //import
	display as error `i' //display the loop number

	keep if regex(A, "18 AND" )==1 //keep only those rows that have "18 AND"
	*I'm using regex because the following code won't work if there are any trailing/leading blanks
	*keep if TABLE21PAKISTANICITIZEN1== "18 AND" 
	keep in 1 //there are 3 of them, but we want the first one
	foreach var of varlist _all{
		if missing(`var'[1]) drop `var' //drops missing variable entries
	}
	drop A
	local index=0
	foreach var of varlist _all{
		local `index++'
		rename `var' v`index' // renames variable entries to be consistent with each other
	}
	gen table=`i' //to keep track of the sheet we imported the data from
	tostring(table), replace
	format %8s _all
	append using `table21' //adding the rows to the tempfile
	save `table21', replace //saving the tempfile so that we don't lose any data
	use `table21',replace
	br
}
*load the tempfile
use `table21', clear
*fix column width issue so that it's easy to eyeball the data
format _all %8s
destring(table), replace
sort table
order table
br



*Q4: Faculty members submitted 128 proposals for funding opportunities. Unfortunately, we only have enough funds for 50 grants. Each proposal was assigned to thee randomly selected students in Econ 490 where they gave a score between 1 (lowest) and 5 (highest). Each student reviewed 24 proposals and assigned a score. We think it will be better if we normalize the score wrt each reviewer before calculating the average score. Add the following columns 1) stand_r1_score 2) stand_r2_score 3) stand_r3_score 4) average_stand_score 5) rank (highest score =>1, lowest => 128)

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



//preserve
//reshape wide RS stand_r_score, i(proposal_id) j(R) string
//restore
//If you want to convert the data back dependent on proposal id, use the above code^