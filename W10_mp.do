* Week 10 assignment
* Migle Petrauskaite

clear

***>>> PLEASE REMEMBER TO CHANGE TO OWN FILE PATH BEFORE RUNNING THE CODE <<<<***

* Input directory 
global input_dir "/Users/miglepetrauskaite/Library/CloudStorage/Box-Box"

* Output directory 
global output_dir "/Users/miglepetrauskaite/Documents/1. Washington DC/Academics/3 Semester /Research fieldwork and analysis/w10_outputs"


* Datasets
global popdensity  "$input_dir/Econ490_Fall2022/week_10/03_assignment/01_data/CIV_populationdensity.xlsx"
global hhdata "$input_dir/Econ490_Fall2022/week_10/03_assignment/01_data/CIV_Section_0.dta"
global gps_data "$input_dir/Econ490_Fall2022/week_10/03_assignment/01_data/GPS Data.dta"
global wards10 "$input_dir/Econ490_Fall2022/week_10/03_assignment/01_data/Tz_elec_10_clean.dta"
global wards15 "$input_dir/Econ490_Fall2022/week_10/03_assignment/01_data/Tz_elec_15_clean.dta"


*********************** Question 1 ***********************

import excel $popdensity, firstrow clear

* Keeping only department-level data

keep if regex(NOMCIRCONSCRIPTION, "DEPARTEMENT")

* Cleaning up the names by getting rid of French partitive articles

replace NOMCIRCONSCRIPTION =  subinstr(NOMCIRCONSCRIPTION,"DEPARTEMENT","",.)
replace NOMCIRCONSCRIPTION =  subinstr(NOMCIRCONSCRIPTION,"D' ","",.)
replace NOMCIRCONSCRIPTION =  subinstr(NOMCIRCONSCRIPTION,"D'","",.)
replace NOMCIRCONSCRIPTION =  subinstr(NOMCIRCONSCRIPTION,"DE ","",.)
replace NOMCIRCONSCRIPTION =  subinstr(NOMCIRCONSCRIPTION,"DU ","",.)

* Eyeballing to check for any other "de" "du" "d'" remaining
sort NOM

* Collapsing consecutive internal blanks to one and getting rid of capital letters
replace NOMCIRCONSCRIPTION = lower(strtrim(stritrim(NOMCIRCONSCRIPTION))) 

* Changing the variable name
rename NOMCIRCONSCRIPTION department

* Correcting typos in department names
replace department="arrha" if department=="arrah"

* Saving a temporary file that will be used to merge datasets
tempfile density
save `density', replace	

* Loading household data
use $hhdata, clear

* Destringing variables
decode b06_departemen, gen(department)

* Merging multiple to one
merge m:1 department using `density'

* Finding and dropping variables with no information
sort _mer
drop if _merge==2 // dropping the observation with no info
drop _merge // dropping the merge variable we no longer need

* Ordering data to compare more easily
order departm b06

* Exporting results file in .csv format
cd "$output_dir"
save week10_q1, replace


*********************** Question 2 ***********************

* Uncomment to install geodist command if needed
* ssc install geodist

* Importing data
use "$gps_data", clear

* Checking for potential clusters
sort lat longit
scatter lat longit

* Assigning ~6 households per interviewer as per question prompt
egen enumerator_id=seq(), block(6) 

* Approximating geeographical distance between nearby households in the same cluster
bysort enumerator_id (longit latit): gen lat2 = latitude[_n+1] // takes the value of the next latitude osbervation (these are sorted in ascending order)
bysort enumerator_id (longit latit): gen long2 = longitude[_n+1] // same principle as above 
geodist latit longit lat2 long2, gen(distance) miles 
 
* Approximating distance travelled per enumerator
bysort enumerator_id: egen distance_travelled = total(distance)  
sum distance_travelled 

* Exporting results
cd "$output_dir"
save week10_q2, replace

*********************** Question 4.1 ***********************

* Import 2010 election data
use $wards10, clear

* Prepare variables for the merge
rename (region_10 district_10 ward_10) (region district ward)
drop total_can ward_tot

* Save tempfile for merging
tempfile wards2010
save `wards2010', replace

* Import 2015 election data
use $wards15, clear

* Prepare variables for merging
rename (region_15 district_15 ward_15) (region district ward)
drop total_can ward_tot

* Merge the two datasets using the common variables prepared in the steps above
merge 1:1 region district ward using `wards2010' 

* Assigning categories
gen int category = _merge
drop _merge
order ward_id_10 ward_id_15 ward category // for easier identification of ward categories
sort category
label var category "Ward categories"
label def ward_categories 1 "parentless ward" 2 "childless ward" 3 "both wards"
label val category ward_categories
descr
labelbook ward_categories 

* Exporting results
cd "$output_dir"
save week10_q4, replace

******************************** END OF DO-FILE ********************************
