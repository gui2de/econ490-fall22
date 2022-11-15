********************************************************************************
********************************************************************************
* Econ 490: Week 10
* Assignent
* Felipe Germanos de Castro
* Nov 14th, 2022
********************************************************************************
********************************************************************************


********************************************************************************
********************************   Set Up   ************************************
********************************************************************************

clear 
set seed 1
set more off

/* Here, we set a few useful global paths for later. Don't forget to change the
first macro!! */

global user "/Users/felipe.germanos/Library/CloudStorage/Box-Box"
global dir "$user/Econ490_Fall2022/week_10"


global civ_density "$user/Econ490_Fall2022/week_10/02_data/CIV_populationdensity.xlsx"
global civ_section0 "$user/Econ490_Fall2022/week_10/02_data/CIV_Section_0.dta"


global gps_data "$user/Econ490_Fall2022/week_10/03_assignment/01_data/GPS Data.dta"


global tz_elec_15_clean "$user/Econ490_Fall2022/week_10/02_data/Tz_elec_15_clean.dta"
global tz_elec_10_clean "$user/Econ490_Fall2022/week_10/02_data/Tz_elec_10_clean.dta"
global tz_15_10_gis "$user/Econ490_Fall2022/week_10/02_data/Tz_GIS_2015_2010_intersection.dta"



cd "$dir"

********************************************************************************
******************************   Question 1   **********************************
********************************************************************************

/* Just a slightly more complete version than the code we used in class */



import excel "$civ_density", sheet("Population density") firstrow clear

/* First, we drop all rows that don't contain department level data and
 clean the department names */

keep if regex(NOMCIRCONSCRIPTION, "DEPARTEMENT")

replace NOMCIRCONSCRIPTION = subinstr(NOMCIRCONSCRIPTION, "DEPARTEMENT", "",.)
replace NOMCIRCONSCRIPTION = subinstr(NOMCIRCONSCRIPTION, " DE ", "",.)
replace NOMCIRCONSCRIPTION = subinstr(NOMCIRCONSCRIPTION, " DU ", "",.)
replace NOMCIRCONSCRIPTION = subinstr(NOMCIRCONSCRIPTION, " DES ", "",.)
replace NOMCIRCONSCRIPTION =  subinstr(NOMCIRCONSCRIPTION,"D' ","",.)
replace NOMCIRCONSCRIPTION = subinstr(NOMCIRCONSCRIPTION, " D'", "",.)


replace NOMCIRCONSCRIPTION = lower(strtrim(strtrim(NOMCIRCONSCRIPTION)))
gen department = NOMCIRCONSCRIPTION
drop NOMCIRCONSCRIPTION

/* Looking at the data, it is possible to find one typo in the department names */
replace department="arrha" if department=="arrah"


/* Finally, we save the temporary file*/
tempfile density
save `density'


/* Here is the code we use to merge the datasets on "department" */
use "$civ_section0", clear 
decode b06_departemen, generate(department)
merge m:1 department using `density'


/* Finally, we drop empty rows (case when merge ==2) */
drop if _merge==2 
drop _merge


/* And this exports the dataset */
save question_1, replace





********************************************************************************
******************************   Question 2   **********************************
********************************************************************************

/* We also covered most of this algorythm in class - ordering latitude and longitude
and choosing appropriate clusters following such ordering. Notice that we need to 
use a package, geodist, to run this code, so there might be an error because of it */


use "$gps_data", clear


/* We start by generating a scatterplot to check for clusters of observations */
sort latitude longitude
scatter longitude latitude, title("Q2 - Clusters by latitude and longitude")

/* Next, we divide the data, which is sorted, in blocks of six, to reflect
the fact that each field worker is assigned to 6 households, and use geodist to 
check how efficient our ordering was. Notice nothing in the code is specific to 
this dataset, so it should be generalizible */
egen field_worker = seq(), block(6) 
bysort field_worker (longitude latitude): gen lat_shifted = latitude[_n+1]
bysort field_worker (longitude latitude): gen longit_shifted = longitude[_n+1] 
geodist latitude longitude lat_shifted longit_shifted, generate(distance)

/* Finally, we can try to measure how well we did by summing the total distance
travelled */

bysort field_worker: egen distance_travelled = total(distance)  
sum distance_travelled 


tabulate distance_travelled // all enumerators are walking under 2 miles
summarize distance_travelled // enumerators are walking under 1 mile on average


/* And this exports the dataset */
save question_2, replace





********************************************************************************
******************************   Question 4   **********************************
********************************************************************************



use "$tz_elec_10_clean", clear

/* Data cleaning to ensure smoother merge */
rename (region_10 district_10 ward_10) (region district ward)
drop total_can ward_tot

/* And we are ready to save the temporary file*/
tempfile old_ward
save `old_ward', replace


/* Here is the code we use to merge the datasets on "district." Notice, we also
have to perform some analogous cleaning work */
use "$tz_elec_15_clean", clear
rename (region_15 district_15 ward_15) (region district ward)
drop total_can ward_tot
merge 1:1 region district ward using `old_ward' 

/* Final cleaning */

gen ward_final = _merge
drop _merge

sort ward_final
label var ward_final "Ward"
label def ward_final 1 "parentless" 2 "childless" 3 "full"

tabulate ward_final


/* Exporting results */
save question_3, replace





********************************************************************************
***********************************  End  **************************************
********************************************************************************








