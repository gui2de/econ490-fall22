

cap prog drop projectdata_sim

prog define projectdata_sim, rclass

clear

syntax anything

clear
set obs 112 //CEPS uses 112 schools for their calculations
generate school_id = _n
generate school_size = trunc(rnormal(179,5))
gen random = runiform(0,1)
gen treat = 0 //randomly assigning treatment to each school with a 50% chance
replace treat = 1 if random > 0.5
drop random
//generate fixed effect
expand school_size //this gives us approximately 20,000 observations, similar to the CEPS dataset
sort school_id
generate student_id = _n

// one of the parent' ages
gen avg_par_age = rnormal(28+16, 4) // geneated according to the world data atlas china, average age of having a baby, and the average age for students from grade 9 to 12
gen avg_par_educ_yrs = trunc(rnormal(12, 2))
drop if avg_par_educ_yrs <0
// family size
gen random = runiform(0,1)
gen single_parent = 0
replace single_parent = 1 if random < .076 //statistic from 1990
//Liu H. A preliminary analysis of single-parent families in China. China Popul Today. 1998 Jun;15(3):11. PMID: 12293906.
gen number_of_siblings = trunc(rnormal(1.4,0.7)) //the average worldwide number of siblings is a mean of 2 and a sd of 1, but due to the history of the one child policy we use a lower distribution here
drop if number_of_siblings < 0
// family_income_k
gen family_income_cny_k = rnormal(35+avg_par_educ_yrs*.7, 10) // generated based on the average chinese household income from stats.gov.cn
gen eq = rnormal(60,10)

//the mental health scale is generally on a scale of 0 to 100
gen mental_health_scale = 10*treat - .5*avg_par_educ_yrs - 5*single_parent + 3*number_of_siblings + .5*family_income_cny_k +.15*eq + rnormal(20,7)
//the true effect size of treatment is 10

//the academic performance is generally on a scale of 0 to 100
gen academic_performance = .3*mental_health_scale + .5*avg_par_educ_yrs - .5*single_parent + .3*family_income_cny_k +.1*eq + rnormal(30,7)
//the true effect size of mental health scale is .3, which makes the true effect size of treatment about 3


if `anything' == "biased" {
	
reg mental_health_scale treat avg_par_age avg_par_educ_yrs single_parent number_of_siblings family_income_cny_k, cluster(school_id)

return scalar b_mh_treat = _b[treat]
return scalar b_mh_par_educ_yrs = _b[avg_par_educ_yrs]
return scalar b_mh_single_parent = _b[single_parent]
return scalar b_mh_number_of_siblings = _b[number_of_siblings]
return scalar b_mh_family_income_cny_k = _b[family_income_cny_k]

ivregress 2sls academic_performance avg_par_age avg_par_educ_yrs single_parent number_of_siblings family_income_cny (mental_health_scale = treat), cluster(school_id)

return scalar b_ap_mental_health_scale = _b[mental_health_scale]
return scalar b_ap_par_educ_yrs = _b[avg_par_educ_yrs]
return scalar b_ap_single_parent = _b[single_parent]
return scalar b_ap_family_income_cny_k = _b[family_income_cny_k]

}


if `anything' != "biased" {
	
	
reg mental_health_scale treat avg_par_age avg_par_educ_yrs single_parent number_of_siblings family_income_cny_k eq, cluster(school_id)

return scalar b_mh_treat = _b[treat]
return scalar b_mh_par_educ_yrs = _b[avg_par_educ_yrs]
return scalar b_mh_single_parent = _b[single_parent]
return scalar b_mh_number_of_siblings = _b[number_of_siblings]
return scalar b_mh_family_income_cny_k = _b[family_income_cny_k]
return scalar b_mh_eq = _b[eq]

ivregress 2sls academic_performance avg_par_age avg_par_educ_yrs single_parent number_of_siblings family_income_cny eq (mental_health_scale = treat), cluster(school_id)

return scalar b_ap_mental_health_scale = _b[mental_health_scale]
return scalar b_ap_par_educ_yrs = _b[avg_par_educ_yrs]
return scalar b_ap_single_parent = _b[single_parent]
return scalar b_ap_family_income_cny_k = _b[family_income_cny_k]
return scalar b_ap_eq = _b[eq]

}

end
