/* Group 2
Week 5 Assignment
Authors: Felipe, Yuri, Moataz, and Yash 
Last Modified: October 9, 2022 (09/10/2022)
Demonstration.do file */

/* Notes: 
1. The covariace matrix and the distribution of standard errors will produce 
the same results across all three demonstrations due to the way they are calculated. 
2. We suggest running each demonstration separately because for each demonstration 
the studentized residual histogram will be different since the independent
variables vary. Running the entire demonstration do-file in one go will only save 
the results of the studentized residual for the third demonstration. 
*/

clear 

// Setting working directory 
global wd "/Users/devakid/Desktop/Git/econ490-fall22/_Group Projects/Group_2/Week_5" 

// Running the program.do file 
do "$wd/program.do"

// Demonstration 1
sysuse lifeexp, clear
se_and_outlier lexp popgrowth gnppc region safewater

// Demonstration 2
sysuse lifeexp, clear
se_and_outlier lexp popgrowth gnppc region 

// Demonstration 3
sysuse lifeexp, clear
se_and_outlier lexp popgrowth gnppc safewater

