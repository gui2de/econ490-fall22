cap program drop pmt 
clear all

program define pmt, rclass // define an r-class program so that the program writes into return and we can get stuff out of the program

// generate the cutoff for the bottom quintile of 30 observations
set obs 18 // our intervention has 18 strata 
gen cluster_id = _n 
expand 30 // creating 30 duplicates for each cluster 
bysort cluster_id: gen household_id = _n // creating a household id for each cluster

/* we are generating separate levels of household income based on their strata. 
For the ease of this simulation, there are broadly three kinds of households. 
Poor (the first six clusters), middle income (cluster 7-12), and rich (clusters 13-18)
A similar approach is also adopted for the education and family size variables*/

gen inc_origin = . 
replace inc_origin = exp(rnormal()) if inrange(cluster_id, 1, 6)
replace inc_origin = exp(rnormal(1, 0.1)) if inrange(cluster_id, 7, 12)  
replace inc_origin = exp(rnormal(2, 0.1)) if inrange(cluster_id, 13, 18)
replace inc_origin = abs(inc_origin)

gen educ_yrs = . 
replace educ_yrs = floor(rnormal(5,1)) if inrange(cluster_id, 1, 4)
replace educ_yrs = floor(rnormal(7.4,1)) if inrange(cluster_id, 5, 6)
replace educ_yrs = floor(rnormal(10,1)) if inrange(cluster_id, 7, 12)
replace educ_yrs = floor(rnormal(14,1)) if inrange(cluster_id, 13, 18)
replace educ_yrs = abs(educ_yrs)

gen age = trunc(rnormal(40,2))
drop if age < 15
gen age_sq = age*age 

gen work_exp = trunc(rnormal(10,2))
replace work_exp = abs(work_exp)

gen fam_size = . 
replace fam_size = floor(rnormal(6,1)) if inrange(cluster_id, 1, 6)
replace fam_size = floor(rnormal(5,1)) if inrange(cluster_id, 7, 12)
replace fam_size = floor(rnormal(4,1)) if inrange(cluster_id, 12, 18)
replace fam_size = abs(fam_size)

gen female = . 
replace female = round(runiform()) 

/* Here, we are generating true income by adding our variables and their respective weights,
plus an error term with mean 0 in the end to increase variability*/

gen inc = inc_origin + 2*educ_yrs + 0.4*age - 0.005*age_sq + 3*work_exp -1*fam_size - 0.25*female +rnormal(0,20)

// Now, we use our variables to run a regression and predict income
reg inc educ_yrs age age_sq work_exp fam_size female 
predict inc_hat, xb

// And we can rank household id by our two income estimates 
sort cluster_id inc
by cluster_id: gen rank_actual = _n 
sort cluster_id inc_hat 
by cluster_id: gen rank_sim = _n

// set target and beneficiaries 
bysort cluster_id: gen target = inrange(rank_actual, 1, 6)
bysort cluster_id: gen beneficiaries = inrange(rank_sim, 1, 6)
bysort cluster_id: gen bottom40 = inrange(rank_actual, 1, 12)

// calculate inclusion and exlcusion errors 
gen exclusion_error = target == 1 & beneficiaries == 0 if target == 1
gen inclusion_error = bottom40 == 0 & beneficiaries == 1 if beneficiaries == 1
sum exclusion_error 
return scalar ee = r(mean)
sum inclusion_error
return scalar ie = r(mean)

end
