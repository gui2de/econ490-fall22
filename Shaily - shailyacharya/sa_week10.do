********************************************************************************
* Econ 490: Week 10
* Stata Homework Assignment
* Shaily Acharya
********************************************************************************
set more off
clear
global user "/Users/shailyacharya/Box/Econ490_Fall2022/week_10/03_assignment"
/*******************************************************************************
Q1: COTE D'IVOIRE (completed in class)
*******************************************************************************/
*set globals and load data
global civ_density "$user/01_data/CIV_populationdensity.xlsx"
global civ_section0 "$user/01_data/CIV_Section_0.dta"
import excel "$civ_density", sheet("Population density") firstrow clear

*keep only department data
keep if regex(NOMCIRCONSCRIPTION, "DEPARTEMENT")

*clean up department column so all of the names are standardized
replace NOMCIRCONSCRIPTION =  subinstr(NOMCIRCONSCRIPTION,"DEPARTEMENT DE ", "", .)
replace NOMCIRCONSCRIPTION =  subinstr(NOMCIRCONSCRIPTION,"DEPARTEMENT DU ", "", .)
replace NOMCIRCONSCRIPTION =  subinstr(NOMCIRCONSCRIPTION,"DEPARTEMENT D' ", "", .)
replace NOMCIRCONSCRIPTION =  subinstr(NOMCIRCONSCRIPTION,"DEPARTEMENT D'", "", .)

replace NOMCIRCONSCRIPTION = lower(strtrim(stritrim(NOMCIRCONSCRIPTION)))

replace NOMCIRCONSCRIPTION="arrha" if NOMCIRCONSCRIPTION=="arrah"

*rename density and department columns and drop the other columns
rename DENSITEAUKM density
rename NOMCIRCONSCRIPTION department

drop SUPERFICIEKM2 POPULATION

*save data as a tempfile
tempfile density
save `density'	

*load the section data, make it ready to merge
use "$civ_section0", clear 
decode b06_departemen, generate(department) 

*merge the two datasets 
merge m:1 department using `density'

*double-check the merge, and drop any unmerged cases
tabulate department if _merge == 1 
tabulate department if _merge == 2 

drop if department == "gbeleban"

// drop merge variable to makee dataset cleaner
drop _merge

/*******************************************************************************
Q2: HOUSEHOLD ASSIGNMENTS
*******************************************************************************/
*ssc install geodist
*set globals and load data
global hh_gps "$user/01_data/GPS Data.dta"
use "$hh_gps", clear

*sort longitude and latitude, and create scatterplot to see which households are close together
sort latitude longitude
scatter latitude longitude

*assign 6 households to each enumerator
egen enumerator=seq(), block(6)

* for each observation, generate variable that shows the distance from one household to the next 
bysort enumerator (longitude latitude): gen latitude2 = latitude[_n+1]
bysort enumerator (longitude latitude): gen longitude2 = longitude[_n+1]
geodist latitude longitude latitude2 longitude2, generate(hh_distance)

* confirm that the distance that each enumerator travels is relatively similar
bysort enumerator: egen enumerator_distance = total(hh_distance)
tab enumerator_distance

/*******************************************************************************
Q4: TANZANIA WARDS (revised)
*******************************************************************************/
global tz_elec15 "$user/01_data/Tz_elec_15_clean.dta"
global tz_elec10 "$user/01_data/Tz_elec_10_clean.dta"

*we combine district and ward names in both datasets. use tempfiles for this. keep relevant vars and create id
use "$tz_elec10", clear
gen district_ward = district_10 + " " + ward_10
ren region_10 region
gen id = _n
tempfile tz_elec10
save `tz_elec10'

use "$tz_elec15", clear
gen district_ward = district_15 + " " + ward_15
ren region_15 region
tempfile tz_elec15
save `tz_elec15'

*merge the cleaned data 
merge 1:1 district_ward using `tz_elec10'

*label wards that were merged properly (so they exist in both years)
gen ward_exists = .
replace ward_exists = 1 if _merge == 3

*label wards that were only in 2010
replace ward_exists = 2 if _merge == 2

*label wards that were only in 2015
replace ward_exists = 3 if _merge == 1

* show the ward counts in 2010 and 2015
tab ward_exists

