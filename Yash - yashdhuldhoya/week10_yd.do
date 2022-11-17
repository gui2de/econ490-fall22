** Author: Yash Dhuldhoya
** Last Modified: November 15, 2022
** Topic: Week 10 Assignment (Appending and merging)

********************************************************************************
clear 
set seed 1
set more off
********************************************************************************

** Setting global paths 

global user "/Users/devakid/Library/CloudStorage/Box-Box/"

global civ_density "$user/Econ490_Fall2022/week_10/02_data/CIV_populationdensity.xlsx"
global civ_section0 "$user/Econ490_Fall2022/week_10/02_data/CIV_Section_0.dta"

global gps "$user/Econ490_Fall2022/week_10/03_assignment/01_data/GPS Data.dta"

global tz_elec_10_clean "$user/Econ490_Fall2022/week_10/03_assignment/01_data/Tz_elec_10_clean"
global tz_elec_15_clean "$user/Econ490_Fall2022/week_10/03_assignment/01_data/Tz_elec_15_clean"


********************************************************************************
*Question 1 
********************************************************************************
import excel "$civ_density", sheet("Population density") firstrow clear
keep if regex(NOMCIRCONSCRIPTION, "DEPARTEMENT")
replace NOMCIRCONSCRIPTION =  subinstr(NOMCIRCONSCRIPTION,"DEPARTEMENT","",.)
replace NOMCIRCONSCRIPTION =  subinstr(NOMCIRCONSCRIPTION,"DE ","",.)
replace NOMCIRCONSCRIPTION =  subinstr(NOMCIRCONSCRIPTION,"D' ","",.)
replace NOMCIRCONSCRIPTION =  subinstr(NOMCIRCONSCRIPTION,"D'","",.)
replace NOMCIRCONSCRIPTION =  subinstr(NOMCIRCONSCRIPTION,"DU ","",.)
 
replace NOMCIRCONSCRIPTION = lower(strtrim(stritrim(NOMCIRCONSCRIPTION)))
rename NOMCIRCONSCRIPTION department
replace department="arrha" if department=="arrah"
tempfile density
save `density'  
 
    
use "$civ_section0", clear 
decode b06_departemen , generate(department) 
merge m:1 department using `density'
drop _merge 

********************************************************************************
*Question 2
********************************************************************************
local enumerator = 19 // given this information in the question 

clear 
tempfile final_allocation 
save `final_allocation', replace emptyok // creating and storing a temporary file for our final merges 
use "$gps", clear

count // counting the number of households/villages and storing them 
local num = ceil(r(N)/`enumerator') // generating the number of households each enumerator should visit and rounding upwards
local gap = (`num'*`enumerator') - r(N) // storing the difference between actual households and rounded households (equals 3)
local enumerator2 = `enumerator' - `gap' // Equals 16 
gen id2 = id // needed for geonear function

tempfile one 
save `one', replace 

foreach x of numlist 1/`enumerator' {
	preserve // running the loop across all enumerators. Also preserving the full dataset before subsetting as shown later
		geonear id latitude longitude using `one', long neighbors (id2 latitude longitude) nearcount (`num') 
		keep in 1/`num' // keeping the nearest 5-6 households/villages (the exact number will depend on the enumerator number)
		gen enum_id = `x'
		keep id2 enum_id
		levelsof id2, local(drop) // storing the unique ids as a local so that they can be dropped from the subsequent loops 
		append using `final_allocation'
		save `final_allocation', replace 
	restore 
		foreach y of local drop {
			drop if id == `y' 
		}
	save `one', replace 
	if `x' == `enumerator2' local num = `num' - 1 // our condition will be met when x is 16. Thus for the subsequent enumerators (17 through 19) they will only interview five households since local num will change from 6 to 5. 
}

use `final_allocation', clear 
rename id2 id 
merge 1:1 id using "$gps"
drop _merge

order enum_id
sort enum_id id 


********************************************************************************
*Question 4a
********************************************************************************
use "$tz_elec_15_clean", clear
keep region_15 district_15 ward_15 // keep variables of interest 
duplicates drop // drop duplicates 
rename (region_15 district_15 ward_15) (region district ward) // renaming variables for easier merging 
sort region district ward 
replace ward = subinstr(ward, " i", "",.) // cleaning and trimming strings 
replace ward = subinstr(ward, " a", "",.)
replace ward = stritrim(strtrim(ward))
sort region district ward 

tempfile tz_15 // saving results in a temporary file 
save `tz_15', replace 

** the same process that was used for preparing the 2015 data is being used for the 2010 data ** 
use "$tz_elec_10_clean", clear
keep region_10 district_10 ward_10 // keep variables of interest 
duplicates drop // drop duplicates 
rename (region_10 district_10 ward_10) (region district ward) // renaming variables for easier merging 
sort region district ward 
replace ward = subinstr(ward, " i", "",.) // cleaning and trimming strings 
replace ward = subinstr(ward, " a", "",.)
replace ward = stritrim(strtrim(ward))
sort region district ward 

merge 1:1 region district ward using `tz_15' // merging the two datasets 

tab _merge // checking merge status 
gen ward_status = _merge
label define ward_type 1 "childless ward" 2 "parentless ward" 3 "Both years" // define three conditions as outlined in the question
label values _merge ward_type // assign value to each label
drop ward_status
rename _merge ward_status

** checking if 2010 wards = 3,333 and 2015 wards = 3,944 
gen wards_2010 = 1 if ward_status == 1 | ward_status == 3 // generating variable to include only 2010 wards 
gen wards_2015 = 1 if ward_status == 2 | ward_status == 3 // generating variable to include only 2015 wards
sum wards_2010 wards_2015 
