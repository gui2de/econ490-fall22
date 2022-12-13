/********************************************************************************
Econ 490: Week 10 Assignment
Aaron Shtilerman
********************************************************************************/

global user "C:\Users\15162\Box"

/*
Q1: We have household survey data and population density data of Côte d'Ivoire. Merge departmente-level density data from the excel sheet (CIV_populationdensity.xlsx) into the household data (CIV_Section_O.dta) (Note: We did this during the class)
*/
global civ_density "$user/Econ490_Fall2022/week_10/02_data/CIV_populationdensity.xlsx"
global civ_section0 "$user/Econ490_Fall2022/week_10/02_data/CIV_Section_0.dta"

import excel "$civ_density", sheet("Population density") firstrow clear 		//"$civ_density" is 1
keep if regex(NOMCIRCONSCRIPTION,"DEPARTEMENT")									// We want only the rows correpsonding to departments
replace NOMCIRCONSCRIPTION=subinstr(NOMCIRCONSCRIPTION, "DEPARTEMENT DE","",.)
replace NOMCIRCONSCRIPTION=subinstr(NOMCIRCONSCRIPTION, "DEPARTEMENT D'","",.)
replace NOMCIRCONSCRIPTION=subinstr(NOMCIRCONSCRIPTION, "DEPARTEMENT DU","",.)
replace NOMCIRCONSCRIPTION=subinstr(NOMCIRCONSCRIPTION, "DEPARTEMENT D'","",.)	// Using regex commands to only get the department name

replace NOMCIRCONSCRIPTION=lower(strtrim(strtrim(NOMCIRCONSCRIPTION)))			// Trims space characters off of the string, and makes the entire string lowercase for consistency
rename NOMCIRCONSCRIPTION department											// Makes variable consistent for both files
replace department="arrha" if department=="arrah"								// Correcting typo in the density file
tempfile density																// Prepares a tempfile for merging
save `density'

use "$civ_section0", clear 														//"$civ_section0" is many (household data)
labelbook b06_departemen
decode b06_departemen, generate(department)
merge m:1 department using `density'


/*
Q2: We have the GPS coordinates for 111 households from a particular village. You are a field manager and your job is to assign these households to 19 enumerators (~6 surveys per enumerator per day) in such a way that each enumerator is assigned 6 households that are close to each other. Manually assigning them for each village will take you a lot of time. Your job is to write an algorithm that would auto assign each household (add a column and assign it a value 1-19 which can be used as enumerator ID). (Note: Your code should still work if I run it on data from another village.) 
*/
global gps "$user/Econ490_Fall2022\week_10\03_assignment\01_data\GPS Data.dta"

clear all
tempfile cluster
save `cluster', emptyok															// creates tempfile
cap prog drop setup																// drops previous programs names "setup"
prog define setup																// Define a function to cross data which will be used repeatedly
use "$gps", clear
keep id latitude longitude
rename (id latitude longitude) (id2 latitude2 longitude2)
count
tempfile gps
save `gps'
rename (id2 latitude2 longitude2) (id latitude longitude)
cross using `gps'																// use cross function to combine all combinations
count

geodist latitude2 longitude2 latitude longitude, generate (distance)			// Calculate distance from other points
sort id2
drop if id2>id																	// remove double counts, will keep the case where id2=id for counting
order id id2
end

setup
di "iteration 1"																// Begins first iteration to find enumerator id
sort latitude id id2
keep if id==id[1]																// Finds all crosses with id with smallest latitude
sort distance
keep if distance<=distance[6]													// Finds 6 closest distances to above id, including itself
forv j=1/6{
	mat ids1=(nullmat(ids1)\[id2[`j'],1])										// Stores the id in a matrix with the enumerator id
}
mat colnames ids1 = id2 eid				
clear
svmat ids1, names(col)
append using `cluster'
save `cluster', replace															// Saves and appends matrix results to tempfile

	
forv i=2/18{
	clear matrix
	setup
	di "iteration `i'"															// Begins i'th iteration to find enumerator id
	merge m:1 id2 using `cluster'												// merging data with tempfile
	gen fid=.
	replace fid=id2 if _merge==3
	sort fid
	by fid: gen dup = cond(_N==1,0,_n)											// makes a matrix of all the unique id values that are already assigned to an eid
	mkmat fid if dup==1, nomissing
	local x = rowsof(fid)
	forv k = 1/`x'{
		drop if id==fid[`k',1]
		drop if id2==fid[`k',1]													// drops all crosses containing at least one of the ids taken
	}
	drop if _merge==3
	drop _merge
	sort latitude id id2
	keep if id==id[1]
	sort distance
	keep if distance<=distance[6]
	forv j=1/6{
		mat ids`i'=(nullmat(ids`i')\[id2[`j'],`i'])
	}
	mat colnames ids`i' = id2 eid
	clear
	svmat ids`i', names(col)
	append using `cluster'
	save `cluster', replace	
}

clear matrix
setup
di "iteration 19"																// Begins 19th iteration to find enumerator id (fewer than 6 remaining)
merge m:1 id2 using `cluster'
gen fid=.
replace fid=id2 if _merge==3
sort fid
by fid: gen dup = cond(_N==1,0,_n)
mkmat fid if dup==1, nomissing
local x = rowsof(fid)
forv k = 1/`x'{
	drop if id==fid[`k',1]
	drop if id2==fid[`k',1]
}
drop if _merge==3
drop _merge
sort latitude id id2
keep if id==id[1]
sort distance
forv j=1/3{
	mat ids19=(nullmat(ids19)\[id2[`j'],19])
}
mat colnames ids19 = id2 eid
clear
svmat ids19, names(col)
append using `cluster'
save `cluster', replace	

use `cluster', clear
rename id2 id
merge 1:m id using "$gps"
pause on

twoway scatter latitude longitude, mlabel(eid)									//Not the most ideal, but good enough

/*
Q4.1: Between 2010 and 2015, the number of wards in Tanzania went from 3,333 to 3,944. This happened by dividing existing ward into 2 (or in some cases more) new wards. Create a final dataset that includes the following types of wards 1) wards that are both in 2010 and 2015 2) wards that are only in 2010 (i.e. "childless ward") 3) 2015 wards that do not have a corresponding 2010 ward (i.e. "parentless ward") Generate a categorical variable to describe these 3 types of wards. 
*/
pause on
global elec10 "$user\Econ490_Fall2022\week_10\03_assignment\01_data\Tz_elec_10_clean.dta"
global elec15 "$user\Econ490_Fall2022\week_10\03_assignment\01_data\Tz_elec_15_clean.dta"
global elec1015 "$user\Econ490_Fall2022\week_10\03_assignment\01_data\Tz_GIS_2015_2010_intersection.dta"


use "$elec1015", clear															//We intend to merge the 2010 and the 2015 data with this dataset separately, then append.
order ward_gis_2012 ward_gis_2017
codebook ward_gis_2012
rename ward_gis_2012 ward_10
rename ward_gis_2017 ward_15
keep ward_10 ward_15
sort ward_10

duplicates tag ward_10 ward_15, generate(duple)									//Removes duplicate wards
by ward_10: gen count=_n
drop if duple>=1 & count>=2
drop duple
reshape wide ward_15, i(ward_10) j(count)										//Reshapes from long to wide for easier merge
tempfile wardmergef
save `wardmergef', replace														// Saves to tempfile

use "$elec10", clear
keep ward_10
duplicates tag ward_10, generate(duple)											//Removes duplicate wards
sort ward_10
by ward_10: gen count=_n
drop if duple>=1 & count>=2
drop duple
drop count
merge m:1 ward_10 using `wardmergef'											// Merges with tempfile
drop _merge
reshape long ward_15, i(ward_10) j(j)											//Reshape back to long to append later
drop if missing(ward_15) & j!=1													//drops empty observations unless relevant
gen category=.
replace category=1 if ward_10==ward_15
replace category=2 if missing(ward_15)											// define category variable under specifications
exit
keep category ward_10
drop if missing(category)
rename ward_10 ward
tempfile wmerge10
save `wmerge10', replace														//Saves to tempfile to append later


use "$elec1015", clear
order ward_gis_2017 ward_gis_2012
codebook ward_gis_2012
rename ward_gis_2012 ward_10
rename ward_gis_2017 ward_15
keep ward_15 ward_10 
sort ward_15

duplicates tag ward_15 ward_10, generate(duple)									//Removes duplicate wards
by ward_15: gen count=_n
drop if duple>=1 & count>=2
drop duple
drop count
by ward_15: gen count=_n
reshape wide ward_10, i(ward_15) j(count)										//Reshapes from long to wide for easier merge
tempfile wardmerger
save `wardmerger', replace														// Saves to tempfile

use "$elec15", clear
keep ward_15
duplicates tag ward_15, generate(duple)											//Similar methodology as above
sort ward_15
by ward_15: gen count=_n
drop if duple>=1 & count>=2
drop duple
drop count
merge m:1 ward_15 using `wardmerger'
drop _merge
reshape long ward_10, i(ward_15) j(j)
drop if missing(ward_10) & j!=1
gen category=.
replace category=3 if missing(ward_10)
keep category ward_15
rename ward_15 ward
drop if missing(category)
append using `wmerge10'															//Appends previous tempfile to create a master list
sort ward
label define relation 1 "Consistent" 2 "Childless" 3 "Parentless"
label val category relation
tempfile masterlist
save `masterlist', replace

use `masterlist', clear


















