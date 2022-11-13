********************************************************************************
* Econ 490: Week 10
* Abigail Orbe
* Nov 14th, 2022
********************************************************************************
** Basic Setup
clear 
set seed 09012018
set more off

// Change to align with your directory
global user "/Users/abigailorbe/Library/CloudStorage/Box-Box"

// Change to align with where you'd like the outputs to be exported
global export "/Users/abigailorbe/Documents/repos/econ490-fall22/Abigail - abigailorbe/Week10/outputs/"

********************************************************************************
* Question 1
********************************************************************************
// Set globals
global civ_density "$user/Econ490_Fall2022/week_10/03_assignment/01_data/CIV_populationdensity.xlsx"
global civ_section0 "$user/Econ490_Fall2022/week_10/03_assignment/01_data/CIV_Section_0.dta"

// Load data
import excel "$civ_density", sheet("Population density") firstrow clear

// Filter to only include department data
keep if regex(NOMCIRCONSCRIPTION, "DEPARTEMENT")

// Standardize department column
replace NOMCIRCONSCRIPTION =  subinstr(NOMCIRCONSCRIPTION,"DEPARTEMENT DE","",.)
replace NOMCIRCONSCRIPTION =  subinstr(NOMCIRCONSCRIPTION,"DEPARTEMENT D'","",.)
replace NOMCIRCONSCRIPTION =  subinstr(NOMCIRCONSCRIPTION,"DEPARTEMENT DU","",.)

replace NOMCIRCONSCRIPTION = lower(strtrim(stritrim(NOMCIRCONSCRIPTION)))

// Fixing spelling discrepancy with CIV section data
replace NOMCIRCONSCRIPTION = "arrha" if NOMCIRCONSCRIPTION == "arrah"

// Keep only density and department columns
drop SUPERFICIEKM2 POPULATION

// Rename columns
rename DENSITEAUKM density
rename NOMCIRCONSCRIPTION department

// Save density data frame
tempfile density
save `density'	

// Load CIV section data and prepare for merge
use "$civ_section0", clear
decode b06_departemen, generate(department)

// Merge
merge m:1 department using `density'

// Look at unmerged cases
tabulate department if _merge == 1 // all observations in civ_section0 are matched
tabulate department if _merge == 2 // there is one district not in the civ_section0 data

// Export
cd "$export"
export delimited 01_civ, replace
********************************************************************************
* Question 2
********************************************************************************
// Load data
global households "$user/Econ490_Fall2022/week_10/03_assignment/01_data/GPS Data.dta"
use "$households", clear

// View map
scatter longitude latitude

*** Creating groups
// Sorting by latitude and longitude
sort latitude longitude
	** After sorting the data by both latitude and longitude, subsequent observations will be close together geographically

// Generate groups of 6 observations
egen group=seq(), block(6)

*** Quantifying how close together grouped households are
// Generate difference to next observation
bysort group (longitude latitude): gen next_latitude = latitude[_n+1]
bysort group (longitude latitude): gen next_longitude = longitude[_n+1]
geodist latitude longitude next_latitude next_longitude, generate(dist_next)

// Check that total distance covered is similar and reasonable for all enumerators
bysort group: egen total_enum_distance = total(dist_next)

tabulate total_enum_distance // all enumerators are walking under 2 miles
summarize total_enum_distance // enumerators are walking under 1 mile on average

// Export
cd "$export"
export delimited 02_enumerator, replace
********************************************************************************
* Question 3
********************************************************************************
// Set globals
global tzelec10 "$user/Econ490_Fall2022/week_10/03_assignment/01_data/Tz_elec_10_clean.dta"
global tzelec15 "$user/Econ490_Fall2022/week_10/03_assignment/01_data/Tz_elec_15_clean.dta"

// Save 2010 dataset with column that combines district and ward names
use "$tzelec10", clear
gen distward = district_10 + " " + ward_10
tempfile elec10
save `elec10'

// Save 2015 dataset with column that combines district and ward names
use "$tzelec15", clear
gen distward = district_15 + " " + ward_15
tempfile elec15
save `elec15'

** Identify wards with identical 2015 and 2010 names
// Merging 2010 and 2015 datasets
quietly merge 1:1 distward using `elec10'

// Save information from wards that were merged successfully
preserve
keep if _merge == 3
gen ward_type = 1 // this is a categorical variable which =1 when the ward is in both 2015 and 2010
keep region_10 district_10 ward_10 ward_15 ward_type // because these wards are perfectly matched, the region and district columns are identical in 2010 and 2015, so we only have to save the region and ward columns from one year
rename region_10 region
rename district_10 district
tempfile matched
save `matched'
restore

** Wards that do not have an identical name match
// Creating a list of wards that were not merged successfully
drop if _merge == 3
keep distward
tempfile notmatched
save `notmatched'

// Generate list of 2010 wards that were not matched by merging full 2010 data with list of unmatched wards
quietly merge 1:1 distward using `elec10'
keep if _merge == 3 // keep only wards whose names were found in the unmatched list
drop _merge
	// Put the data in same format as `matched' 
	rename district_10 district
	rename region_10 region
	keep region district ward_10
	tempfile notmatched10
	save `notmatched10'

// Generate list of 2015 wards that were not matched by merging full 2010 data with list of unmatched wards
use `elec15', clear
quietly merge 1:1 distward using `notmatched'
keep if _merge == 3
drop _merge
	// Putting in same format as `matched' 
	rename district_15 district
	rename region_15 region
	keep region district ward_15
	tempfile notmatched15
	save `notmatched15'

** Addressing potential for spelling inconsistencies
	* There is a possibility that there are wards that existed in both 2010 and 2015 but whose names are spelt differently between the years. Thus, they would not have been matched in the initial merge on line 108. To match these wards, we can compare unmatched ward names in the same district, create a similarity score that tells us how comparable their names are, and use this similarity score to identify these "pseudo-identical" matches.
	
// Merge unmatched 2010 and 2015 wards in the same district
quietly merge m:m region district using `notmatched10'
	// this creates pairwise combinations of unmatched ward names in each district

// Generate similarity scores for ward names
matchit ward_15 ward_10

// If the similarity score is over 80%, we consider the two ward names pseudo-identical matches
drop if similscore < .80
gen ward_type = 1
	// looking at the data, you'll notice that these ward names differ by a few letters or spaces

// Adding these pseudo-identical matches to our tempfile of matched wards
keep region district ward_10 ward_15 ward_type
append using `matched'
tempfile allmatched
save `allmatched'

** Identifying wards only found in 2010
// Merging all matched wards with previously unmatched 2010 ward names
use `notmatched10', clear
quietly merge 1:1 region district ward_10 using `allmatched'
keep if _merge == 1 // only keep wards that are found in 2010 but not in the matched list
replace ward_type = 2 // this is a categorical variable which =2 when the ward is only found in 2010
drop _merge

// Add these wards to our tempfile of matched wards
append using `allmatched'
tempfile identified
save `identified'

** Identifying wards only found in 2015
// Merging matched names with previously unmatched 2015 ward names
use `notmatched15', clear
quietly merge 1:1 region district ward_15 using `allmatched'
keep if _merge == 1
replace ward_type = 3 // this is a categorical variable which =3 when the ward is only found in 2015
drop _merge

// Add these wards to our tempfile of categorized wards
append using `identified'
gen ward_id = _n // generating a unique identifier for each ward
label define ward_type 1 "In both 2010 and 2015" 2 "Only in 2010" 3 "Only in 2015"

** Check that these categories produce correct number of wards
quietly tabulate ward_type if ward_type == 1 
scalar bothyears = r(N)
quietly tabulate ward_type if ward_type == 2
scalar only2010 = r(N)
quietly tabulate ward_type if ward_type == 3
scalar only2015 = r(N)
display "Number of wards in 2010: " bothyears + only2010
display "Number of wards in 2015: " bothyears + only2015
***** 3,333 wards are either found in both 2015 and 2010 OR only found in 2010, confirming the number of wards we know existed in 2010. Similarly, 3,944 wards are either found in both 2015 and 2010 OR only found in 2015, confirming the number of wards we know existed in 2015. Thus, we have reason to believe that our categorization of the wards is correct.

// Export
cd "$export"
export delimited 03_wards, replace
