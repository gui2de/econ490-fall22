
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