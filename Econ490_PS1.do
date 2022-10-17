*Week 4 Assignment
*Oghenefegor Omorojor

cd "/Users/user/Box Sync/Week4/04_assignment/data"

global wd  "/Users/user/Box Sync"

use "$wd/Week4/04_assignment/data/village_pixel", clear

summarize

describe

*Question 1a
sort payout pixel
by payout (pixel), sort: gen pixel_consistent = payout[1] != payout[_N]



*Question 1b
* convert pixel variable to categorical variable + inspect categories
encode pixel, generate(pixel_n)
tab pixel_n, nolabel
* creating the dummy
bysort village: egen mode_pixel = mode(pixel_n), maxmode
gen pixel_household = 0
replace pixel_household = 1 if mode_pixel != pixel_n
bysort village: egen pixel_village = mean(pixel_household)
replace pixel_village = 1 if pixel_village > 0
tab pixel_village
* Identifying village names
gen household1 if mode_pixel = 1


*Question 1c
gen household2 if mode_pixel != 1 | pixel_consistent = 0
gen household3 if mode_pixel != 1 | pixel_consistent = 1


*Question 2
clear
set obs 1  //we need just 1 row to import the dataset
gen s = fileread("https://onlinesys.necta.go.tz/results/2021/psle/results/shl_ps0101114.htm") //scrape data from the webpage

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
	replace `subject' = usubstr(`subject',-3,.)
	
	
	
}

*Identify school code
global wd  "/Users/user/Box Sync"

use "$wd/Week4/04_assignment/data/psle_student_raw", clear


*Question 3
global excel_t21 "/Users/user/Box Sync/Week4/04_assignment/data/Pakistan_district_table21.xlsx"
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
