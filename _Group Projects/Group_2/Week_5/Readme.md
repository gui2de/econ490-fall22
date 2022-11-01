Please change the working directory to the file path that goes to the Box folder on your own computer when running the demonstration do file

This program will help you determine if you should run a linear regression model on your dataset, as well as let you know of any outliers.


After you loaded the dataset, the syntax is 

 . myprogram dep_var ind_var_1 ... ind_var n

Where the dep_var is your variable of interest for the potential regression and all ind_var_k variables are independent variables that might have outliers.

The program first drops any string variables and identifies the dependent variable as the first variable you entered.

Next, it generates a covariance matrix, which is useful to assess collinearity issues, and then it regresses the dependent variable on each non-string variable in the dataset in order to construct the error plots - which are saved under varname.gph

This is useful to check if the errors of a regression are normally distributed for each covariate, as this is one of the assumptions of the linear regression model. If errors are not normally distributed for a given covariate, it means a linear regression will not be the most adequate method to estimate its relationship with the dependent variable. 

Finally, the program runs the proposed regression and produces a histogram showcasing the distribution of studentized residuals and shows which values are outliers - defined as those values that have an absolute t-statistic greater than two. For more information on studentized residuals, please refer to this link (https://online.stat.psu.edu/stat462/node/247/). 


Please note that the folder has one txt file (Readme), two do-files (program.do and demonstration.do), n scatterplots, and k histograms. Here n stands for the number of variables in the dataset and k stands for the number of regressions run in the demonstration do-file