/* --------------------------------
Problem Set: Week 10
ECON 490
Sylvia Brown
 --------------------------------*/

/* --------------------------------

BEFORE RUNNING THIS CODE:
1) CHANGE DIRECTORY BELOW TO THE FILEPATH TO YOUR VERSION OF THE BOX FOLDER IN YOUR LAPTOP
2) if not already installed, install geodist command by running the following code in the command line: ssc install geodist
3) if not already installed, install reclink2 command by running the following three lines of code in the command line:
	net from http://www.stata-journal.com/software/sj15-3
	net install dm0082.pkg, replace
	net get dm0082.pkg, replace
4) if not already installed, install strdist command by running the following code in the command line: ssc install strdist

 --------------------------------*/

clear
global user "/Users/sylviabrown/Library/CloudStorage/Box-Box/Econ490_Fall2022/week_10/03_assignment"
* ^^^^^^^^^^^^^^^^ THIS IS WHERE YOU NEED TO UPDATE THE FILE PATH ^^^^^^^^^^^^^^^^
cd $user

/* ------------

QUESTION 1

 -------------*/

// import Excel data 
global civ_density "$user/01_data/CIV_populationdensity.xlsx"
global civ_section0 "$user/01_data/CIV_Section_0.dta"
import excel "$civ_density", sheet("Population density") firstrow clear

// keep all rows of Excel sheet that are 'departement'
keep if regex(NOMCIRCONSCRIPTION, "DEPARTEMENT")

// remove the phrase preceding the name of department in variable that contains department name
replace NOMCIRCONSCRIPTION =  subinstr(NOMCIRCONSCRIPTION,"DEPARTEMENT DE ", "", .)
replace NOMCIRCONSCRIPTION =  subinstr(NOMCIRCONSCRIPTION,"DEPARTEMENT DU ", "", .)
replace NOMCIRCONSCRIPTION =  subinstr(NOMCIRCONSCRIPTION,"DEPARTEMENT D' ", "", .)
replace NOMCIRCONSCRIPTION =  subinstr(NOMCIRCONSCRIPTION,"DEPARTEMENT D'", "", .)

// make the values of variable that contains the name of the department all lower case
replace NOMCIRCONSCRIPTION = lower(strtrim(stritrim(NOMCIRCONSCRIPTION)))

// rename the variable that contains the name of the department so that it is in english
rename NOMCIRCONSCRIPTION department

// rename all variables so that they are lowercase
rename _all, lower

// fix typos in department names
replace department="arrha" if department=="arrah"

tempfile density
save `density'	

use "$civ_section0", clear 
decode b06_departemen, generate(department) 

// merge cleaned Excel data into village data file
merge m:1 department using `density'

// because "gbeleban" department appears in Excel data but not village data file, drop observation 
//where department is "gbeleban" because most information about this department is missing
drop if department == "gbeleban"

// drop _merge variable resulting from merging datasets
drop _merge

/* ------------

QUESTION 2

 -------------*/

// create empty temporary file
clear
tempfile question2
save `question2', replace emptyok

// import GPS data 
global location_data "$user/01_data/GPS data.dta"
use "$location_data", clear 

// rename variables 
rename (id latitude longitude) (id_pair latitude_pair longitude_pair)

// save this dataset as a temporary file
tempfile gps
save `gps'

// rename variables in this dataset to indicate it represents the list of original households
rename (id_pair latitude_pair longitude_pair) (id_orig latitude_orig longitude_orig)

// rank households according to how leftmost (according to longitude) they are -- ties are split using latitude and id number
sort longitude_orig latitude_orig id_orig
generate leftmost_rank = _n

// create a local macro representing total number of households
local obs_count = _N

// form pairwise combinations of every household in original dataset
cross using `gps'

// drop any observations where a household is being compared against itself
drop if id_orig == id_pair

* ------------ assigning enumerator using geodist command ------------ *
// create an empty enumerator variable
generate enumerator = .

// calculate distances between each original household and all of its comparison households
geodist latitude_orig longitude_orig latitude_pair longitude_pair, generate(geo_dist)

// create a variable for loop equal to the number of enumerators we have available
local num_enum = 19

// create variable for number of households per enumerator
local hh_per_enum = floor(`obs_count'/`num_enum')

// loop through each household to find closest households, assign the group to a single enumerator, and drop the relevant
// observations so that we do not assign households to more than one enumerator. After one cluster of households
// is assigned, the algorithm moves onto the next leftmost (by longitude) household.
forvalues i=1/`num_enum' {

	quietly summarize leftmost_rank // find the minimum of the rank variable in the dataset
	local min_left_rank = r(min) // save the minimum as a local
	preserve // save the existing version of the dataset wth the pairwise comparisons
	keep if leftmost_rank == `min_left_rank' // keep if it is the leftmost household remaining in the dataset
	sort geo_dist // sort by geographical distance
	generate dist_rank = _n // rank households that this household is compared to by their distance from the household of interest
	keep if dist_rank <= `hh_per_enum' // keep households that are close enough to the household of interest such that the 19 enumerators can cover every household in the village
	
	// create a local variable representing the list of households that are closest to our household of interest
	levelsof id_pair, local(levels_temp) separate(",")
	
	// restore the existing version of the dataset wth the pairwise comparisons
	restore
	
	// save the existing version of the dataset wth the pairwise comparisons
	preserve
	
	keep if inlist(id_orig, `levels_temp') | leftmost_rank == `min_left_rank' // keep rows in pairwise comparison dataset that are either the household of interest of the households close to it
	replace enumerator = `i' // asign enumerator variable
	levelsof id_orig, local(levels_temp2) separate(",") // save a list of the households assigned an enumerator in this run of the loop
	collapse enumerator, by(id_orig) // collapse data such that there is one row for each household assigned an enumerator in this run of the loop
	rename id_orig id // rename id_orig variable to name of id variable in original dataset
	
	// append list of villages assigned enumerators in this run of the loop and their household ids to temporary file
	append using `question2'
	save `question2', replace
	
	// restore the existing version of the dataset wth the pairwise comparisons
	restore

	// drop any rows in the existing version of the dataset wth the pairwise comparisons 
	// where the original household or the households it is being compared to have already been assigned enumerator
	drop if inlist(id_pair, `levels_temp2')
	drop if inlist(id_orig, `levels_temp2')
	
}
// reopen original dataset
use "$location_data", clear

// merge enumerator assignments to original dataset
merge 1:1 id using `question2'

// drop merge variable
drop _merge

// generate mean distance of household from cetner of household cluster it was
// assigned to in order to check whether algorithm produced low travel distances
// for enumerators
bysort enumerator: egen avg_lat = mean(latitude)
bysort enumerator: egen avg_long = mean(longitude)
geodist latitude longitude avg_lat avg_long, generate(geodist_test_wenum)
bysort enumerator: egen avg_dist = mean(geodist_test_wenum)

// find average distance enumerator must travel from center of assigned
// cluster to each household
sum avg_dist

// generate mean distance of household from central point to compare to
// average mean distance of households in enumerator cluster from central point in enumerator cluster
egen avg_lat_all = mean(latitude) // calculate average latitude of all households
egen avg_long_all = mean(longitude) // calculate average longitude of all households
geodist latitude longitude avg_lat_all avg_long_all, generate(geodist_test_all) // calculate distance of each household from central point
sum geodist_test_all // find average distance of each household from central point

// drop testing variables
drop avg_lat avg_long geodist_test_wenum avg_dist avg_lat_all avg_long_all geodist_test_all

/* ------------

QUESTION 4

 -------------*/
// load 2010 data and create empty temporary file
global tz_elec_15_clean "$user/01_data/Tz_elec_15_clean.dta"
global tz_elec_10_clean "$user/01_data/Tz_elec_10_clean.dta"
clear
tempfile question4
save `question4', replace emptyok
use "$tz_elec_10_clean", clear 

// keep only variables of interest and create ID variable to be used when fuzzy matching 2010 and 2015 datasets
keep district_10 region_10 ward_10
rename (region_10 district_10 ward_10) (region district ward)
gen dist_id = _n

// save 2010 data as tempfile
tempfile data_10
save `data_10'

// load 2015 data, keep only variables of interest, and create ID variable to be used when fuzzy matching 2010 and 2015 datasets
use "$tz_elec_15_clean", clear 
keep region_15 district_15 ward_15
rename (region_15 district_15 ward_15) (region district ward)
gen idvar = _n

// fuzzy match datasets using reclink2, with multiple 2010 wards matching to the 2015 wards
reclink2 region district ward using `data_10', idmaster(idvar) idusing(dist_id) uprefix(_10) manytoone gen(score)

// delete duplicates of 2015 wards resulting from reclink2
duplicates drop region district ward, force

// create variables of string distance for region, district, and ward variables
strdist region _10region, gen(region_strdist)
strdist district _10district, gen(district_strdist)
strdist ward _10ward, gen(ward_strdist)

// replace _merge variable is not a perfect or near-perfect match in ward, district, and/or region
replace _merge = 2 if region_strdist >= 4 & _merge ~= 1
replace _merge = 2 if district_strdist >= 4 & _merge ~= 1
replace _merge = 2 if ward_strdist >= 3 & _merge ~= 1

// create empty variables for final region, district, and ward variables
generate region_final = ""
generate district_final = ""
generate ward_final = ""

// replace region, ward, and district variables with 2015 values if there was a perfect or 
// near-perfect match with 2010 data or if there was no match from 2010 data
replace region_final = region if _merge == 1 | _merge == 3
replace district_final = district if _merge == 1 | _merge == 3
replace ward_final = ward if _merge == 1 | _merge == 3

// preserve existing dataset
preserve

// keep only imperfect merges
keep if _merge == 2

// double each observation
expand 2

// create a count variable
generate count_n = _n

// replace region, ward, and district variables with 2015 values for half of
// observations and mark merge as having no match in 2010 data
replace region_final = region if mod(count_n,2) == 1
replace district_final = district if mod(count_n,2) == 1
replace ward_final = ward if mod(count_n,2) == 1
replace _merge = 1 if mod(count_n,2) == 1

// replace region, ward, and district variables with 2010 values for half of
// observations
replace region_final = _10region if mod(count_n,2) == 0
replace district_final = _10district if mod(count_n,2) == 0
replace ward_final = _10ward if mod(count_n,2) == 0

// keep only variables of interest
keep region_final district_final ward_final _merge

// drop any duplicates
duplicates drop 

// save these data on imperfect matches
save `question4', replace

// restore original dataset
restore

// drop any imperfect merges
drop if _merge == 2

// keep only variables of interest
keep region_final district_final ward_final _merge

// append data on imperfect merges
append using `question4'

// drop duplicates
duplicates drop region_final district_final ward_final if _merge == 2, force
duplicates tag region_final district_final ward_final, generate(test_var)
drop if test_var > 0 & _merge == 2

// recode ward type variable so that its values match the problem set
recode _merge 3=1 1=3
rename _merge ward_type

// add label for ward type variables
label define ward_type 1 "Ward is in both 2010 and 2015" 2 "Ward is only in 2010" 3 "Ward is only in 2015"
label values ward_type ward_type

// check if number of wards in 2015 and number of wards in 2010 match ward type counts
count if ward_type == 1 | ward_type == 3 // should equal 3,944
count if ward_type == 1 | ward_type == 2 // should equal 3,333 -- is too low, need to find where I'm dropping 2010 wards
