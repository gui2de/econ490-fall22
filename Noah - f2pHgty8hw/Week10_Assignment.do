///////////////////////////////////////
///*** ECON 490 WEEK 10 HOMEWORK ***///
///////////////////////////////////////

*Name: Noah Blake Smith

*Date: November 13, 2022

clear all
set seed 1
set more off

global user "/Users/nbs/Desktop/week_10/03_assignment/01_data/" // User should to appropriate folderpath

////////////////////////
///*** QUESTION 1 ***///
////////////////////////

*Set globals
global civ_density "$user/CIV_populationdensity.xlsx"
global civ_section0 "$user/CIV_Section_0.dta"

*Import data
import excel "$civ_density", sheet("Population density") firstrow clear

*Include only department data
keep if regex(NOMCIRCONSCRIPTION,"DEPARTEMENT")

*Extract relevant information and clean up
replace NOMCIRCONSCRIPTION = subinstr(NOMCIRCONSCRIPTION,"DEPARTEMENT DE","",.)
replace NOMCIRCONSCRIPTION = subinstr(NOMCIRCONSCRIPTION,"DEPARTEMENT D'","",.)
replace NOMCIRCONSCRIPTION = subinstr(NOMCIRCONSCRIPTION,"DEPARTEMENT DU","",.)
replace NOMCIRCONSCRIPTION = lower(strtrim(stritrim(NOMCIRCONSCRIPTION)))

*Rename variables
ren NOMCIRCONSCRIPTION department
ren DENSITEAUKM density
ren *, lower

*Fix typo
replace department="arrha" if department=="arrah"

*Create and save tempfile
tempfile density
save `density'

*Import, clean, and merge CIV data
use "$civ_section0", clear
decode b06_departemen, generate(department)
merge m:1 department using `density'

*Check for errors
tabulate department if _merge == 1 // No observations in civ_section0 are unmatched_
tabulate department if _merge == 2 // One district not in civ_section0 called "gbeleban" (problematic but not world-ending)

*Outro
compress
save "question1.dta", replace

////////////////////////
///*** QUESTION 2 ***///
////////////////////////

*Setup
clear all
global gps_data "$user/GPS data.dta"
use "$gps_data", clear

*ssc install geodist // User-created command to calculate distances

gen j = 100000 // Arbitrary number for loop below
local i = 0 // Counter for loop below

while j[1] > 60000 { // Arbitrary threshold I chose that seemed reasonable
	
	local i = `i' + 1 // Update then display loop number
	di `i'
	
	cap drop longitude0 latitude0 distance longitude_* latitude_* group length height area criterion // Drop variables from previous loop
	
	*Choose random coordinate
	local latitude0 = runiform(-90,90)
	local longitude0 = runiform(-180,180)
	gen latitude0 = `latitude0'
	gen longitude0 = `longitude0'

	geodist latitude longitude latitude0 longitude0, gen(distance) // Calculate distance of each village to mutual point

	sort distance latitude longitude // Sort dataset by distance to arbitrary point

	egen group = seq(), block(6) // Group villages by 6
	
	///*** Validation ***///

	*Gen max and min latitudes and longitudes by group
	egen latitude_max = max(latitude), by(group)
	egen latitude_min = min(latitude), by(group)
	egen longitude_max = max(longitude), by(group)
	egen longitude_min = min(longitude), by(group)

	*Take max of length, height, and area for each group as the criterion to measure of goodness-of-fit (i.e., group cluster cohesion)
	gen length = (latitude_max - latitude_min) * 10^7 // Scaled by 10^7 for ease of interpreting numbers; no impact on outcome
	gen height = (longitude_max - longitude_min) * 10^7
	gen area = (latitude_max - latitude_min) * (longitude_max - longitude_min) * 10^7
	egen criterion = rowmax(length height area)
	
	*Replace j with mean criterion
	qui sum criterion
	replace j = `r(mean)'
	di j[1]
}

*ssc install sepscatter // Install command written by Stata genius Nick Cox
sepscatter latitude longitude, separate(group) legend(off) // Scatter data, color-coded by group

/*Check if scattered data seems reasonably grouped. If not, rerun loop with a j of your choosing.*/

*Outro
keep latitude longitude id age female group
compress
save "question2.dta", replace

//////////////////////////
///*** QUESTION 4.1 ***///
//////////////////////////

*Set globals
clear all
global tz_elec_10_clean "$user/Tz_elec_10_clean.dta"
global tz_elec_15_clean "$user/Tz_elec_15_clean.dta"

*Clean 2010 data
use "$tz_elec_10_clean", clear
gen merge_variable = region_10 + "_" + district_10 + "_" + ward_10 // Variable on which merges/comparisons will be performed
tempfile elec_10
save `elec_10'

*Clean 2015 data
use "$tz_elec_15_clean", clear
gen merge_variable = region_15 + "_" + district_15 + "_" + ward_15
tempfile elec_15
save `elec_15'

///*** Step 1: perfect matches ***///

merge 1:1 merge_variable using `elec_10' // Merge 2010 and 2015 data

preserve // Save for later

keep if _merge==3 // Keep perfect matches

gen ward_category = . // Generate category variable
replace ward_category = 3 // In both 2010 and 2015

keep region_* district_* ward_* // Keep only relevant variables
ren (region_10 district_10) (region district) // Rename, given perfect match

tempfile matched_step_1
save `matched_step_1'

///*** Step 2: non-perefect-matches ***///

restore

keep if _merge!=3 // Keep non-perfect-matches
keep merge_variable // Keep only relevant variable

tempfile unmatched_step_2
save `unmatched_step_2'

///*** Step 3: 2010 non-perfect-matches ***///

merge 1:1 merge_variable using `elec_10'
keep if _merge==3 // Keep only data in 2010 and nonmatched
drop _merge

ren (region_10 district_10) (region district)

tempfile unmatched_10
save `unmatched_10'

///*** Step 4: 2015 non-perfect-matches ***///

use `elec_15', clear

merge 1:1 merge_variable using `unmatched_step_2'
keep if _merge==3

drop _merge
ren (region_15 district_15) (region district)

tempfile unmatched_15
save `unmatched_15'

///*** Step 5: fuzzy matching ***///

joinby region district using `unmatched_10' // Join datasets by matching region and district

*ssc install freqindex
*ssc install matchit
matchit ward_10 ward_15 // Generates similarity score
hist similscore, freq bin(100) // Shows distribution of values
keep if similscore > 0.9 // Seems like a reasonable cutoff

gen ward_category = 3 // In 2010 and 2015

append using `matched_step_1'
tempfile matched_step_5
save `matched_step_5'

///*** Step 6: re-check 2010 ***///

use `unmatched_10', clear

merge 1:1 region district ward_10 using `matched_step_5' // Merge datasets on region, district, and ward_10
keep if _merge==1 // Keep if only in 2010
replace ward_category = 1 // In 2010 only
drop _merge

append using `matched_step_5'
tempfile master
save `master'

///*** Step 7: re-check 2015 ***///

use `unmatched_15', clear

merge 1:1 region district ward_15 using `matched_step_5'
keep if _merge==1
replace ward_category = 2 // In 2015 only
drop _merge

append using `master'

*Define and apply value label
la def ward_category_label 1 "In 2010 only" 2 "In 2015 only" 3 "In 2010 and 2015"
la val ward_category "ward_category_label"

*Check for errors
count if ward_category==1 | ward_category==3 // Equals 3,333 as expected
count if ward_category==2 | ward_category==3 // Equals 3,944 as expected

*Outro
order *, alpha
compress

save "question4.1.dta", replace
