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
	foreach j in 10 20 50 100 { //test different cluster sizes
		cap mat drop results_`k'_`j'
		forval te = 0(1)5 { //loop over treatment effect sizes (te) of 0 to 5 at increments of 1
			forval i=1/100 { //running this loop 100 times
				clear
				projectdata_sim 1 `j' `k' `te' .8 //run simulation with bias, varying cluster sizes, varying number of schools, varying treatment effects, and take-up of 80%
				mat results_`k'_`j' = nullmat(results_`k'_`j') \ [`k',`j',`r(b_treat)', `r(p)',`te'] //save matrix with number of schools, cluster size, treatment coefficient, pvalues, and treatment effect
				}
		}
	}
}

foreach k in 30 60 90 120 { //saving the matrices as tempfiles
	foreach j in 10 20 50 100 {
		clear
		tempfile results_temp_`k'_`j' //create tempfile for matrix
		save `results_temp_`k'_`j'', emptyok
		svmat results_`k'_`j', n(col) //save matrix to tempfile
		save `results_temp_`k'_`j'', replace
	}
}

clear
use `results_temp_30_10' //load first temp file
foreach j in 20 50 100 { //append other temp files
	append using `results_temp_30_`j''
}
foreach k in 60 90 120 {
	foreach j in 10 20 50 100 {
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

foreach k in 30 60 90 120 { //graph probability of significance by treatment effect, by number of schools and cluster size
	graph bar sig if number_of_schools == `k', over(treatment_effect) by(cluster_size, title("MDE, `k' schools, biased, by cluster size")) yline(0.8) b1title("Treatment Effect") ytitle("Probability of Significance")
	graph export "mde_bar_`k'_clustersize.png", replace
}

collapse sig, by(number_of_schools cluster_size treatment_effect) //collapse probability into means, by number of schools, cluster size, and treatment effect

rename sig probability_of_significance //renaming variable

export delimited using "mde_numberofschools_clustersize.csv", replace //save table of significance

}

********************************************************************************
* finding minimum detectable effect, unbiased
********************************************************************************

{
	
clear

tempfile results_temp_unbiased
save `results_temp_unbiased', emptyok

qui forval te = 0(1)5 { //loop over treatment effect sizes (te) of .8 to 1.2 at increments of .1
	foreach j in 1 2 { //running this loop twice because the maximum matrix size is smaller than 1000
		clear
		cap mat drop results_mat
		forval i=1/500 { //running this loop 500 times
			clear
			projectdata_sim 0 50 60 `te' .8 //run simulation without bias, cluster size of 50, 60 schools, varying treatment effects, and take-up of 80%
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

graph bar sig, over(te) yline(0.8) title("MDE, unbiased") b1title("Treatment Effect") ytitle("Probability of Significance") name(mde_bar_unbiased, replace) //graph probability of significance by treatment effect


}

********************************************************************************
* finding minimum detectable effect, biased
********************************************************************************

{
	
clear

tempfile results_temp_biased
save `results_temp_biased', emptyok

qui forval te = 0(1)5 { //loop over treatment effect sizes (te) of .8 to 1.2 at increments of .1
	foreach j in 1 2 { //running this loop twice because the maximum matrix size is smaller than 1000
		clear
		cap mat drop results_mat
		forval i=1/500 { //running this loop 500 times
			clear
			projectdata_sim 1 50 60 `te' .8 //run simulation with bias, cluster size of 50, 60 schools, varying treatment effects, and take-up of 80%
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

graph bar sig, over(te) yline(0.8) title("MDE, biased") b1title("Treatment Effect") ytitle("Probability of Significance") name(mde_bar_biased, replace) //graph probability of significance by treatment effect


}

********************************************************************************
* finding minimum detectable effect, biased, more precise
********************************************************************************

{
	
clear

tempfile results_temp_bias_precise
save `results_temp_bias_precise', emptyok

qui forval te = .8(.1)1.2 { //loop over treatment effect sizes (te) of .8 to 1.2 at increments of .1
	foreach j in 1 2 { //running this loop twice because the maximum matrix size is smaller than 1000
		clear
		cap mat drop results_mat
		forval i=1/500 { //running this loop 500 times
			clear
			projectdata_sim 1 50 60 `te' .8 //run simulation with bias, cluster size of 50, 60 schools, varying treatment effects, and take-up of 80%
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

graph bar sig, over(te) yline(0.8) title("MDE, biased, precise") b1title("Treatment Effect") ytitle("Probability of Significance") name(mde_bar_biased_precise, replace) //graph probability of significance by treatment effect


}

********************************************************************************
* exporting combined graphs
********************************************************************************

{
	
graph combine mde_bar_biased mde_bar_unbiased, title("MDE biased vs unbiased")
graph export "mde_biased_vs_unbiased.png", replace

graph combine mde_bar_biased mde_bar_biased_precise, title("MDE biased, precise")
graph export "mde_biased_vs_biased_precise.png", replace

}
