/* Group 2
Week 5 Assignment
Authors: Felipe, Yuri, Moataz, and Yash 
Last Modified: October 9, 2022 (09/10/2022)
Program .do file */

cd "/Users/devakid/Desktop/Git/econ490-fall22/_Group Projects/Group_2/Week_5"
cap prog drop se_and_outlier
prog define se_and_outlier 
syntax anything

preserve

/* Identifying and dropping string variables before generating a covariance 
matrix and mapping the distribution of standard errors
*/
ds, has(type string)
drop `r(varlist)'

// Generating a local for our dependent variable 
local dep_var: word 1 of `anything'

// Creating a list of the remaining non-string variables 
ds `dep_var', not
local othervar `r(varlist)'

// Creating a loop to generate a covariance matrix for assessing collinearity issues
foreach var in `othervar' {
	corr, cov
}

/* Creating a loop to construct plots which check for the nature of the 
distribution of the error terms
*/ 	
foreach var in `othervar' {
	reg `dep_var' `var'
	rvfplot, yline(0)
	graph save `var'.gph, replace	
}

restore // to bring back the string variables in our dataset


qui reg `anything'

// Calculating studentized residuals for our regression of interest
predict st_resid, rstudent 


/* Plotting the studentized residuals and the critical value of |2| to check 
for the size and quantity of outliers
*/
hist st_resid, percent ///
	xline(2, lcol(red)) ///
	xline(-2, lcol(red)) ///
	title("Distribution of Studentized Residuals") ///
	note("This graph uses a critical value of absolute two to detect outliers", pos(6)) 
	
end

