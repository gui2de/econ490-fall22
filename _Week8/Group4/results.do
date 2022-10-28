clear all

global username "/Users/geenapanzitta/Documents/GitHub"

cd "${username}/econ490-fall22/_Week8/Group4"

run "simulate.do"

set seed 5731341 //generated using random.org

foreach j in 50 100 200 300 400 500 {
	forv i = 1/100 {
		clear
		qui income_sim `j'
		mat results = nullmat(results) \ [`i', `j', `r(b_age)', `r(b_educ_yrs)', `r(b_dist_from_city)', `r(b_family_size)', `r(b_experience)']
	}
}

mat colnames results = i n b_age b_educ_yrs b_dist_from_city b_family_size b_experience

clear

svmat results, names(col)

local vars b_age b_educ_yrs b_dist_from_city b_family_size b_experience

foreach i in `vars' {
	scatter `i' n, b1title("Number of Observations") name("scatter_`i'", replace)
}

graph combine scatter_b_age scatter_b_educ_yrs scatter_b_dist_from_city scatter_b_family_size scatter_b_experience, title("Coefficients vs. Sample Size")
graph export "income_sim_scatter.png", replace
