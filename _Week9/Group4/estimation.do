********************************************************************************
* ECON 491
* Week 9 - Estimation
* Group 4
* November 14, 2022
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
local takeup_rate: word 5 of `anything' //inputting takeup rate

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
gen treat = 0 //randomly assigning treatment to half of schools
replace treat = 1 if random_id > `number_of_schools'/2
drop random random_id
expand cluster_size //expand
sort school_id
generate student_id = _n
gen random = runiform(0,1)
gen takeup = 0 //randomly assigning takeup status
replace takeup = 1 if random <= `takeup_rate'

//the mental health scale is generally on a scale of 0 to 100
//the true effect size is `te'
gen mental_health_scale = treat*rnormal(`te',5) + rnormal(50,7) //generating mental health scale
replace mental_health_scale = rnormal(50,7) if takeup == 0

}

********************************************************************************
* run biased regression
********************************************************************************

{
	
if `bias' == 1 {
	reg mental_health_scale treat, cluster(school_id) //regress on treatment, ignoring attrition
	mat a = r(table) //save regression matrix
	mat a = a[....,1] //save first row only
	mat a = a' //transpose matrix
	local b_t = _b[treat] //save treatment coefficient
	local p_val = a[1,4] //save p value from regression matrix
	return scalar b_treat = `b_t'
	return scalar p = `p_val'
}

}

********************************************************************************
* run unbiased regression
********************************************************************************

{
	
if `bias' == 0 {
	replace treat = treat*takeup //make treatment only 1 if at treatment school and complied
	reg mental_health_scale treat, cluster(school_id)
	mat a = r(table)
	mat a = a[....,1]
	mat a = a'
	local b_t = _b[treat]
	local p_val = a[1,4]
	return scalar b_treat = `b_t'
	return scalar p = `p_val'
}

}


end
