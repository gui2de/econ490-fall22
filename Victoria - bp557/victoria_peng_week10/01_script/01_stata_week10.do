********************************************************************************
* Econ 490: Week 10
* Handling datasets in Stata
* Ali Hamza
* Nov 8th, 2022
********************************************************************************
clear 
set seed 1
set more off
********************************************************************************



global user "C:/Users/ah1152/Box"

global psle  "$Users/victoriapeng/Desktop/490 Research Field/Week10/02_data/psle_student_raw.dta"
global psle_do "$/Users/victoriapeng/Desktop/490 Research Field/Week10/01_script/00_subroutines/01_studentcleaning.do"

global grant "Users/victoriapeng/Desktop/490 Research Field/Week10/02_data/grant_prop_review_2022.dta"

global tz_elec_15_raw "$Users/victoriapeng/Desktop/490 Research Field/Week10/02_data/Tanzania_election_2015_raw.dta"
global tz_elec_15_clean "$Users/victoriapeng/Desktop/490 Research Field/Week10/02_data/Tz_elec_15_clean.dta"
global tz_elec_10_clean "$Users/victoriapeng/Desktop/490 Research Field/Week10/02_data/Tz_elec_10_clean.dta"
global tz_15_10_gis "$Users/victoriapeng/Desktop/490 Research Field/Week10/02_data/Tz_GIS_2015_2010_intersection.dta"

global store_location "$Users/victoriapeng/Desktop/490 Research Field/Week10/02_data/store_location_bufferzone.dta"

global kenya_baseline "$Users/victoriapeng/Desktop/490 Research Field/Week10/02_data/kenya_education_baseline.dta"
global kenya_endline  "$Users/victoriapeng/Desktop/490 Research Field/Week10/02_data/kenya_education_endline.dta"

global civ_density "$Users/victoriapeng/Desktop/490 Research Field/Week10/02_data/CIV_populationdensity.xlsx"
global civ_section0 "$Users/victoriapeng/Desktop/490 Research Field/Week10/02_data/CIV_Section_0.dta"





/********************************************************************************
*Stata Cheat Sheets
********************************************************************************

https://www.stata.com/bookstore/statacheatsheets.pdf


********************************************************************************/


********************************************************************************
*Append/reshape
********************************************************************************

*Example from week 4 Assignent


clear 
tempfile rev
save `rev', emptyok


*reviewer 1
	use "$grant", clear
	keep proposal_id Rewiewer1 Review1Score
	rename Rewiewer1 reviewer 
	rename Review1Score score
	
	append using `rev'
	save `rev', replace

*reviewer 2
	use "$grant", clear
	keep proposal_id Reviewer2 Reviewer2Score
	rename Reviewer2 reviewer 
	rename Reviewer2Score score
	
	append using `rev'
	save `rev', replace	
	
*reviewer 2
	use "$grant", clear
	keep proposal_id Reviewer3 Reviewer3Score
	rename Reviewer3 reviewer 
	rename Reviewer3Score score
	
	append using `rev'
	save `rev', replace	

use `rev', clear 	



*Example Grant
use "$grant", clear
*in class demo
 

*Example PSLE
use "$psle", clear 
*in class demo



********************************************************************************
*Merge
********************************************************************************

*Merge 1:1 example Baseline/endline

use "$kenya_baseline",clear
merge 1:1 pseudo_idvar using "$kenya_endline"


use "$kenya_endline",clear
merge 1:1 pseudo_idvar using "$kenya_baseline"

*Is this the same?
 
*Example: CIV 
*in class demo
import excel "$civ_density", sheet("Population density") firstrow clear
	
use "$civ_section0", clear 


********************************************************************************
*Fillin
********************************************************************************
webuse fillin1, clear
list
fillin sex race age_group
list

*example Tanzania 2015 election
use "$tz_elec_15_raw", clear
*in class demo

********************************************************************************
*Joinby Vs Cross
********************************************************************************

*Difference between Joinby and Cross

clear

// CREATE "MASTER" DATA SET
set obs 6
gen int id = ceil(_n/3)
gen x = round(runiform()*10,1)
list, clean
tempfile master
save `master'

// CREATE "USING" DATA SET
clear
set obs 6
gen int id = ceil(_n/3)
gen y = round(runiform()*10,1)
list, clean
tempfile using
save `using'

use `master', clear
joinby id using `using'
count
assert `r(N)' == 18
list, clean

use `master', clear
rename id id_master
cross using `using'
count
assert `r(N)' == 36
list, clean


*example: Buffer Zone Calculations
use "$store_location", clear
*in class demo

********************************************************************************
*Reclink2 (assignment)
********************************************************************************

use "$tz_elec_10_clean", clear

use "$tz_15_10_gis", clear 

keep region_gis_2017 district_gis_2017 ward_gis_2017
duplicates drop 
rename (region_gis_2017 district_gis_2017 ward_gis_2017) (region district ward)
sort region district ward
gen dist_id = _n

tempfile gis_15
save `gis_15'


use "$tz_elec_15_clean", clear 
keep region_15 district_15 ward_15
duplicates drop
rename (region_15 district_15 ward_15) (region district ward)
sort region district ward
gen idvar = _n


reclink2 region district ward using `gis_15', idmaster(idvar) idusing(dist_id) gen(score) 
 