********** Question 2 // Did you manage to add school_id to your dataset? Can't seem to find it in your code. What else were you not able to do? Just leave a comment. And then upload your work. Well done!
// Copied from hint:
global school "/Users/abigailorbe/Library/CloudStorage/Box-Box/Econ490_Fall2022/Week4/04_assignment/data/psle_student_raw.dta"

use "$school", clear

split s, parse(">SUBJECTS") 
split s2, parse("</TD></TR>") gen(var)
gen serial = _n
reshape long var, i(serial) j(j)
split var, parse("</FONT></TD>")
keep var1 var2 var3 var4 var5
drop if var2=="" & var3==""
gen cand_id = substr(var1,-14,.)
gen gender = substr(var3,-1,.)
gen prem_number =  substr(var2,strpos(var2, "CENTER") +8, .)
gen name =  substr(var4,strpos(var4, "<P>") +3 , .)
replace var5 = substr(var5,ustrpos(var5, "LEFT") +6 , .)
replace var5 = substr(var5,1 , strlen(var5) - 7)
split var5, parse(,)
rename var51 kiswahili
rename var52 english
rename var53 maarifa
rename var54 hisabati
rename var55 science
rename var56 uraia
rename var57 average
drop var1 var2 var3 var4 var5 
local varlist "kiswahili english maarifa hisabati science uraia average"
foreach subject in `varlist'{
	replace `subject' = usubstr(`subject',-1,1)
}
// Save
cd "/Users/abigailorbe/Documents/repos/econ490-fall22/Abigail - abigailorbe/Week 4/2_outputs"
save question2
