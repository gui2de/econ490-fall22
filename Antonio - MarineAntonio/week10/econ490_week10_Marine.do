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



* ----------------------------------- *
***** 
* Problem 4.

clear all

use "Tz_elec_10_clean", clear

rename *_10 *  // removing all of the _10 suffixes so we can merge later
drop total_candidates ward_total_votes // drop unnecessary variables
replace district = "manispaa ya kigoma ujiji" if district == "manispaa ya kigomaujiji" // correct typo

tempfile tanz10
save `tanz10', replace

use "Tz_elec_15_clean", clear

rename *_15 *  // like before, dropping all of the suffixes (_15)
drop total_candidates ward_total_votes // drop same vars again

* OBSERVATION: the 'ward' variable alone doesn't uniquely identify observations, so there must be multiple wards with the same name.
merge 1:1 region district ward using `tanz10' // After merging, it can be seen that there are many wards with the same name. The suspicious case is when these wards are in either the same region OR district, where one is parentless and the other is childless. This happens a lot.
* sort ward _merge

gen type = _merge // generate categorical variable describing "type of ward" in regard to presence in 2010 and/or 2015
drop _merge


duplicates tag ward, gen(dup) // to flag duplicate ward names

gen tag = 0 // tag = 1 indicates a suspicious observation.
* Later, we will use this tag to combine observations that didn't merge nicely due to being in a new region/district in 2015.

* sort ward region type
 
bysort ward region (type ward_id): replace tag = 1 if (type == 1 & type[_n+1] == 2) | (type == 2 & type[_n-1] == 1) // tagging observations where there are two wards from the same region with the same name, one parentless and one childless. 
* Important assumption: the boundaries of the regions of Tanzania did not change--besides by introducing entirely new regions--but the district boundaries might have, and there could be new districts.

* CONCERN #1: New regions were introduced between 2010 and 2015, and these haven't been tagged yet.

* CONCERN #2: If there are >=3 wards with the same name in the same region, where >=2 are parentless (childless) and at least 1 is childless (parentless), then we don't know for certain that we tagged the correct observation.
		* e.g., there could be 3 wards 'x1 x2 x3' in region 'y', where x1 and x2 are parentless and x3 is childless -- sorting by ward region type, we could tag x2 and x3 when really we want to tag x1 and x3.

//

* CONCERN #1: new regions

* by tabulating region by type, we can identify new regions. These are the ones that have exclusively type 1 observations (parentless)
tab region type // there are 4 new regions (not present in 2010 dataset, but present in 2015). These are Geita, Katavi, Njombe, and Simiyu.

gen newregion = .
replace newregion = 1 if region == "geita" | region == "katavi" | region == "njombe" | region == "simiyu" // create an indicator variable for being a new region. 
* This is relevant because two wards could have the same name but appear to be unique if they are in different regions--but if the region came into existence between 2010 and 2015, we could (likely?) be dealing with the same ward!

sort ward type region

bysort ward (type region ward_id): replace tag = 2 if type == 1 & type[_n+1] == 2 & newregion == 1 & tag[_n+1] == 0 // tag obs that are parentless, w/ next obs childless, + in a new region in 2015, AND where the next obs is NOT already tagged (since it has already been matched to another obs)

bysort ward (type region ward_id): replace tag = 2 if type == 2 & type[_n-1] == 1 & tag[_n-1] == 2 // tag childless obs, w/ prior obs parentless and in a new region (and tagged for it)


sort ward type region // to inspect data 

gen tag_samereg = .
bysort ward (region type): replace tag_samereg = 1 if (tag >= 1 & region[_n] == region[_n+1]) | (tag >= 1 & region[_n] == region[_n-1]) // this indicates that a pair of tagged wards are in the same region

gen tag_samedist = .
bysort ward (district type): replace tag_samedist = 1 if (tag >= 1 & district[_n] == district[_n+1]) | (tag >= 1 & district[_n] == district[_n-1]) // this indicates that a pair of tagged wards are in the same district

gen tag_uniqueregdist = .
replace tag_uniqueregdist = 1 if tag >= 1 & tag_samereg != 1 & tag_samedist != 1 // this would be an odd case where wards have been tagged as suspicious while only having ward name in common (not region or district)

drop tag_samereg tag_samedist // no longer need these indicators


* now we want to reveal whether there are any wards that are parentless (type==1), NOT in a new region (newregion!=1), but are tagged without sharing a region or district
		* Recall that newregion is defined by the region NOT existing in 2010. So, if we excluded type==1, we would get many more observations since the 2010 "childless" obs. would not be new regions, but correspond to an obs in a new reg)
		
tab ward if tag_uniqueregdist == 1 & newregion != 1 & type == 1 // no wards fit this criteria, which is good.

* Now we've dealt with concern 1.

//

*CONCERN #2: (tagging wrong ward when multiple parentless/childless)
	* obviously tag = 0 if dup = 0, so we only want to look at wards with non-unique names (duplicates)
	* additionally, we can ignore cases where dup = 1 (only two wards with same name), because there can't be multiple parentless (childless) wards and >=1 childless (parentless) ward if there are only two wards with that name.
	

sort dup ward region type tag // to inspect data 

* Now we'll create a complicated "tab if" statement to identify wards that
* (i) share a name with at least 2 other wards in the same region (dup>=2), (region[_n-1]==region[_n]==region[_n+1])
* (ii) are tagged
* (iii) share a type with the previous obs. (or next obs.?)

tab ward if dup >= 2 & (region[_n-1] == region[_n]) & (region[_n] == region[_n+1]) & (tag >= 1) & (type[_n] == type[_n-1] | type[_n] == type[_n+1]) & (ward[_n] == ward[_n-1]) // listing wards that (i) share a name with at least 2 other wards in the same region (ii) & are tagged

// the only ward of interest is Mgwashi
* three wards named "mgwashi" from the region "tanga" -- there are two parentless (2015) wards and one childless (2010) ward.
* According to "Tz_GIS_2015_2010_intersection.dta", the mgwashi ward in lushoto (district) became the mgwashi ward in bumbili (district) between 2010 and 2015. Thus, these should be the tagged cases.
		* note: the mgwashi ward in korogwe in 2015 corresponds to the 2010 ward dindira in korogwe.
replace tag = 1 if region == "tanga" & ward == "mgwashi" & district == "wilaya ya lushoto" 
replace tag = 1 if region == "tanga" & ward == "mgwashi" & district == "wilaya ya bumbuli" 
replace tag = 0 if region == "tanga" & ward == "mgwashi" & district == "wilaya ya korogwe"

* Now we have dealt with concern 2.


replace tag = 0 if type == 3 // if a ward was properly matched, nothing to worry about -- this makes 0 changes, which is a good sign.


* NEXT, WE HAVE TO USE OUR TAG TO CHANGE TYPES.
	* If we tagged an observation, it is because the merge labeled observations as parentless or childless when we really think it is the same ward, but in a different region and/or district.

* PLAN:
	* We cannot simply (replace type = 3 if tag >= 1), because then we would double-count these observations.
	* So, we have to find a way to get rid of one half of the observation pairs.
	* Then, we can change the type of the remaining tagged observations to 3 (present in both 2010 and 2015)

tab tag type // We can see that there are 519+331 = 850 type 1 tagged obs. and 850 type 2 tagged obs.
	* So, it is balanced! These observations are not actually parentless and childless.
	
	* This is great! We can drop all of the type 2 observations when tag > 0
	
drop if tag > 0 & type == 2 

* Now the remaining "parentless" observations can be converted to type == 3 (wards in both 2010 and 2015, i.e., "Always Present")

replace type = 3 if tag >= 1

* Now we can get rid of the variables we used to figure this all out.

drop dup tag newregion tag_uniqueregdist

sort ward_id

* Now we can create and apply a label that makes the meaning of the type variable more clear.

label var type "Ward Type" 
label define ward_type 3 "always present" 2 "childless" 1 "parentless", replace // to describe the meaning of the categorical variable type
label values type ward_type // actually applying our label to the appropriate variable

tab type, matcell(M) // to see how many wards there are of each type, with nice labels. the option matcell(M) creates a matrix of the results.

display M[3,1] + M[1,1] // always present + parentless = 3944 -- this is the exact number of wards in Tanzania in 2015!

display M[3,1] + M[2,1] // always present + childless = 3333 -- the exact number of wards in Tanzania in 2010.