********************************************************************************
* Econ 490: Week 11
* ietestfieldkit test of Week 11 Survey
* Sylvia Brown
* Nov 19, 2022
********************************************************************************

clear
global user "/Users/sylviabrown/git/econ490-fall22/Sylvia - sbrown5x/_Week11"
global survey "$user/scb_form.xlsx"

cd "$user"

ietestform using "$survey", reportsave("iefieldtest_report.csv")
