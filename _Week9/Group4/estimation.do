********************************************************************************
* ECON 491
* Final Project - Power Calculations, Estimation
* Group 4
* December 6, 2022
********************************************************************************

cap prog drop projectdata_sim

prog define projectdata_sim, rclass

clear

********************************************************************************
* setting up inputs
********************************************************************************

{
	
syntax anything
local bias: word 1 of `anything' //a dummy for whether the results are biased or not
local cluster_size: word 2 of `anything' //inputting cluster size
local number_of_schools: word 3 of `anything' //inputting number of schools
local te: word 4 of `anything' //inputting treatment effect
local compliance: word 5 of `anything' //inputting compliance rate
local attrition: word 6 of `anything' //inputting attrition rate
local active_and_passive: word 7 of `anything' //inputting whether it has active and passive controls

}

********************************************************************************
* data generating process
********************************************************************************

{

clear
set obs `number_of_schools' //setting number of schools based on input
generate school_id = _n
generate cluster_size = `cluster_size' //setting number of students to be observed at each school

gen random = runiform(0,1)
sort random
gen random_id = _n
gen treat = 0 //randomly assigning treatment to 1/3, active control to 1/3, and passive control to 1/3
gen active = 0
if `active_and_passive' == 0 {
	replace treat = 1 if random_id > (`number_of_schools'/2)	
}
if `active_and_passive' == 1 {
	replace active = 1 if random_id > `number_of_schools'/3 & random_id < 2*(`number_of_schools'/3)
	replace treat = 1 if random_id > 2*(`number_of_schools'/3)	
}
drop random random_id

expand cluster_size //expand to student level data
sort school_id
generate student_id = _n

gen random = runiform(0,1)
gen compliance = 0 //randomly assigning compliance status
replace compliance = 1 if random <= `compliance'
gen treated = treat*compliance //whether a student was treated
gen active_participated = active*compliance
drop random

gen random = runiform(0,1)
gen attrited = 0 //randomly assigning attrition status
replace attrited = 1 if random <= `attrition'
drop random

gen mh = rnormal(0,1) + treated * `te'
//variable normally distributed 0 to 1

replace mh = . if attrited == 1

}

********************************************************************************
* run unbiased regression
********************************************************************************

{

if `bias' == 0 {
	reg mh treated, cluster(school_id) //same as above, but look at whether they were treated instead of whether they were assigned into treatment
	mat a = r(table)
	mat a = a[....,1]
	mat a = a'
	local b_t = _b[treat]
	local p_val = a[1,4]
	return scalar b_treat = `b_t'
	return scalar p = `p_val'
}

}

********************************************************************************
* run biased regression
********************************************************************************

{
	
if `bias' == 1 {
	reg mh treat, cluster(school_id) //regress on treatment, ignoring attrition
	mat a = r(table) //save regression matrix
	mat a = a[....,1] //save first row only
	mat a = a' //transpose matrix
	local b_t = _b[treat] //save treatment coefficient
	local p_val = a[1,4] //save p value from regression matrix
	return scalar b_treat = `b_t'
	return scalar p = `p_val'
}

}


end
