

global wd "/Users/benjamintu/Downloads/Econ490_Fall2022/Week4/04_assignment/data"

use "$wd/village_pixel.dta", clear

* Q1 a)
egen pixel_mean = mean(payout),by(pixel) //calculate the mean for each different pixel.

gen pixel_consistent = 0 if pixel_mean== 0 | pixel_mean ==1    // pixel is consistent if the mean is an integer.

replace pixel_consistent = 1 if pixel_mean!= 0 & pixel_mean!= 1 // if the mean is not an integer, pixel is not consistent

* b)
/*
why the value changes when I try to destring?
gen nu_pixel = substr(pixel,3,4)
destring (nu_pixel), replace
egen nu_pixel_mean = mean(nu_pixel),by(village)
*/

sort village

egen tag_pixel_village = tag(village pixel) 

egen tag_pixel_village_mean = sum(tag_pixel_village),by(village)

gen pixel_village=0 if  tag_pixel_village_mean == 1

replace pixel_village=1 if tag_pixel_village_mean >1

* c)
gen village_categories=1 if pixel_village==0 

replace village_categories=2 if pixel_village==1 & pixel_consistent==0

replace village_categories=3 if pixel_village==1 & pixel_consistent==1

tab hhid if village_categories==2

*Q2
use "$wd/psle_student_raw.dta", clear

	levelsof schoolcode, local (list) // assign a number to each school
	local n = 0 
	foreach i of local list {
		local n = `n' + 1 
		use "$wd/psle_student_raw.dta", clear
		keep if schoolcode == "`i'"

		*Above mentioned parts are not relevant as you already have the webscraped info in the dataset.

		split s, parse(">SUBJECTS") //we need to get rid of part before "Subject", I figured this out by eyeballing the data

		*right now all the data is in the same row,Objective: each row is a unique student

		*Identify any pattern => new line
		*eyeball the data/website. There's a new line after subject grades. 
		*Failry certain "</TD></TR>" is where a new line starts.
		split s2, parse("</TD></TR>") gen(var) //
		*Still every student info is in the same row,we can get to 1 row = 1 student info
		*by using reshape command

		gen serial = _n
		reshape long var, i(serial) j(j)
		split var, parse("</FONT></TD>")
		*keep only the relevant variables
		keep var1 var2 var3 var4 var5

		*dropping first and last rows as they are empty
		drop if var2=="" & var3==""


		*candidate ID variable
		gen cand_id = substr(var1,-14,.)

		*gender
		gen gender = substr(var3,-1,.)


		*Prem Number
		gen prem_number =  substr(var2,strpos(var2, "CENTER") +8, .)

		*Name
		gen name =  substr(var4,strpos(var4, "<P>") +3 , .)

		*grades
		replace var5 = substr(var5,ustrpos(var5, "LEFT") +6 , .)
		replace var5 = substr(var5,1 , strlen(var5) - 7)

		*all the subject info is in one columns, create separate columns
		split var5, parse(,) //use "comma" as the parser.
		*rename variables
		rename var51 kiswahili
		rename var52 english
		rename var53 maarifa
		rename var54 hisabati
		rename var55 science
		rename var56 uraia
		rename var57 average

		*drop columns that are no longer needed.
		drop var1 var2 var3 var4 var5 

		*extract just the greade
		local varlist "kiswahili english maarifa hisabati science uraia average"
		foreach subject in `varlist'{
			replace `subject' = usubstr(`subject',-1,1)
		}
		
		// generate variable for schoolcode
		local y = "`i'" 
		gen schoolcode = "`y'"
		order schoolcode
		
		if `i' == 1 {
			tempfile one
			save `one', replace
		}
		else {
			append using `one'
			save `one', replace
		}
		
		
		
	}

Q3
global excel_t21 "$wd/Pakistan_district_table21.xlsx"
*update the global

clear
*setting up an empty tempfile
tempfile table21
save `table21', replace emptyok

*Run a loop through all the excel sheets (135) this will take 2-10 mins because it has to import all 135 sheets, one by one
forvalues i=1/135 {
	import excel "$excel_t21", sheet("Table `i'") firstrow clear allstring //import
	display as error `i' //display the loop number

	keep if regex(TABLE21PAKISTANICITIZEN1, "18 AND" )==1 //keep only those rows that have "18 AND"
	*I'm using regex because the following code won't work if there are any trailing/leading blanks
	*keep if TABLE21PAKISTANICITIZEN1== "18 AND" 
	keep in 1 //there are 3 of them, but we want the first one
	rename TABLE21PAKISTANICITIZEN1 table21

	gen table=`i' //to keep track of the sheet we imported the data from
	append using `table21' //adding the rows to the tempfile
	save `table21', replace //saving the tempfile so that we don't lose any data
}
*load the tempfile
use `table21', clear
*fix column width issue so that it's easy to eyeball the data
format %40s table21 B C D E F G H I J K L M N O P Q R S T U V W X Y  Z AA AB AC

//get rid of non-numeric values
foreach var in B C D E F G H I J K L M N O P Q R S T U V W X Y Z AA AB AC {
 	destring `var' , gen (numeric`var') force
	drop `var'
}

Q4
use "$wd/grant_prop_review_2022.dta", clear

//rename variables due to typo
rename Rewiewer1 Reviewer1
rename Review1Score Score1
rename Reviewer2Score Score2
rename Reviewer3Score Score3

//calculate the average score
gen ave_score = (Score1+Score2+Score3)/3

//sort value in a descending way
gsort -ave_score

// get ranking
gen rank = _n








