********************************************************************************
* Econ 490: Assignment Week 10
* Benjamin Tu
********************************************************************************
clear 
********************************************************************************

*input directory
global import "/Users/benjamintu/Downloads/week_10/03_assignment/01_data"

*Question 1
*set global directory for excel and dta data
global density_data_excel "$import/CIV_populationdensity.xlsx"
global density_data_dta "$import/CIV_Section_0.dta"

*import dta file
use "$density_data_dta",clear
decode b06_departemen, gen (departement) // turn integer into string
replace departement = "arrah" if departement == "arrha" // correct typo
tempfile one //create a temporary file
save `one',replace

*import excel
import excel "$density_data_excel", sheet("Population density") firstrow clear

keep if regex(NOMCIRCONSCRIPTION, "DEPARTEMENT") // match and only keep the name where it contains "department"

*delete irrelevant information and only keep the name of the deparment
replace NOMCIRCONSCRIPTION =  subinstr(NOMCIRCONSCRIPTION,"DEPARTEMENT","",.)
replace NOMCIRCONSCRIPTION =  subinstr(NOMCIRCONSCRIPTION,"DE ","",.)
replace NOMCIRCONSCRIPTION =  subinstr(NOMCIRCONSCRIPTION,"D' ","",.)
replace NOMCIRCONSCRIPTION =  subinstr(NOMCIRCONSCRIPTION,"DU ","",.)
replace NOMCIRCONSCRIPTION = lower(strtrim(stritrim(NOMCIRCONSCRIPTION))) // take out space between words and make them lower case

rename NOMCIRCONSCRIPTION departement // change variable name

merge 1:m departement using `one' 

sort _merge // sort and determine which data has missing value

keep if _merge == 3 // only keep deparments that do not have missing values

drop _merge

*Question 2

global gps "$import/GPS Data.dta"


ssc install geonear // install package that will be used later
local enumerator_num = 19 //set the number of enumerator
clear
tempfile result
save `result',replace emptyok
use "$gps", clear

count
local enum_number = ceil(r(N)/`enumerator_num') // calculate the number of respondents per each enumerator and round it up. In this case, 111/19
local enum_gap = `enum_number' * `enumerator_num' - r(N) // since `number' is rounded up, the maximum allocated households might be greater than the actual households. In this case, 111/19 = 6 6*19=114. Hence, if each enumerator is assigned with 6 households, the maximum total number of households is greater than the actual households. Then, because of the 3 people gap, three enumerators need to take one less household. In other words, 16 enumerators will take 6 households, and the rest 3 will only take 5.
local new_enum = `enum_number' - `enum_gap' // calculate the number of enumerators who will be assigned with maximum households
gen id_new = id // generate new id for later package use
tempfile `one'
save `one',replace
foreach i of numlist 1/`enumerator_num'{ 
	preserve
		geonear id latitude longitude using `one', long neighbors (id_new latitude longitude) nearcount (`enum_number')// use geonear package to find 6 households that are close to each other
		keep in 1/`enumerator_num'
		gen enum_id = `i'
		keep id_new enum_id
		levelsof id_new, local(drop) // take the newly matched id and store it which will be dropped later
		append using `final'
		save `result',replace
	restore
	foreach x of local drop{
		drop if id == `x'
	}
	save `one', replace
		
}
use `result',clear
rename id_new id_new

*Question 3

*import data
global election_10 "$import/Tz_elec_10_clean.dta"
global election_15 "$import/Tz_elec_15_clean.dta"

use $election_10, clear // import 2010 election data

rename (region_10 district_10 ward_10) (region district ward) // change the name of the variable
tempfile one
save `one', replace

use $election_15, clear // import 2015 election data
rename (region_15 district_15 ward_15) (region district ward) // change 2015 variable name as well to match 2010 election data

merge 1:1 region district ward using `one' 

gen ward_type = _merge
label define ward_type 1 "parentless ward" 2 "childless ward" 3 "Both years" // define three conditions as outlined in the question
label values _merge ward_type // assign value to each label
drop ward_type
rename _merge ward_type






