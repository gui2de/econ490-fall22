******Week 10 assignment
******Oghenefegor Omorojor


*Input directory
global import "/Users/user/Box Sync/01_data"


*Output directory
global output "/Users/user/Documents/Stata"


*****************Question 1: Merging data********************

* Importing data
global civ_pop_density "$import/CIV_populationdensity.xlsx"
global civ_section0 "$import/CIV_Section_0.dta"

* Importing excel file
import excel "$civ_pop_density", firstrow clear

* Keeping only the data on department level
keep if regex(NOMCIRCONSCRIPTION, "DEPARTEMENT") 

* Cleaning unnecessary data
replace NOMCIRCONSCRIPTION =  subinstr(NOMCIRCONSCRIPTION,"DEPARTEMENT","",.)
replace NOMCIRCONSCRIPTION =  subinstr(NOMCIRCONSCRIPTION,"DE ","",.)
replace NOMCIRCONSCRIPTION =  subinstr(NOMCIRCONSCRIPTION,"D' ","",.)
replace NOMCIRCONSCRIPTION =  subinstr(NOMCIRCONSCRIPTION,"DU ","",.)

* Turning the words into lowercase letters
replace NOMCIRCONSCRIPTION = lower(strtrim(stritrim(NOMCIRCONSCRIPTION))) 

* New variable name
rename NOMCIRCONSCRIPTION departement 

* Create tempfile
tempfile density
save `density', replace

* To merge
merge 1:m departement using "density" 
sort _merge 
keep if _merge == 2
drop _merge
	
	
use "$civ_section0", clear 

exit



********Question 2: Algorithm to assign each household*******

ssc install geodist

* Create tempfile
clear


* Importing the data
global gps_data "$import/GPS Data.dta"
use "$gps_data"

* Creating 6 households
egen enumerator_id=seq(), block(6)

* Renaming first variables to place in first file
tempfile geography
save `geography', replace emptyok
rename (id latitude longitude) (id_new latitude_new longitude_new)

* Renaming for second file
tempfile gps
save `gps'
rename (id_new latitude_new longitude_new)(id_final latitude_final longitude_final)

* Estimating distance
geodist latitude_new longitude_new latitude_final longitude_final, generate (distance)

bysort enumerator_id: egen miles_per_hr = total(distance)

cd "$output"


***********************Question 4.1**************************

* Import datasets
global tz_10 "$import/Tz_elec_10_clean.dta"
global tz_15 "$import/Tz_elec_15_clean.dta"

use "$tz_10"

rename (region_10 district_10 ward_10) (region district ward)

* New tempfile
tempfile ward_new
save `ward_new', replace

* To merge datasets based on district
use "$tz_15", clear
rename (region_15 district_15 ward_15)(region district ward)
merge 1:1 region district ward using `ward_new'

* Generating categorical variables
gen final_ward = _merge
drop _merge

sort final_ward
label var final_ward "Categories"
label def final_ward 1 "parentless ward" 2 "childless ward" 3 "total wards"
label val final_ward categories

cd "$output"
