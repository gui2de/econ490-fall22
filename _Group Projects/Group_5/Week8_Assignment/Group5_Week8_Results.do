clear all

global path "/Users/benjamintu/Documents/Github" // User must change to appropriate path

cd "${path}/econ490-fall22/_Group Projects/Group_5/Week8_Assignment"

run "Group5_Week8_Simulation.do" // Execute our simulation file

set seed 452996 // Generated using random.org

///*** RUN PROGRAM ***///

forvalues i = 1/100 {

	di as error `i'
	
	clear // Clear from last loop
	
	qui charter_simulation // Our r-class program is called charter_simulation
	
	mat results = nullmat(results)\[`i',r(beta),r(beta_hat),r(beta_hat_c0),r(beta_hat_c1)] // Append loop's results to bottom of matrix

}

///*** CLEAN UP ***///

mat colnames results = i beta beta_hat beta_hat_c0 beta_hat_c1 // Name columns of matrix

clear

svmat results, names(col) // Export matrix columns as variables in memory

*Generate difference variables
gen difference = beta - beta_hat
gen difference_c0 = beta - beta_hat_c0 // Difference between beta and beta hat's 95% CI lower bound
gen difference_c1 = beta - beta_hat_c1 // Difference between beta and beta hat's 95% CI upper bound

*Generate line y = 0
gen y = 0

*Generate mean difference variable
gen mean_difference = .
la var mean_difference "Mean of differences from i=1 to current row"

forval j = 1/100 { // Loop through each trial
	egen temp = mean(difference) in 1/`j' // Generate temporary variable for the mean of the differences from i=1 to j
	replace mean_difference = temp[1] if i==`j' // Replace the mean_difference value at row j with the temporary variable
	drop temp // Drop the temporary variable
}

*Generate mean difference variable: lower 95% CI
gen mean_difference_c0 = .
la var mean_difference_c0 "Lower 95% CI of mean of differences from i=1 to current row"

forval j = 1/100 { // Loop through each trial
	egen temp = mean(difference_c0) in 1/`j' // Generate temporary variable from i=1 to j
	replace mean_difference_c0 = temp[1] if i==`j' // Replace the mean_difference_c0 value at row j with the temporary variable
	drop temp // Drop the temporary variable
}

*Generate mean difference variable: upper 95% CI
gen mean_difference_c1 = .
la var mean_difference_c1 "Upper 95% CI of mean of differences from i=1 to current row"

forval j = 1/100 { // Loop through each trial
	egen temp = mean(difference_c1) in 1/`j' // Generate temporary variable from i=1 to j
	replace mean_difference_c1 = temp[1] if i==`j' // Replace the mean_difference_c1 value at row j with the temporary variable
	drop temp // Drop the temporary variable
}

///*** CREATE GRAPHS & TABLES ***///

*Table with summary statistics
sum beta beta_hat

*Histogram of difference between beta and beta_hat
hist difference, freq xtick(-1.5(0.1)1.5) xlabel(-1.5(0.5)1.5) xtitle("Difference between {&beta} and `=ustrunescape("\{&beta}\u0302")'") bin(30) graphregion(color(white))
graph export "Histogram_of_Difference_between_Beta_and_Beta_Hat.png", as(png) name("Graph") replace

*Graph: mean of difference between beta and beta_hat converges to 0 as N goes to infinity
twoway (rarea mean_difference_c0 mean_difference_c1 i, fcolor(gs12) fintensity(30) xscale(range(1 100)) xlabel(1 20 40 60 80 100) plotregion(margin(zero)) lwidth(none none)) || line mean_difference_c0 mean_difference_c1 i, lpattern(dash dash) lcolor(gs8 gs8) || line y i, lcolor(black) lwidth(thin) || scatter mean_difference i, mcolor(black) graphregion(color(white)) xtitle("Trials completed", margin(medium)) yscale(range(-1 1.75)) ytick(-1(0.5)1.5) ylabel(-1(0.5)1.5,nogrid) legend(off) title("Mean difference between {&beta} and `=ustrunescape("\{&beta}\u0302")' as N {&rarr} {&infin} (95% CI)")

graph export "Mean_Difference_Converges_to_0_Updated.png", as(png) name("Graph") replace

*Export simulation data as CSV
export delimited using "Group5_Week8_Data.csv", replace
