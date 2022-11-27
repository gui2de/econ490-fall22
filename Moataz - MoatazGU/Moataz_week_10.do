**Econ 490
*Assignment Week 10 
*Almoataz Shikhy
**********************
*Q1//Household Survey Côte d'Ivoire  

global user "C:/Users/Moataz/Box"
global civ_population"$user/Econ490_Fall2022/week_10/03_assignment/01_data/CIV_populationdensity.xlsx"
global hhsurvey "$user/Econ490_Fall2022/week_10/03_assignment/01_data/CIV_Section_0.dta"

*** import excel data CIV_populationdensity
import excel "$civ_population", firstrow clear

*keep department 
keep if regex(NOMCIRCONSCRIPTION, "DEPARTEMENT")

*cleaning data 
replace NOMCIRCONSCRIPTION =  subinstr(NOMCIRCONSCRIPTION,"DEPARTEMENT","",.)
replace NOMCIRCONSCRIPTION =  subinstr(NOMCIRCONSCRIPTION,"DE ","",.)
replace NOMCIRCONSCRIPTION =  subinstr(NOMCIRCONSCRIPTION,"D' ","",.)
replace NOMCIRCONSCRIPTION =  subinstr(NOMCIRCONSCRIPTION,"DU ","",.)

*change words to lowercase
replace NOMCIRCONSCRIPTION = lower(strtrim(stritrim(NOMCIRCONSCRIPTION)))
rename NOMCIRCONSCRIPTION departement
*create temporaryfile 
tempfile dinsity
save `dinsity', replace 	

clear
use "$hhsurvey", clear
decode b06_departemen, generate (departement)
merge m:1 departement using `dinsity'

*****************************
*GPS Coordinates
*Q2 
global user "C:/Users/Moataz/Box"
global gps "$user/Econ490_Fall2022/week_10/03_assignment/01_data/GPS Data.dta"

local enum = 19		// Number of enumerators as given in the question.
clear
tempfile final_data					// create temporary file
save `final_data', replace emptyok	// save temporary file as blank document
use "$gps", clear
	count							// To obtain number of observations
	local num = ceil(r(N)/`enum') 	// Rounding up number of households per enumerator, in our case we have 111 HH with 19 enumerators. the last enumerator will interview onyly 3
	local gap = `enum'*`num' - r(N)	// Identifying the gap between number of respondents and maximum number of respondents which equal 3 
	local enum2 = `enum' - `gap'	// Calculating number of enumerators that will get maximum respondent, the rest will have 1 less (equal 16)
	gen id2 = id					// creating another id for "geonear"
	tempfile gnear					// temporary file for "geonear"
	save `gnear', replace
	foreach x of numlist 1/`enum' {
			preserve
				geonear id latitude longitude using `gnear', long neighbors(id2 latitude longitude) nearcount(`num')
				keep in 1/`num'
				gen enum_id = `x'
				keep id2 enum_id
				levelsof id2, local(drop) //storing the unique values and drop the rest in the loop 
				append using `final_data'
				save `final_data', replace
			restore
			foreach y of local drop {
				drop if id == `y'
			}
			save `gnear', replace
			if `x' == `enum2' local num = `num' - 1 //we have 19 enumerators, when x is 16 the enumerators from 17 to 19 will interview only 5 insteade of 6.
	}
	
use `final_data', clear
rename id2 id
merge 1:1 id using "$gps"
	drop _m

order enum_id
sort enum_id id
sepscatter longitude latitude, sep(enum_id) legend(row(2)) //create scatter plot by enumerator

********************************
*Q4 Tanzania Election 2015 / 2010
global user "C:/Users/Moataz/Box"
global tz_election_10 "$user/Econ490_Fall2022/week_10/03_assignment/01_data/Tz_elec_10_clean.dta"
global tz_election_15 "$user/$user/Econ490_Fall2022/week_10/03_assignment/01_data/Tz_elec_15_clean.dta"

use "$tz_election_10", clear
keep region_10 district_10 ward_10
rename (region_10 district_10 ward_10) (region district ward)
duplicates drop
sort region district ward
tempfile tz_10
save `tz_elec',replace 

use "$tz_election_15", clear
keep region_15 district_15 ward_15
rename (region_15 district_15 ward_15)(region district ward)
merge 1:1 region district ward using `tz_elec'
gen wards= _merge
drop _merge
sort wards
label var wards "ward"
label def wards 1"parentless" 2 "childless" 3 "full_ward"








