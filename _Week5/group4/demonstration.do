global username "/Users/geenapanzitta/Documents/GitHub/econ490-fall22" //EDIT THIS
// edit the above with your file path to run the program

cd "${username}_Week5/group4"
//calls the working directory

clear all 
run program.do

//runs the program with different data sets

graphsum auto price mpg

graphsum census death divorce

graphsum surface latitude temperature
