********************************************************************************
* Econ 490: Week 10
* Handling datasets in Stata
* Bingjie (Victoria) Peng
* Nov 11st, 2022
********************************************************************************
clear 
set seed 1
set more off
global data_location = "/Users/victoriapeng/Desktop/490 Research Field/Week10/03_assignment/01_data" 
********************************************************************************

*1
clear
import excel "CIV_populationdensity", sheet("Population density") firstrow clear // import the excel dataset
keep if regexm(NOMCIRCONSCRIPTION,"DEPARTEMENT") // find departmente-level observations
replace NOMCIRCONSCRIPTION=subinstr(NOMCIRCONSCRIPTION," ","",.) // remove all spaces
replace NOMCIRCONSCRIPTION = substr(NOMCIRCONSCRIPTION, 14, .) // extract the parts that we want
keep NOMCIRCONSCRIPTION  DENSITEAUKM // keep variables that we want
tempfile table1 // create an empty file
save "table1.dta", replace emptyok
use "CIV_Section_0",clear
decode b06_departemen,generate(NOMCIRCONSCRIPTION) // generate a new variable based on the label
replace NOMCIRCONSCRIPTION = upper(NOMCIRCONSCRIPTION) // change into upper characters
merge m:1 NOMCIRCONSCRIPTION using "table1" // merge
drop if _merge == 2 // drop those only from the using dataset
drop _merge NOMCIRCONSCRIPTION 
erase table1.dta
save "CIV_Section_0_1", replace

*2
use "GPS Data.dta", clear
gen id1=id
gen id2=id
tempfile GPS // create an empty file
save GPS, replace //emptyok

use GPS, clear
geonear id1 latitude longitude using GPS , neighbors(id2 latitude longitude) within(50) long // find nearest villages for each village
gen n = _n 
keep if n <= 6 // find 6 nearest villages for the first village (including itself)
replace n = 1 // assign these 6 villages to the first enumerator
tempfile GPS1 // create an empty file for the enumerator ID
save GPS1, replace emptyok
use GPS, clear
merge 1:1 id2 using GPS1 
drop _merge
drop if n != . // drop thoes villages which have already been assigned
save GPS, replace emptyok
	
forvalues i = 2(1)18 { // create a loop for the next 17 enumerator
	use GPS, clear
	geonear id1 latitude longitude using GPS , neighbors(id2 latitude longitude) within(50) long
	gen n = _n
	keep if n <= 6
	replace n = `i'
	append using GPS1
	save GPS1, replace emptyok
	use GPS, clear
	merge 1:1 id2 using GPS1, replace update
	drop _merge
	drop if n != .
	save GPS, replace emptyok 
	}
	
use GPS, clear // the case for the last enumerator is a little bit different since s/he will be only assigned 3 villages
geonear id1 latitude longitude using GPS , neighbors(id2 latitude longitude) within(50) long
gen n = _n
keep if n <= 3
replace n = 19
append using GPS1
rename n enumerator_id 
gen id = id1
	
merge m:1 id using "GPS Data.dta" // add assigned enumerator IDs to the original dataset
drop if enumerator_id == .
keep id2 latitude longitude age female enumerator_id
sort id2
rename id2 id
save GPS_Data_final, replace

erase GPS.dta 
erase GPS1.dta
	


*4.1
use Tz_elec_10_clean, clear
gen region = region_10 
gen district=district_10 
gen ward=ward_10
keep ward_id_10 region district ward // keep variables needed
tempfile table2 // create an empty file
save "table2.dta", replace emptyok

use Tz_elec_15_clean, clear
gen region = region_15
gen district=district_15
gen ward=ward_15
keep ward_id_15 region ward district // keep variables needed

merge 1:1 region district ward using "table2" // merge based on multiple geographic variables from the largest to the smallest

rename _merge ward_type
label define ward_type 1 "parentless ward" 2 "childless ward" 3 "Both years" // label define
label values ward_type ward_type // label variable

erase table2.dta
save "Tz_ward", replace


 