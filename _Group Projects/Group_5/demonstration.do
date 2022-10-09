clear

global wd "/Users/miglepetrauskaite/Desktop/GITHUB/Repo/econ490-fall22/_Group Projects/Group_5"

do "$wd/program.do"

// demonstrating the use: regressing wage and age
group5 ln_wage age

// demonstrating  the use: regressing wage and belonging to a union
group5 ln_wage union

// another use:
group5 ln_wage nev
