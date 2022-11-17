***
***
* Econ 490: Week 10 Stata assignment
* Antonio Marine
* due November 13, 2022
***
***

clear all

global user "C:/Users/anton/Box" // ** CHANGE THIS LINE 
cd "$user/Econ490_Fall2022/week_10/03_assignment/01_data"

* ----------------------------------- *
*****
* Problem 1. 

clear

import excel "CIV_populationdensity.xlsx", firstrow clear // import the relevant excel sheet (department-level density data). the first row has variable names

keep if regex(NOMCIRCONSCRIPTION, "DEPARTEMENT") // only keeping observations that have "DEPARTEMENT" in the NONCIRCONSCRIPTION column to isolate department-level data

replace NOMCIRCONSCRIPTION =  subinstr(NOMCIRCONSCRIPTION,"DEPARTEMENT ","",.) // remove "DEPARTEMENT " from all of the observations

replace NOMCIRCONSCRIPTION =  subinstr(NOMCIRCONSCRIPTION,"DE ","",.)
replace NOMCIRCONSCRIPTION =  subinstr(NOMCIRCONSCRIPTION,"D' ","",.)
replace NOMCIRCONSCRIPTION =  subinstr(NOMCIRCONSCRIPTION,"DU ","",.)
replace NOMCIRCONSCRIPTION =  subinstr(NOMCIRCONSCRIPTION,"D'","",.)
 
replace NOMCIRCONSCRIPTION = lower(strtrim(stritrim(NOMCIRCONSCRIPTION))) // lower-case letters


tempfile density
save `density'

use "CIV_Section_0.dta", clear
* use "$user/Econ490_Fall2022/week_10/02_data/CIV_Section_0.dta", clear // load the Stata dataset with household data

decode b06_departemen, gen("NOMCIRCONSCRIPTION") // change department variable from numeric to string and change name so it matches our other dataset. Now our two datasets will have a common variable that we can use to merge by

* While working on this, I noticed a typo in the data set after merging. The region Arrah is misspelled "arrha", so we will correct it before merging.

replace NOMCIRCONSCRIPTION = "arrah" if NOMCIRCONSCRIPTION == "arrha"

merge m:1 NOMCIRCONSCRIPTION using `density'

sort _merge
* Now that we've corrected the typo, only gbeleban is unassociated with anything from the CIV_Section_0.dta set (_merge!=3). We can drop this case.
drop if _merge!=3 
drop _merge // no longer need the _merge variable

* Now I want to do some final cleaning:
rename NOMCIRCONSCRIPTION department 
sort department

* ---------------------------------- *
***** 
* Problem 2.
// THIS PROBLEM USES TWO PACKAGES "geodist" AND "sepscatter"

* these two lines install the packages
ssc inst geodist  // to calculate geographical distances
ssc inst sepscatter  // to quickly produce a scatter plot that displays points differently based on a third variable

clear all

save enumerator_assignment, replace emptyok

use "GPS Data.dta", clear // load in data set

* We want this code to work for many situations, including for different numbers of enumerators and the number of households assigned to each numerator.
local n_enumerators = 19 // we have 19 enumerators in this scenario. Change this number to the number of enumerators available.
* local hh_per_enum = ceil(_N/`n_enumerators')
gen hh_per_enum = ceil(_N/`n_enumerators') // This takes the total number of households (_N), divides it by the number of available enumerators (n_enumerators), and rounds up to determine how many households should be assigned to each enumerator.

* scatter latitude longitude, name(lat_long) // to view dispersement of points (like a map)

* I know the cross command forms every pairwise combination of two datasets! I can use this to calculate the distance between every two locations.

rename (id latitude longitude age female) (id_x lat_x long_x age_x female_x) // renaming variables to get different column names so we can cross

sort long_x lat_x id_x

cross using "GPS Data.dta"

geodist lat_x long_x latitude longitude, gen(distance)

gen enumerator_id = . // create new enumerator id variable
gen delete = . // create a variable delete that will later be used to remove observations. This will prevent us from assigning multiple enumerators to the same household

forv i = 1/`n_enumerators' {
	sort long_x id_x distance
	replace enumerator_id = `i' if _n <= hh_per_enum 
	preserve
	drop if enumerator_id != `i'
	drop lat_x long_x id_x age_x female_x delete // only original vars remain. note: can drop all five quicker another way...
	tempfile enum`i'
	save `enum`i'', replace
	append using enumerator_assignment
	save enumerator_assignment, replace
	restore
	bysort id (enumerator_id): replace enumerator_id = `i' if enumerator_id[1] == `i'
	bysort id_x (enumerator_id): replace delete = 1 if id_x == id & enumerator_id == `i'
	bysort id_x (delete): replace delete = 1 if delete[1] == 1
	replace delete = 1 if enumerator_id == `i'
	drop if delete == 1
}

use "enumerator_assignment.dta", clear // load in the data set we've created

* now we'll clean it by dropping some unnecessary variables
drop distance
drop hh_per_enum

sort enumerator_id id
* ISSUE: have too many households. In this case, the last 3 observations are duplicates of the prior 3 since 111/6 = 18 remainder 3
duplicates drop

sepscatter latitude longitude, separate(enumerator_id) // this plot depicts the coordinates of each household, with different shapes/colors based on the enumerator assigned to the house. It looks like enumerators never have to travel very far, and all of the households they're assigned to are rather clustered together!

* The map is nice, but we also want to quantify this.
* I got this idea from Abby's code.
bysort enumerator_id (longitude latitude): gen next_latitude = latitude[_n+1]
bysort enumerator_id (longitude latitude): gen next_longitude = longitude[_n+1]
geodist latitude longitude next_latitude next_longitude, gen(trip_distance) // This is approximately the distance the enumerator must travel to get to the next household

bysort enumerator_id: egen total_distance = total(trip_distance) // measuring total distance traveled by each enumerator

tab total_distance // all but 1 enumerator have to travel less than 1 km
summarize total_distance // on average, enumerators travel .563 kilometers -- this should be a nice and easy walk



***** 
* Problem 4.

clear all