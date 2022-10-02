********** Question 1
use "/Users/abigailorbe/Library/CloudStorage/Box-Box/Econ490_Fall2022/Week4/04_assignment/data/village_pixel.dta"
	// a
	sort pixel
	bysort pixel: egen minpayout = min(payout)
	bysort pixel: egen maxpayout = max(payout)
	generate pixel_consistent = maxpayout-minpayout
	drop minpayout
	drop maxpayout
	
	//b
	sort village
	bysort village pixel: gen unique = _n==1
	bysort village: egen npixels = sum(unique)
	gen pixel_village = 0 if npixels == 1
	replace pixel_village = 1 if npixels > 1
	drop unique
	drop npixels
	
	//c 
	gen hh_cat = 1 if pixel_village == 0
	replace hh_cat = 2 if pixel_village == 1 & pixel_consistent == 0
	replace hh_cat = 3 if pixel_village == 1 & pixel_consistent == 1

// Save
cd "/Users/abigailorbe/Documents/repos/econ490-fall22/Abigail - abigailorbe/Week 4/2_outputs"
save question1

********* Question 3
// Copied from hint:
global excel_t21 "/Users/abigailorbe/Library/CloudStorage/Box-Box/Econ490_Fall2022/Week4/04_assignment/data/Pakistan_district_table21.xlsx"
clear
tempfile table21
save `table21', replace emptyok
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
use `table21', clear
format %40s table21 B C D E F G H I J K L M N O P Q R S T U V W X Y  Z AA AB AC

// Transforming variables to numeric
destring, replace
replace M = "" if M=="-"
replace N = "" if N=="-"
replace O = "" if O=="-"
replace Q = "" if Q=="-"
replace U = "" if strpos(U, "-")
replace W = "" if W== "1                                     -"
destring, replace

// Creating variable list and looping to rename variables
vl create alpha = (B C D E F G H I J K L M N O P Q R S T U V W X Y Z AA AB AC)
foreach x of varlist $alpha {
	local i = `i' + 1
	rename `x' X`i'
}

// Reshaping data to align columns
reshape long X, i(table)
drop if missing(X)
bysort table (_j) : gen j = _n
drop _j
reshape wide X, i(table) j(j)	

// Renaming columns to reflect original excels
rename X1 all_totalpop
rename X2 all_cni
rename X3 all_nocni
rename X4 male_totalpop
rename X5 male_cni
rename X6 male_nocni
rename X7 female_totalpop
rename X8 female_cni
rename X9 female_nocni
rename X10 trans_totalpop
rename X11 trans_cni
rename X12 trans_nocni

// Fixing negative values
replace trans_cni = abs(trans_cni)

// Dropping table21 variable because it doesn't add any information
drop table21

// Export
cd "/Users/abigailorbe/Documents/repos/econ490-fall22/Abigail - abigailorbe/Week 4/2_outputs"
save question3

********** Question 4
// Set directories and make variable names consistent
cd "/Users/abigailorbe/Library/CloudStorage/Box-Box/Econ490_Fall2022/Week4/04_assignment/data/"
use grant_prop_review_2022.dta, clear
cd "/Users/abigailorbe/Documents/repos/econ490-fall22/Abigail - abigailorbe/Week 4/0_data/intermediary"
rename Rewiewer1 Reviewer1
rename Review1Score Reviewer1Score
save grant_prop_review_2022_fixed

// Create subsets of data for each review 
forval i = 1/3 {
use "/Users/abigailorbe/Documents/repos/econ490-fall22/Abigail - abigailorbe/Week 4/0_data/grant_prop_review_2022.dta", clear
	rename Rewiewer1 Reviewer1
	rename Review1Score Reviewer1Score
	keep Reviewer`i' Reviewer`i'Score proposal_id
	rename Reviewer`i' Reviewer
	rename Reviewer`i'Score Score
	save review`i'data
}

// Append subsets together
use review1data.dta, clear
append using review2data.dta
append using review3data.dta

drop proposal_id

// Create mean and standard deviation by reviewer
sort Reviewer
bysort Reviewer: egen mean = mean(Score)
bysort Reviewer: egen sd = sd(Score)

drop Score

// Drop duplicates
bysort Reviewer: gen unique = _n==1
drop if unique !=1
drop unique

save reviewermeansd

// Rename variables so mean and standard deviation can be merged with master file
use reviewermeansd, clear
rename Reviewer Reviewer3
rename mean mean_rev3
rename sd sd_rev3
save rev3merge

rename Reviewer3 Reviewer2
rename mean_rev3 mean_rev2
rename sd_rev3 sd_rev2
save rev2merge

rename Reviewer2 Reviewer1
rename mean_rev2 mean_rev1
rename sd_rev2 sd_rev1
save rev1merge

// Merge all 4 documents together and calculate standardized scores
merge 1:m Reviewer1 using "/Users/abigailorbe/Documents/repos/econ490-fall22/Abigail - abigailorbe/Week 4/0_data/intermediary/grant_prop_review_2022_fixed.dta", nogenerate
gen stand_r1_score = (Reviewer1Score - mean_rev1)/sd_rev1
drop mean_rev1 sd_rev1

merge m:1 Reviewer2 using rev2merge, nogenerate
gen stand_r2_score = (Reviewer2Score - mean_rev2)/sd_rev2
drop mean_rev2 sd_rev2

merge m:1 Reviewer3 using rev3merge, nogenerate
gen stand_r3_score = (Reviewer3Score - mean_rev3)/sd_rev3
drop mean_rev3 sd_rev3

// Calculate average standardized score
local scores "stand_r1_score stand_r2_score stand_r3_score"
gen average_stand_score = (stand_r1_score+stand_r2_score+stand_r3_score)/3

// Rank by average standardized score
drop if Reviewer3 == "ynd3" // this person did not complete a Review3 so a new row with empty columns was created
sort average_stand_score
gen rank = 129 - _n

// Save
cd "/Users/abigailorbe/Documents/repos/econ490-fall22/Abigail - abigailorbe/Week 4/2_outputs"
save question4
