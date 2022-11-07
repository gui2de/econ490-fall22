///////////////////////////////////////
///*** WEEK 9 POWER CALCULATIONS ***///
///////////////////////////////////////

*Group 5: Noah Blake Smith, Miglé Petrauskaité, and Benjamin Tu

*Date: November 6, 2022

clear all

global path "/Users/nbs/Documents/Georgetown/Semester 5/1 Courses/ECON 490" // User must change to appropriate path

cd "${path}/econ490-fall22/_Week9/Group5"

run "estimation.do" // Execute our simulation file, which contains r-class program charter_simulation

set seed 452996 // Generated using random.org

cap mat drop results // Drop any previous matrices in memory named "results"

///*** RUN PROGRAM ***///

forvalues i = 1/100 {

	di as error `i'
	
	clear // Clear from last loop
	
	qui charter_simulation, biased // The biased option includes the biased average treatment effect (ATE) in addition to the true ATE
	
	mat results = nullmat(results)\[`i',r(ate_true),r(ate_biased),r(ate_biased_c0),r(ate_biased_c1),r(ts_public_mean),r(ts_public_sd),r(ts_charter_mean),r(ts_charter_sd),r(rho)] // Append loop's results to bottom of matrix

}

///*** CLEAN UP ***///

mat colnames results = i ate_true ate_biased ate_biased_c0 ate_biased_c1 ts_public_mean ts_public_sd ts_charter_mean ts_charter_sd rho // Name columns of matrix

clear

svmat results, names(col) // Export matrix columns as variables in memory

la var i "Iteration"
la var ate_true "True average treatment effect"
la var ate_biased "Biased average treatment effect"
la var ate_biased_c0 "Minimum of biased ATE 95% CI"
la var ate_biased_c1 "Maximum of biased ATE 95% CI"
la var ts_public_mean "Mean test score if all children attended public"
la var ts_public_sd "Standard deviation of test scores if all children attended public"
la var ts_charter_mean "Mean test score if all children attended charter"
la var ts_charter_sd "Standard deviation of test scores if all children attended charter"
la var rho "Pairwise correlation between ts_public and ts_charter"

///*** MINIMUM SAMPLE SIZE ***///

gen msn = . // MSN was chosen instead of MSS because the latter also signifies "mean sum of squares"
la var msn "Minimum sample size (N)"

forval i = 1/100 {
	
	local ts_public_mean`i' = ts_public_mean[`i'] // Stata does not recognize cell values as numbers because it is a subpar statistical package, so we must store each cell value as a local
	local ts_charter_mean`i' = ts_charter_mean[`i']
	local rho`i' = rho[`i']
	local ts_public_sd`i' = ts_public_sd[`i']
	local ts_charter_sd`i' = ts_charter_sd[`i']
	
	power pairedmeans `ts_public_mean`i'' `ts_charter_mean`i'', corr(`rho`i'') sd1(`ts_public_sd`i'') sd2(`ts_charter_sd`i'') alpha(0.05) power(0.8) // We find the minimum sample size for our two-sample paired-means test at default 5% significance level and 0.8 power
	
	replace msn = r(N) if i==`i' // Fill in the minimum sample size for row i
}

//*** SUMMARY STATISTICS ***///

*Generate summary statistics matrix
foreach i of varlist ate_true ate_biased msn { // Loop through variables
	sum `i' // Summarize variable
	mat summary_statistics = nullmat(summary_statistics) \ [r(N),r(mean),r(sd),r(min),r(max)] // Append variable summary statistics to matrix
}

mat colnames summary_statistics = observations mean sd min max // Name columns of matrix
mat rownames summary_statistics = ate_true ate_biased msn // Name rows of matrix

*Export matrix to Excel Workbook
putexcel set summary_statistics.xlsx, replace // Specify Excel Workbook to export matrix
putexcel A1 = matrix(summary_statistics), names // Export matrix to Excel Workbook

*Convert Excel Workbook to .csv
/*
// The exclamation point sends commands to the operating system. I have commented this section out because I do not want to install software on your computer without consent. Users of macOS can run the code below, should they choose. Windows users will be unable to run the code.

! cd ~ // Change current directory to default
! /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" // Installs Homebrew, a free, open-source software package management system for macOS and Linux
! brew install gnumeric // Installs gnumeric via Homebrew, a reputable library created by the GNOME Free Software Desktop Project
! cd ${path}/econ490-fall22/_Week9/Group5"
! ssconvert summary_statistics.xlsx summary_statistics.csv // Uses the ssconvert command in the gnumeric library to convert the file from .xlsx to .csv format
! rm summary_statistics.xlsx // Deletes Excel Workbook
*/

///*** GRAPH TRUE ATE vs. BIASED ATE ***///

*Generate cumulative true ATE
gen ate_true_cum = .
la var ate_true_cum "Cumulative true ATE"

forval j = 1/100 { // Loop through each trial
	egen temp = mean(ate_true) in 1/`j' // Generate temporary variable for the mean of the differences from i=1 to j
	replace ate_true_cum = temp[1] if i==`j' // Replace the mean_difference value at row j with the temporary variable
	drop temp // Drop the temporary variable
}

*Generate cumulative biased ATE
gen ate_biased_cum = .
la var ate_biased_cum "Cumulative biased ATE"

forval j = 1/100 { // Loop through each trial
	egen temp = mean(ate_biased) in 1/`j' // Generate temporary variable for the mean of the differences from i=1 to j
	replace ate_biased_cum = temp[1] if i==`j' // Replace the mean_difference value at row j with the temporary variable
	drop temp // Drop the temporary variable
}

*Generate cumulative CIs for biased ATE

gen ate_biased_c0_cum = .
la var ate_biased_c0_cum "Cumulative minimum of biased ATE 95% CI"

forval j = 1/100 { // Loop through each trial
	egen temp = mean(ate_biased_c0) in 1/`j' // Generate temporary variable for the mean of the differences from i=1 to j
	replace ate_biased_c0_cum = temp[1] if i==`j' // Replace the mean_difference value at row j with the temporary variable
	drop temp // Drop the temporary variable
}

gen ate_biased_c1_cum = .
la var ate_biased_c1_cum "Cumulative maximum of biased ATE 95% CI"

forval j = 1/100 { // Loop through each trial
	egen temp = mean(ate_biased_c1) in 1/`j' // Generate temporary variable for the mean of the differences from i=1 to j
	replace ate_biased_c1_cum = temp[1] if i==`j' // Replace the mean_difference value at row j with the temporary variable
	drop temp // Drop the temporary variable
}

*Generate graph
graph set window fontface "Times New Roman"

twoway (rarea ate_biased_c0_cum ate_biased_c1_cum i, fcolor(gs12) fintensity(30) xscale(range(1 100)) xlabel(1 20 40 60 80 100) plotregion(margin(zero)) lwidth(none none)) || line ate_biased_c0_cum ate_biased_c1_cum i, lpattern(dash dash) lcolor(gs10 gs10) lwidth(thin thin) || line ate_biased_cum ate_true_cum i, lcolor(black ebblue) lwidth(medium medium) graphregion(color(white)) xtitle("Trials completed", margin(medium)) yscale(range(0 14)) ytick(0(2)14) ylabel(0(4)14,nogrid) title("`=ustrunescape("\u03B2\u0302")'{subscript:biased} and `=ustrunescape("\u03B2")'{subscript:true} as N {&rarr} {&infin} (95% CI)") legend(order (4 5) label(4 "`=ustrunescape("\u03B2\u0302")'{subscript:biased}") label(5 "`=ustrunescape("\u03B2")'{subscript:true}"))

graph export "${path}/econ490-fall22/_Week9/Group5/biased_and_true_ATEs_as_N_approaches_infinity.png", as(png) name("Graph") replace
