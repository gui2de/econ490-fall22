clear all

global path "/Users/benjamintu/Documents/Github"

cd "${path}/econ490-fall22/_Group Projects/Group_5/Week8_Assignment"

run "Group5_Week8_Simulation.do" // Execute our simulation file

set seed 452996 // Generated using random.org

///*** RUN PROGRAM ***///

forvalues i = 1/100 {

	di as error `i'
	
	clear // Clear from last loop
	
	qui charter_simulation // Our r-class program is called charter_simulation
	
	mat results = nullmat(results)\[`i',r(beta),r(beta_hat)] // Append loop's results to bottom of matrix

}

mat colnames results = i beta beta_hat // Name columns of matrix

clear

svmat results, names(col) // Export matrix columns as variables in memory

///*** CREATE GRAPHS & TABLES ***///

*Table with summary statistics
sum beta beta_hat

*Histogram of difference between beta and beta_hat
gen difference = beta - beta_hat
hist difference, freq xtick(-1.5(0.1)1.5) xlabel(-1.5(0.5)1.5) xtitle("Difference between {&beta} and `=ustrunescape("\{&beta}\u0302")'") bin(30) graphregion(color(white))
graph export "Histogram_of_Difference_between_Beta_and_Beta_Hat.png", as(png) name("Graph") replace

*Generate mean difference variable
gen mean_difference = .
la var mean_difference "Mean of differences from i=1 to current row"

forval j = 1/100 { // Loop through each trial
	egen temp = mean(difference) in 1/`j' // Generate temporary variable for the mean of the differences from i=1 to j
	replace mean_difference = temp[1] if i==`j' // Replace the mean_difference value at j with the temporary variable
	drop temp // Drop the temporary variable
}

*Graph: mean of difference between beta and beta_hat converges to 0 as N goes to infinity
scatter mean_difference i, ytitle("Mean difference between {&beta} and `=ustrunescape("\{&beta}\u0302")'") xtitle("Trials completed") graphregion(color(white))
graph export "Mean_Difference_Converges_to_0.png", as(png) name("Graph") replace

*Export simulation data as CSV
export delimited using "Group5_Week8_Data.csv", replace
