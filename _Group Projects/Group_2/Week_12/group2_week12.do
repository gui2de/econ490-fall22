** Author: Group 12
** Last Modified: December 12, 2022
** Topic: Week 12 Assignment (High Frequency Checks)

********************************************************************************
clear 
set seed 1
set more off
********************************************************************************

** Load the data 
use "/Users/devakid/Desktop/Git/econ490-fall22/_Group Projects/Group_2/Week_12/data_week12.dta"

********************************************************************************
*Check 1  
********************************************************************************

/* The goal of this check is to look at the survey durations for each survey. 
Once we have these durations, we can see how many surveys were more than 
two standard deviations away from the median (which is not as affected by outliers as the mean) 
duration and flag those above (very slow) and below (very fast) surveys. 
However, just based on this, we cannot determine  whether this was a 
respondent-specific issue or an enumerator issue. To determine that, we can then 
compute the mean survey duration and see how each enumerator compares to the 
mean survey duration. In this manner we can identify which whether the problem 
is specific to respondents or certain enumerators. If it is the latter, then we
can take corrective action to address this issue. */ 

** Calculate duration of each survey 

gen duration = endtime - starttime 
replace duration = (duration/(1000*60)) // converting the duration of the survey to minutes 

sum duration, detail // get mean duration and the standardise 
gen sd_mean = (duration - r(mean))/r(sd) // get z-scores by standardising along the mean   
list duration if abs(sd_mean) > 2 & duration != . // get outlier durations  

/* the two outliers are both 2,505,982 minutes, which is significantly higher than 
the median of 287,725 minutes. As a result, they skew our distribution and durations 
which should be outliers are not recorded as such in this case. 

One workarond to that is dropping the outlier durations and then checking for outliers */

preserve // keep our original dataset in tact 
drop if duration > 2505981 // removing the outliers 
sum duration, detail  
gen sd_mean_noout = (duration - r(mean))/r(sd) 
count if abs(sd_mean_noout) > 2 & duration != .  // 29 outlier observations 
restore // 

** Checking enumerator-level survey duration 
bys surveyor_id: egen enum_avg_dur = mean(duration)
qui sum duration, d 
	gen overall_avg_dur =  286.8167 
	gen diff_avg_dur = enum_avg_dur - r(mean)
	gen perc_diff_avg = (diff_avg_dur/r(mean))*100 // seeing on average the percentage difference between each enumerator's duration and the mean survey duration 

egen tag_enum = tag(enum)

list surveyor_id enum_avg_dur overall_avg_dur perc_diff_avg if tag
keep surveyor_id enum_avg_dur overall_avg_dur perc_diff_avg tag
keep if tag // saving the percentage difference from average survey duration for each enumerator
export excel using "enum_check_results.xlsx", sheetmodify firstrow(varlabels) cell(A2) sheet("`title'") // exporting results 
