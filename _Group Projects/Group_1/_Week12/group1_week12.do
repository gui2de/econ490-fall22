/* --------------------------------
Problem Set: Week 12
ECON 490
Shaily Acharya, Sylvia Brown, Neel Desai
 --------------------------------*/

/* --------------------------------

BEFORE RUNNING THIS CODE:
1) CHANGE DIRECTORY BELOW TO THE FILEPATH TO YOUR VERSION OF THE BOX FOLDER IN YOUR LAPTOP

 --------------------------------*/

clear
global user "/Users/sylviabrown/git/econ490-fall22/_Group Projects/Group_1/_Week12"
* ^^^^^^^^^^^^^^^^ THIS IS WHERE YOU NEED TO UPDATE THE FILE PATH ^^^^^^^^^^^^^^^^
cd "$user"

// set standard settings
set more off
set seed 123

/* ------------

CHECK #1

 -------------*/
 
* -------------------------------- GENERATING THE DATA --------------------------------
// simulate data used for check
set obs 1000
forvalues i = 1/9 {
gen var_`i' = runiformint(1,5)
}

// generate random variable and identification variable
gen random_var = runiform(0,1)
gen obs_num = _n

// generate instances where they select the same value for every question
forvalues i = 2/9 {
	replace var_`i' = var_1 if random_var <= 0.05
}

// generate instances where they alternate between two of the same values for every question
forvalues i = 3/9 {
	local mod_result = mod(`i', 2)
	replace var_`i' = var_1 if `mod_result' == 1 & random_var > 0.05 & random_var <= 0.12
	replace var_`i' = var_2 if `mod_result' == 0 & random_var > 0.05 & random_var <= 0.12
}
// generate instances where they answer in a "Christmas tree" or "staircase" 
// (answers with the highest/lowest number and then steps up/down by increments of one
// until they reach the lowest/highest number, and then "step" back up/down again)
local r_triangle 1 2 3 4 5 4 3 2 1
local l_triangle 5 4 3 2 1 2 3 4 5

local j = 1
foreach i in `r_triangle' {
	replace var_`j' = `i' if random_var > 0.12 & random_var <= 0.15
	local j = `j' + 1
}

local k = 1
foreach i in `l_triangle' {
	replace var_`k' = `i' if random_var > 0.15 & random_var <= 0.18
	local k = `k' + 1
}

* -------------------------------- CHECKING THE DATA --------------------------------
// generate the check variable
generate pattern_flag = .

// check if they answer the same for every answer
replace pattern_flag = 1 if var_1 == var_2 & var_2 == var_3 & var_3 == var_4 & var_4 == var_5 & var_5 == var_6 & var_6 == var_7 & var_7 == var_8 & var_8 == var_9

// check if they alternate between only two answers
replace pattern_flag = 1 if var_1 == var_3 & var_3 == var_5 & var_5 == var_7 & var_7 == var_9 & var_2 == var_4 & var_4 == var_6 & var_6 == var_8 & var_1 ~= var_2

// check if they answer in a "Christmas tree" pattern
replace pattern_flag = 1 if var_2 == var_1 + 1 & var_3 == var_2 + 1 & var_4 == var_3 + 1 & var_5 == var_4 + 1 & var_6 == var_5 - 1 & var_7 == var_6 - 1 & var_8 == var_7 - 1 & var_9 == var_8 - 1
replace pattern_flag = 1 if var_2 == var_1 - 1 & var_3 == var_2 - 1 & var_4 == var_3 - 1 & var_5 == var_4 - 1 & var_6 == var_5 + 1 & var_7 == var_6 + 1 & var_8 == var_7 + 1 & var_9 == var_8 + 1

replace pattern_flag = 0 if pattern_flag == . 

* -------------------------------- EXPORTING THE DATA --------------------------------
export excel using "output/check_results.xlsx"


/* ------------

CHECK #2

 -------------*/
 
 
 
 
 
 
 