// program that will compare a regression with two predictors to a regression with
	// two predictors and an interaction term.
	// outputs: 2 regression output tables and a scatter plot with 2 lines of best fit
	
cap prog drop group3
prog def group3
	syntax anything
	local y: word 1 of `anything'
	local x1: word 2 of `anything'
	local x2: word 3 of `anything'
	gen x1x2 = x1*x2
	quietly reg y x1 x2
	svmat r(table)
	reg y x1 x2 x1x2
	