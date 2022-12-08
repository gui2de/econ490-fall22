********************************************************************************
* Econ 490: Week 10
* Geena Panzitta
* November 15, 2022
********************************************************************************

{
	
set more off
clear all

*Change username here
global username "/Users/geenapanzitta/Library/CloudStorage/Box-Box/"

cd "${username}Econ490_Fall2022/week_10/03_assignment"

global civ_density "01_data/CIV_populationdensity.xlsx"
global civ_section0 "01_data/CIV_Section_0.dta"

global gps_data "01_data/GPS Data.dta"

global tz_elec_15_clean "01_data/Tz_elec_15_clean.dta"
global tz_elec_10_clean "01_data/Tz_elec_10_clean.dta"

}

/*******************************************************************************
Q1
*******************************************************************************/

{

clear
import excel "${civ_density}", sheet("Population density") firstrow //import excel file
keep if substr(NOMCIRCONSCRIPTION,1,11) == "DEPARTEMENT" //keep only departement level entries

replace NOMCIRCONSCRIPTION = substr(NOMCIRCONSCRIPTION,16,.) if substr(NOMCIRCONSCRIPTION,1,15) == "DEPARTEMENT DE " | substr(NOMCIRCONSCRIPTION,1,15) == "DEPARTEMENT D' " | substr(NOMCIRCONSCRIPTION,1,15) == "DEPARTEMENT DU " //take out the beginning of the string

replace NOMCIRCONSCRIPTION = substr(NOMCIRCONSCRIPTION,15,.) if substr(NOMCIRCONSCRIPTION,1,14) == "DEPARTEMENT D'" //take out the beginning of the string

replace NOMCIRCONSCRIPTION = strlower(NOMCIRCONSCRIPTION) //make string lowercase to match merge format
rename NOMCIRCONSCRIPTION department //rename variable to match other data
replace department = "arrha" if department == "arrah" //fix spelling inconsistency

tempfile density //save data to tempfile
save `density'	

clear
use "${civ_section0}" //load data
decode b06_departemen, generate(department) //decode to make string variable

merge m:1 department using `density' //merge with density data

}

/*******************************************************************************
Q2
*******************************************************************************/

{

clear

tempfile assignments //generate tempfile for enumerator assignments
save `assignments', emptyok

use "${gps_data}" //import gps data
egen h_total = count(id) //count number of households
local hn = h_total //save number of households as local
drop h_total
rename (id latitude longitude)(id1 lat1 long1)

tempfile gps //save data as tempfile
save `gps'

rename (id1 lat1 long1) (id2 lat2 long2) //rename key variables

cross using `gps' //now we have 111*111 observations
drop if id1 == id2 //get rid of obs with the same ids, drops the total to 12210, P(111,2)
egen p1 = concat(id1 id2) //get rid of extra permutations
egen p2 = concat(id2 id1)
replace p2 = p1 if id1 > id2 //p2 is now the same for all/both permutations of the same ids
by p2, sort: generate i = _n
keep if i==1 //keeps only one permutation, drops the total to 6105, C(111,2)
drop p1 p2 i
geodist lat1 long1 lat2 long2 , generate(dist) //calculate distance between each household

gen lat = .
gen lat_num = .
replace lat = lat1 if lat1 <= lat2 //make lat the smaller of the two latitudes
replace lat_num = 1 if lat1 <= lat2 //note whether smaller lat is first or second household
replace lat = lat2 if lat2 < lat1
replace lat_num = 2 if lat2 < lat1
gen id_origin = . //generate empty/zero variables
gen enum_1 = 0
gen enum_2 = 0
gen assigned = 0
gen num = .
gen num_id = .
gen j1 = .
gen j2 = .
gen min_j_num = .

*set number of enumerators
local en = 19
local e1 = trunc(`hn'/`en') //save number of households per enumerator (lower)
local e1_1 = `e1'-1
local e2 = `e1'+1 //save number of households per enumerator (upper)
local e2_1 = `e2'-1
if `e1' == `hn'/`en' {
	local e2 = 0
}

local en2 = `hn' - `en'*`e1' //save number of enumerators with upper bound
local en1 = `en'-`en2' //save number of enumerators with lower bound

forv i = 1/`en' { //loop through each enumerator

	sort assigned lat //sort so that unassigned households are first, then smallest to largest latitude
	generate j = _n //find the smallest latitude household, picking only one when there are ties
	replace j1 = j if lat_num == 1
	replace j2 = j if lat_num == 2
	egen min_j1 = min(j1)
	egen min_j2 = min(j2)
	replace min_j_num = 1 if min_j1 < min_j2 //note which of the two households the smallest latitude is
	replace min_j_num = 2 if min_j2 < min_j1

	replace id_origin = id1 if j == 1 & min_j_num == 1 //set the minimum lat house as the origin house
	replace id_origin = id2 if j == 1 & min_j_num == 2

	sort id_origin //make nonempty id_origin house first
	local id_origin_l = id_origin[1] //save id_origin as local

	replace id_origin = `id_origin_l' if (id1 == `id_origin_l'|id2 == `id_origin_l') & assigned == 0 //save all household pairs with the minimum lat house as having the origin house

	replace enum_1 = `i' if id_origin == id1 & assigned == 0 //set enumerator for the origin house
	replace enum_2 = `i' if id_origin == id2 & assigned == 0

	sort id_origin assigned dist //put all household pairs that include the origin house first, the unassigned houses first within that, and sort by distance within that

	forv j = 1/`e1_1' { //run through upper bound number of households - 1 (since origin house is the first)
		replace enum_1 = `i' if _n == `j' & id_origin == id2 & assigned == 0 & `i' <= (`en'-`en2') //set enumerator for the first `e1_1' closest houses
		replace num = 1 if _n == `j' & id_origin == id2 & assigned == 0 & `i' <= (`en'-`en2') //save a variable as nonzero
		replace num_id = id1 if _n == `j' & id_origin == id2 & assigned == 0 & `i' <= (`en'-`en2') //save the id of the house that is not the origin house
		
		replace enum_2 = `i' if _n == `j' & id_origin == id1 & assigned == 0 & `i' <= (`en'-`en2')
		replace num = 1 if _n == `j' & id_origin == id1 & assigned == 0 & `i' <= (`en'-`en2')
		replace num_id = id2 if _n == `j' & id_origin == id1 & assigned == 0 & `i' <= (`en'-`en2')
	}

	sort num //sort so that the first `e1_1' houses that match the requirements are listed first
	forv j = 1/`e1_1' { //save locals of the ids of each house
		local origin_`j' = num_id[`j'] 
	}

	forv j = 1/`e1_1' { //set the enumerator for the chosen houses, even when they aren't paired with the origin house
		replace enum_1 = `i' if id1 == `origin_`j'' & `i' <= (`en'-`en2')
		replace enum_2 = `i' if id2 == `origin_`j'' & `i' <= (`en'-`en2')
	}

	if `e2' > 0 { //repeat for the lower bound
		forv j = 1/`e2_1' {
			replace enum_1 = `i' if _n == `j' & id_origin == id2 & assigned == 0 & `i' > (`en'-`en2')
			replace num = 1 if _n == `j' & id_origin == id2 & assigned == 0 & `i' > (`en'-`en2')
			replace num_id = id1 if _n == `j' & id_origin == id2 & assigned == 0 & `i' > (`en'-`en2')
			replace assigned = 1 if _n == `j' & id_origin == id2 & assigned == 0 & `i' > (`en'-`en2')
			replace enum_2 = `i' if _n == `j' & id_origin == id1 & assigned == 0 & `i' > (`en'-`en2')
			replace num = 1 if _n == `j' & id_origin == id1 & assigned == 0 & `i' > (`en'-`en2')
			replace num_id = id2 if _n == `j' & id_origin == id1 & assigned == 0 & `i' > (`en'-`en2')
			replace assigned = 1 if _n == `j' & id_origin == id1 & assigned == 0 & `i' > (`en'-`en2')
		}
	}

	sort num
	count
	forv j = 1/`e2_1' {
		local origin_`j' = num_id[`j']
	}

	forv j = 1/`e2_1' {
		replace enum_1 = `i' if id1 == `origin_`j'' & `i' > (`en'-`en2')
		replace enum_2 = `i' if id2 == `origin_`j'' & `i' > (`en'-`en2')
		
	}

	replace assigned = 1 if enum_1 != 0 | enum_2 != 0 //mark households with enumerators as assigned

	replace id_origin = . //reset the empty variables
	replace lat = . if assigned == 1 //mark lat as empty for assigned houses
	replace num = .
	replace num_id = .
	drop j
	replace j1 = .
	replace j2 = .
	replace min_j_num = .
	drop min_j1 min_j2

}

preserve
drop if enum_1 == 0 | enum_2 == 0 //drop pairs that have a missing enumerator
collapse enum_1, by(id1) //keep 1 obs for each household
rename (id1 enum_1)(id enum) //rename to match original data
save `assignments', replace //save the tempfile
restore

drop if enum_1 == 0 | enum_2 == 0 //same as above
collapse enum_2, by(id2)
rename (id2 enum_2)(id enum)
append using `assignments' //add to enum_1 assignments
collapse enum, by(id) //keep 1 obs for each household
save `assignments', replace //save as tempfile

clear
use "${gps_data}" //load original data
merge 1:1 id using `assignments' //merge in enumerator assignment
sort enum //sort by enumerator
tab enum //show how many households are assigned to each enum

//ssc inst sepscatter
sepscatter longitude latitude, sep(enum) //create scatter plot by enumerator

/* creates the scatter plot without sepscatter
twoway (scatter longitude latitude if enum == 1, m(circle) mc(blue) legend(label(1 "Enumerator 1") label(2 "Enumerator 2") label(3 "Enumerator 3") label(4 "Enumerator 4") label(5 "Enumerator 5") label(6 "Enumerator 6") label(7 "Enumerator 7") label(8 "Enumerator 8") label(9 "Enumerator 9") label(10 "Enumerator 10") label(11 "Enumerator 11") label(12 "Enumerator 12") label(13 "Enumerator 13") label(14 "Enumerator 14") label(15 "Enumerator 15") label(16 "Enumerator 16") label(17 "Enumerator 17") label(18 "Enumerator 18") label(19 "Enumerator 19"))) (scatter longitude latitude if enum == 2, m(circle) mc(red)) (scatter longitude latitude if enum == 3, m(circle) mc(orange)) (scatter longitude latitude if enum == 4, m(circle) mc(pink)) (scatter longitude latitude if enum == 5, m(circle) mc(gray)) (scatter longitude latitude if enum == 6, m(circle) mc(cyan)) (scatter longitude latitude if enum == 7, m(circle) mc(green)) (scatter longitude latitude if enum == 8, m(circle) mc(brown)) (scatter longitude latitude if enum == 9, m(circle) mc(purple)) (scatter longitude latitude if enum == 10, m(circle) mc(black)) (scatter longitude latitude if enum == 11, m(circle) mc(lavender)) (scatter longitude latitude if enum == 12, m(circle) mc(lime)) (scatter longitude latitude if enum == 13, m(circle) mc(yellow)) (scatter longitude latitude if enum == 14, m(circle) mc(teal)) (scatter longitude latitude if enum == 15, m(circle) mc(maroon)) (scatter longitude latitude if enum == 16, m(circle) mc(mint)) (scatter longitude latitude if enum == 17, m(circle) mc(khaki)) (scatter longitude latitude if enum == 18, m(circle) mc(magenta)) (scatter longitude latitude if enum == 19, m(circle) mc(olive))
*/

}


/*******************************************************************************
Q4
*******************************************************************************/

{

clear
use "${tz_elec_10_clean}" //import 2010 data
rename ward_10 ward //rename variable to match
sort ward
by ward, sort: generate i = _n
drop if i != 1 //keep only one obs for each ward
tempfile tz_10 //save as tempfile
save `tz_10', emptyok

clear
use "${tz_elec_15_clean}" //import 2015 data
rename ward_15 ward //rename variable to match
sort ward
by ward, sort: generate i = _n
drop if i != 1 //keep only one obs for each ward
merge 1:1 ward using `tz_10' //merge with 2010 data

gen ward_type = . //generate ward_type based on merge status
replace ward_type = 1 if _merge == 3
replace ward_type = 2 if _merge == 1
replace ward_type = 3 if _merge == 2

label define wtype 1 "In both 2010 and 2015" 2 "Only in 2010" 3 "Only in 2015" //ad value labels to ward_type
label values ward_type wtype

drop _merge //drop _merge variable

}

/*******************************************************************************
END
*******************************************************************************/
