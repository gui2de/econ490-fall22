********************************************************************************
* ECON 491
* Week 9 - Power Calculations
* Group 4
* November 14, 2022
********************************************************************************

clear all

global username "/Users/geenapanzitta/Documents/GitHub/econ490-fall22"

cd "${username}/_Week9/Group4"

run "estimation.do"

set seed 46595 //generated using random.org

********************************************************************************
* picking number of schools and cluster size
********************************************************************************

{

qui foreach k in 30 60 90 120 { //test different number of schools
	foreach j in 10 20 30 40 { //test different cluster sizes
		cap mat drop results_`k'_`j'
		forval te = 0(.2)1 { //loop over treatment effect sizes (te) of 0 to 5 at increments of 1
			forval i=1/100 { //running this loop 100 times
				clear
				projectdata_sim 0 `j' `k' `te' .8 .05 1 //run simulation with bias, varying cluster sizes, varying number of schools, varying treatment effects, and compliance of 80%
				mat results_`k'_`j' = nullmat(results_`k'_`j') \ [`k',`j',`r(b_treat)', `r(p)',`te'] //save matrix with number of schools, cluster size, treatment coefficient, pvalues, and treatment effect
				}
		}
	}
}

foreach k in 30 60 90 120 { //saving the matrices as tempfiles
	foreach j in 10 20 30 40 {
		clear
		tempfile results_temp_`k'_`j' //create tempfile for matrix
		save `results_temp_`k'_`j'', emptyok
		svmat results_`k'_`j', n(col) //save matrix to tempfile
		save `results_temp_`k'_`j'', replace
	}
}

clear
use `results_temp_30_10' //load first temp file
foreach j in 20 30 40 { //append other temp files
	append using `results_temp_30_`j''
}
foreach k in 60 90 120 {
	foreach j in 10 20 30 40 {
		append using `results_temp_`k'_`j''
	}
}

rename c1 number_of_schools //rename variables
rename c2 cluster_size
rename c3 b_t
rename c4 p
rename c5 treatment_effect
sort number_of_schools //sort by number of schools
sort cluster_size //sort by cluster size

gen sig = p <0.05 //generate signfiicance variable if p value less than .05

collapse sig, by(number_of_schools cluster_size treatment_effect) //collapse probability into means, by number of schools, cluster size, and treatment effect

save $sizes_dta, replace

}

********************************************************************************
* finding minimum detectable effect, biased
********************************************************************************

{
	
clear

tempfile results_temp_biased
save `results_temp_biased', emptyok

qui forval te = 0(.2)1 { //loop over treatment effect sizes (te) of .8 to 1.2 at increments of .1
	foreach j in 1 2 { //running this loop twice because the maximum matrix size is smaller than 1000
		clear
		cap mat drop results_mat
		forval i=1/500 { //running this loop 500 times
			clear
			projectdata_sim 1 20 90 `te' .8 .05 1 //run simulation with bias, cluster size of 50, 60 schools, varying treatment effects, and take-up of 80%
			mat results_mat = nullmat(results_mat) \ [`r(b_treat)', `r(p)',`te'] //save matrix with treatment coefficient, pvalues, and treatment effect
			}
		clear
		svmat results_mat, n(col) //save matrix to data
		rename c1 b_t //rename variables
		rename c2 p
		rename c3 te
		
		gen sig = p <0.05 //generate signfiicance variable if p value less than .05
		collapse sig, by(te) //collapse data to find probability of significance
		
		append using `results_temp_biased' //save data to tempfile
		save `results_temp_biased', replace
		}
}

clear
use `results_temp_biased' //load tempfile
sort te

collapse sig, by(te)

save $biased_dta, replace

}

********************************************************************************
* finding minimum detectable effect, unbiased
********************************************************************************

{
	
clear

tempfile results_temp_unbiased
save `results_temp_unbiased', emptyok

qui forval te = 0(.2)1 { //loop over treatment effect sizes (te) of .8 to 1.2 at increments of .1
	foreach j in 1 2 { //running this loop twice because the maximum matrix size is smaller than 1000
		clear
		cap mat drop results_mat
		forval i=1/500 { //running this loop 500 times
			clear
			projectdata_sim 0 20 90 `te' .8 .05 1 //run simulation without bias, cluster size of 50, 60 schools, varying treatment effects, and take-up of 80%
			mat results_mat = nullmat(results_mat) \ [`r(b_treat)', `r(p)',`te'] //save matrix with treatment coefficient, pvalues, and treatment effect
			}
		clear
		svmat results_mat, n(col) //save matrix to data
		rename c1 b_t //rename variables
		rename c2 p
		rename c3 te
		
		gen sig = p <0.05 //generate signfiicance variable if p value less than .05
		collapse sig, by(te) //collapse data to find probability of significance
		
		append using `results_temp_unbiased' //save data to tempfile
		save `results_temp_unbiased', replace
		}
}

clear
use `results_temp_unbiased' //load tempfile
sort te

collapse sig, by(te)

save $unbiased_dta, replace


}

********************************************************************************
* finding minimum detectable effect, unbiased, more precise
********************************************************************************

{
	
clear

tempfile results_temp_bias_precise
save `results_temp_bias_precise', emptyok

qui forval te = .15(.01).2 { //loop over treatment effect sizes (te) of .8 to 1.2 at increments of .1
	foreach j in 1 2 { //running this loop twice because the maximum matrix size is smaller than 1000
		clear
		cap mat drop results_mat
		forval i=1/500 { //running this loop 500 times
			clear
			projectdata_sim 0 20 90 `te' .8 .05 1 //run simulation with bias, cluster size of 50, 60 schools, varying treatment effects, and take-up of 80%
			mat results_mat = nullmat(results_mat) \ [`r(b_treat)', `r(p)',`te'] //save matrix with treatment coefficient, pvalues, and treatment effect
			}
		clear
		svmat results_mat, n(col) //save matrix to data
		rename c1 b_t //rename variables
		rename c2 p
		rename c3 te
		
		gen sig = p <0.05 //generate signfiicance variable if p value less than .05
		collapse sig, by(te) //collapse data to find probability of significance
		
		append using `results_temp_bias_precise' //save data to tempfile
		save `results_temp_bias_precise', replace
		}
}

clear
use `results_temp_bias_precise' //load tempfile
sort te

collapse sig, by(te)

save $precise_dta, replace


}

********************************************************************************
* finding minimum detectable effect, unbiased, takeup
********************************************************************************

{

qui foreach j in 20 40 60 80 100 { //test different attrition levels
	local j2 `j'*.01
	cap mat drop results_`j'
	forval te = 0(.2)1 { //loop over treatment effect sizes (te) of 0 to 5 at increments of 1
		forval i=1/100 { //running this loop 100 times
			clear		
			projectdata_sim 0 20 90 `te' `j2' .05 1 //run simulation with bias, varying cluster sizes, varying number of schools, varying treatment effects, and compliance of 80%
			mat results_`j' = nullmat(results_`j') \ [`j2',`r(b_treat)', `r(p)',`te'] //save matrix with number of schools, cluster size, treatment coefficient, pvalues, and treatment effect
			}
	}
}

foreach j in 20 40 60 80 100 {
	clear
	tempfile results_temp_`j' //create tempfile for matrix
	save `results_temp_`j'', emptyok
	svmat results_`j', n(col) //save matrix to tempfile
	save `results_temp_`j'', replace
}

clear
use `results_temp_20' //load first temp file
foreach j in 40 60 80 100 { //append other temp files
	append using `results_temp_`j''
}

rename c1 takeup //rename variables
rename c2 b_t
rename c3 p
rename c4 treatment_effect
sort takeup

gen sig = p <0.05 //generate signfiicance variable if p value less than .05
replace takeup = round(takeup * 100)

collapse sig, by(takeup treatment_effect) //collapse probability into means, by number of schools, cluster size, and treatment effect

save $takeup_dta, replace

}

********************************************************************************
* finding minimum detectable effect, unbiased, attrition
********************************************************************************

{

qui foreach j in 1 5 10 50 { //test different attrition levels
	local j2 `j'*.01
	cap mat drop results_`j'
	forval te = 0(.2)1 { //loop over treatment effect sizes (te) of 0 to 5 at increments of 1
		forval i=1/100 { //running this loop 100 times
			clear
			projectdata_sim 0 20 90 `te' .8 `j2' 1 //run simulation with bias, varying cluster sizes, varying number of schools, varying treatment effects, and compliance of 80%
			mat results_`j' = nullmat(results_`j') \ [`j2',`r(b_treat)', `r(p)',`te'] //save matrix with number of schools, cluster size, treatment coefficient, pvalues, and treatment effect
			}
	}
}

foreach j in 1 5 10 50 {
	clear
	tempfile results_temp_`j' //create tempfile for matrix
	save `results_temp_`j'', emptyok
	svmat results_`j', n(col) //save matrix to tempfile
	save `results_temp_`j'', replace
}

clear
use `results_temp_1' //load first temp file
foreach j in 5 10 50 { //append other temp files
	append using `results_temp_`j''
}

rename c1 attrition //rename variables
rename c2 b_t
rename c3 p
rename c4 treatment_effect
sort attrition

gen sig = p <0.05 //generate signfiicance variable if p value less than .05
replace attrition = round(attrition * 100)

collapse sig, by(attrition treatment_effect) //collapse probability into means, by number of schools, cluster size, and treatment effect

save $attrition_dta, replace

}

********************************************************************************
* combining all data
********************************************************************************

{
	
clear
tempfile dta_compiling
save `dta_compiling', emptyok

use $sizes_dta, clear
gen type = "sizes"
gen takeup = .
gen attrition = .
rename treatment_effect te
order te sig number_of_schools cluster_size takeup attrition type
save `dta_compiling', replace

use $biased_dta, clear
gen type = "biased"
gen number_of_schools = .
gen cluster_size = .
gen takeup = .
gen attrition = .
order te sig number_of_schools cluster_size takeup attrition type
append using `dta_compiling'
save `dta_compiling', replace

use $unbiased_dta, clear
gen type = "unbiased"
gen number_of_schools = .
gen cluster_size = .
gen takeup = .
gen attrition = .
order te sig number_of_schools cluster_size takeup attrition type
append using `dta_compiling'
save `dta_compiling', replace

use $precise_dta, clear
gen type = "precise"
gen number_of_schools = .
gen cluster_size = .
gen takeup = .
gen attrition = .
order te sig number_of_schools cluster_size takeup attrition type
append using `dta_compiling'
save `dta_compiling', replace

use $takeup_dta, clear
gen type = "takeup"
gen number_of_schools = .
gen cluster_size = .
gen attrition = .
rename treatment_effect te
order te sig number_of_schools cluster_size takeup attrition type
append using `dta_compiling'
save `dta_compiling', replace

use $attrition_dta, clear
gen type = "attrition"
gen number_of_schools = .
gen cluster_size = .
gen takeup = .
rename treatment_effect te
order te sig number_of_schools cluster_size takeup attrition type
append using `dta_compiling'
save `dta_compiling', replace

save $all_dta, replace

}

********************************************************************************
* making all the graphs
********************************************************************************

{

use $all_dta, clear

label define a2level 1 "1% Attrition" 5 "5% Attrition" 10 "10% Attrition" 50 "50% Attrition"
label values attrition a2level

label define t2level 20 "20% Compliance" 40 "40% Compliance" 60 "60% Compliance" 80 "80% Compliance" 100 "100% Compliance"
label values takeup t2level

label define c2size 10 "10 Students Per School " 20 "20 Students Per School" 30 "30 Students Per School" 40 "40 Students Per School"
label values cluster_size c2size

foreach k in 30 60 90 120 { //graph probability of significance by treatment effect, by number of schools and cluster size
	graph bar sig if number_of_schools == `k' & type == "sizes", over(te) by(cluster_size, title("Minimum Detectable Effect, `k' Schools")) yline(0.8) b1title("Treatment Effect (sd)") ytitle("Probability of Significance") bar(1,color(navy))
	graph export "graphs/mde_`k'schools_clustersize.png", replace
}

graph bar sig if type == "biased", over(te) yline(0.8) title("Minimum Detectable Effect, Not Accounting for Partial Compliance", size(small)) b1title("Treatment Effect (sd)") ytitle("Probability of Significance") bar(1,color(navy)) name(mde_bar_biased, replace)

graph bar sig if type == "unbiased", over(te) yline(0.8) title("Minimum Detectable Effect, Accounting for Partial Compliance", size(small)) b1title("Treatment Effect (sd)") ytitle("Probability of Significance") bar(1,color(navy)) name(mde_bar_unbiased, replace) xsize(5) ysize(5) //graph probability of significance by treatment effect

graph combine mde_bar_biased mde_bar_unbiased, title("Minimum Detectable Effect and Partial Compliance, 90 Schools, 20 Students Per School") xsize(10) ysize(5)
graph export "graphs/mde_biased_vs_unbiased.png", replace

graph bar sig if type == "precise", over(te) yline(0.8) title("Minimum Detectable Effect, 90 Schools, 20 Students Per School", size(medium)) b1title("Treatment Effect (sd)") ytitle("Probability of Significance") name(mde_bar_biased_precise, replace) bar(1,color(navy)) //graph probability of significance by treatment effect
graph export "graphs/mde_precise.png", replace

graph bar sig if type == "takeup", over(te) by(takeup, title("Minimum Detectable Effect, 90 Schools, 20 Students Per School")) yline(0.8) b1title("Treatment Effect (sd)") ytitle("Probability of Significance") bar(1,color(navy))
graph export "graphs/mde_takeup.png", replace

graph bar sig if type == "attrition", over(te) by(attrition, title("Minimum Detectable Effect, 90 Schools, 20 Students Per School")) yline(0.8) b1title("Treatment Effect (sd)") ytitle("Probability of Significance") bar(1,color(navy))
graph export "graphs/mde_attrition.png", replace

}
