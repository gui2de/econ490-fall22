/* --------------------------------

BEFORE RUNNING THIS CODE: CHANGE DIRECTORY BELOW TO FILEPATH WHERE YOU HAVE THE ECON490-FALL22 FOLDER

 --------------------------------*/

// clear the memory environment
clear all

// set the working directory 
global username "/Users/sylviabrown/git/"
* ^^^^^^^^^^^^^^^^ THIS IS WHERE YOU NEED TO UPDATE THE FILE PATH ^^^^^^^^^^^^^^^^

cd "${username}/econ490-fall22/_Week8/group1"

// Set the randomization seed 
set seed 563241

// run the simulation program
do "simulate.do"

// Start a loop over a parameter index (in this case, the number of state clusters we have sampled from)
forvalues i = 1/20 { // for 1 to 20 states...
	forvalues j = 1/5 { // ...generate 5 different sets of samples

		clear

		qui salary_simulate `i' // run the program

		mat results = nullmat(results)\[`i', `j', `r(sample_size)', `r(b_gpa)', `r(se_gpa)'] // save results relevant to estimate of effect of GPA on salary

	}

}

// save results of our loop above as data
mat colnames results = clusters number_run sample_size b_gpa se_gpa
clear
svmat results, names(col) 

// generate scatter plots of our number of clusters we've sampled from vs. variables relevant to estimate of effect of GPA on salary
scatter sample_size clusters, title("Sample Size vs. Number of Clusters") name(sample_size, replace)
scatter b_gpa clusters, title("Estimate of Effect of GPA" "on Salary vs. Number of Clusters") name(b_gpa, replace)
scatter se_gpa clusters, title("Standard Error of Estimate of Effect" "of GPA on Salary vs. Number of Clusters") name(se_gpa, replace)

// create a first row of scatter plots
graph combine sample_size b_gpa, rows(1) name(row1)

// combine the three scatter plots
graph combine row1 se_gpa, cols(1)

// export the scatterplots as a .png file
graph export "salary_scatter.png", replace

// export data as .csv file
export delimited demonstration_results
