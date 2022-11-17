*1
clear all
import excel "CIV_populationdensity", sheet("Population density") firstrow clear // import excel dataset
tempfile table1 // create an empty file
save "table1.dta", replace emptyok
use "CIV_Section_0"
decode b06_departemen,generate(NOMCIRCONSCRIPTION) // generate a new variable based on the label
replace NOMCIRCONSCRIPTION = upper(NOMCIRCONSCRIPTION) // change into upper characters
merge m:m NOMCIRCONSCRIPTION using "table1" // merge
drop if _merge == 2
drop _merge NOMCIRCONSCRIPTION
erase table1.dta
save "CIV_Section_0_1", replace

*2
clear all
use "GPS Data.dta"

*3
clear all
use Tz_elec_10_clean
keep ward_10
duplicates drop ward_10, force // drop duplicates 
gen ward = ward_10
tempfile table2 // create an empty file
save "table2.dta", replace emptyok

use Tz_elec_15_clean, clear
keep ward_15
duplicates drop ward_15, force // drop duplicates
gen ward = ward_15
merge 1:1 ward using "table2" // merge

keep ward _merge
rename _merge ward_type
label define ward_type 1 "parentless ward" 2 "childless ward" 3 "Both years" // label define
label values ward_type ward_type // label variable

erase table2.dta
save "Tz_ward", replace

 