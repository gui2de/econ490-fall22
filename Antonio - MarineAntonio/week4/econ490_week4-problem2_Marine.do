*****
* Problem 2.
* Formatting of the PSLE info of students of 138 schools in Arusha District in Tanzania is messy (psle_student_raw.dta).
* TASK: Create a student level dataset with the following variables:
* schoolcode, cand_id, gender, prem_number, name, and
*grade variables for
** kiswahili english maarifa hisabati science uraia average
* There is a hint do file with code to clean it for 1 school. I need to make a loop through all 138.

clear

cd "C:\Users\anton\Box\Econ490_Fall2022\Week4\04_assignment\data"

use psle_student_raw.dta, clear

cd "C:\Users\anton\OneDrive\Documents\Georgetown\ECON\ECON490\assignments\data"
* For review, you'll have to edit this directory--I was unable to upload anything to the Box drive.

split s, parse(">SUBJECTS")
drop s s1

split s2, parse("</TD></TR>") gen(student)

gen school = _n

save psle_student_s2, replace

*First we will clean the first row/school and save it as its own dataset. Then, we will use a loop to clean school 2 and append the school 1 dataset to the end, create a new dataset with both schools, and then append this dataset to school 3 (and so on...)
keep if school == 1

reshape long student, i(schoolcode) j(id)

drop if student == ""

drop school id s2

split student, parse("</FONT></TD>")

drop if student2 == ""

*candidate ID variable
	gen cand_id = substr(student1,-14,.)
	
*gender
	gen gender = substr(student3,-1,.)
	
*prem number
	gen prem_number =  substr(student2,strpos(student2, "CENTER") +8, .)
	
*name
	gen name =  substr(student4,strpos(student4, "<P>") +3 , .)
	
*grades
	replace student5 = substr(student5,ustrpos(student5, "LEFT") +6 , .)
	replace student5 = substr(student5,1 , strlen(student5) - 7)
	
*schoolcode
	replace schoolcode = substr(schoolcode, 5, 9)
	
*Now all of each student's info is in one column, so we will create separate columns for each variable
split student5, parse(,) //use "comma" as the parser.

*rename variables
	rename student51 kiswahili
	rename student52 english
	rename student53 maarifa
	rename student54 hisabati
	rename student55 science
	rename student56 uraia
	rename student57 average
	
*drop columns that are no longer needed.
drop student student1 student2 student3 student4 student5

local varlist "kiswahili english maarifa hisabati science uraia average"
foreach subject in `varlist'{
	replace `subject' = usubstr(`subject',-1,1)
	}

*save school1, replace
tempfile school1
save `school1'
	*tempfile^ ?

* I call the final "Marine" to indicate that I created this dataset
save psle_student_final_Marine, replace
	

* Now we can create the loop.

forvalues i = 2/138 {
	use psle_student_s2.dta, clear
	keep if school == `i'
	reshape long student, i(schoolcode) j(id)
	drop if student == ""
	drop school id s2
	split student, parse("</FONT></TD>")
	drop if student2 == ""
*candidate ID variable
	gen cand_id = substr(student1,-14,.)
*gender
	gen gender = substr(student3,-1,.)
*prem number
	gen prem_number =  substr(student2,strpos(student2, "CENTER") +8, .)
*name
	gen name =  substr(student4,strpos(student4, "<P>") +3 , .)
*grades
	replace student5 = substr(student5,ustrpos(student5, "LEFT") +6 , .)
	replace student5 = substr(student5,1 , strlen(student5) - 7)
*schoolcode
	replace schoolcode = substr(schoolcode, 5, 9)

*Now all of each student's info is in one column, so we will create separate columns for each variable
	split student5, parse(,) //use "comma" as the parser.
*rename variables
	rename student51 kiswahili
	rename student52 english
	rename student53 maarifa
	rename student54 hisabati
	rename student55 science
	rename student56 uraia
	rename student57 average
*drop columns that are no longer needed.
	drop student student1 student2 student3 student4 student5

	local varlist "kiswahili english maarifa hisabati science uraia average"
	foreach subject in `varlist'{
		replace `subject' = usubstr(`subject',-1,1)
	}
tempfile school`i'
save `school`i''

append using psle_student_final_Marine
	
save psle_student_final_Marine, replace
	}

sort schoolcode





*reshape long var, i(schoolcode) j(id)
*drop if student==""
** This takes too long to run, but seems right
