[R] group5 - user program

SYNTRAX

group5 [depvar] [indepvar]

OVERVIEW

Our folder contains two .do files: program.do and demonstration.do. The former is the code for the user-created program group5. The latter demonstrates example uses of the group5 program. The user must specify the dynamic file path to use the demonstration.do file, per the assignment instructions.

The program group5 loads a default data set called nlswork. This is the National Longitudinal Survey of Young Working Women, which is a time series from 1968 to 1988 of of 4,711 women. The data set contains both numeric and string variables. The group5 program only accepts only numeric variables.

Upon specifying two numeric variables in nlswork, the program group5 performs a regression and exports the results in a .docx file. The results in the .docx file have an identical format to the regress command in the Stata window.

By default, the regress command drops observations with missing variables. Because the group5 program is built on regress, it does the same.

EXAMPLE

If the user sought to regress the natural log of wage on age, the user would enter:

group5 ln_wage age