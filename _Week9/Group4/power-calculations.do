clear all

global username "/Users/geenapanzitta/Documents/GitHub/econ490-fall22"

cd "${username}/_Week9/Group4"

run "estimation.do"

set seed 5731341 //generated using random.org

// forv i = 1/100 {
// 	clear
// 	qui projectdata_sim "unbiased"
// 	mat results_mh = nullmat(results_mh) \ [`i', 10, `r(b_mh_treat)', -.5, `r(b_mh_avg_par_educ_yrs)', -5, `r(b_mh_single_parent)', 3, `r(b_mh_number_of_siblings)', 0.5, `r(b_mh_family_income_cny_k)']
//
// }

forv i = 1/100 {
	clear
	qui projectdata_sim "unbiased"
	mat results_mh = nullmat(results_mh) \ [`i', 10, `r(b_mh_treat)', -.5, -5]

}

mat colnames results = i n b_age b_educ_yrs b_dist_from_city b_family_size b_experience

clear

svmat results, names(col)
		
		
//calculate minimum detectable effect size
set matsize 800
cap mat drop results
qui forval te = 0(0.5)1 { // Loop over treatment effect sizes (te) of 0 to 1 standard deviations at increments of 0.1 SDs

	forval i=1/100 { // Running this loop 1000 times
		clear
		set obs 80 // Set sample size to 1000
		gen e=rnormal() // Include a normally distributed error term
		gen t=rnormal()>0 // Randomly assign treatment to half the population
		gen y=1+`te'*t+e // Set functional form for DGP (here we have some constant 1 plus the treatment effect times the positive normal dist plus error term
		reg y t // Run the regression for each loop and store the results in matrix below
		
		mat a = r(table)
		mat a = a[....,1]
		mat results = nullmat(results) \ a' , [`te']
		
		}
}

mat colnames results = i n b_treat b_par_age b_par_educ_yrs b_dist_from_city b_family_size b_family_income_k

// Load the results into data
clear
svmat results , n(col)

local vars b_treat b_par_age b_par_educ_yrs b_dist_from_city b_family_size b_family_income_k

foreach i in `vars' {
	scatter `i' n, b1title("Number of Observations") name("scatter_`i'", replace)
}
graph combine scatter_b_treat scatter_b_par_age scatter_b_par_educ_yrs scatter_b_dist_from_city scatter_b_family_size scatter_b_family_income_k, title("Coefficients vs. Sample Size")

graph export "projectdata_sim.png"
export delimited using "projectdata_sim.csv", replace

// Analyze all the regressions we ran
gen sig = p <0.05 
graph bar sig , over(c10) yline(0.8) //assuming we need power of 0.8, the graph shows for each treatment effect size (values on x-axis) the percent of times that the regression had significant results i.e. where p<0.05

