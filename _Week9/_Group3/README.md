# Group 3

## Explanation of program
`schoolpower.do`

This program takes two parameters: rho, the intracluster (intraschool) correlation of student test scores, and the true effect of the universal school lunch program on student test scores. These two parameters determine the data-generating process for the test scores.

All in all, this program produces a simulated dataset of test scores, treatment status, free/reduced-price lunch eligibility, and other variables that would be collected as part of our study. Then, it regresses test scores on treatment status, clustering standard errors by school. Users can choose the "biased" option which excludes free/reduced-price lunch eligibility from the regression. We know that free/reduced-price lunch eligibility directly impacts test scores because it is part of the data-generating process for test scores (students who are ineligible for NSLP and thus are of higher socioeconomic status have higher test scores in our simulated data).

Finally, the program saves the regression table and the p-value for the treatment status dummy.

## Results
`power-calculations.do`

This dofile runs the program above, looping through different true effect size values and intracluster correlation coefficients and iterating the regression 50 times per combination of effect size and rho. The loop outputs a results matrix with the true effect size, intracluster correlation, p-value, and estimated treatment effect. We determine if the p-value will be rejected by comparing it to the alpha value 0.05. Then, we tabulate the percentage of iterations in each combination of rho and true effect size in which the null hypothesis is correctly rejected. 

We find that our sample of 200 elementary schools with an average of 75 fourth graders per school will be adequately large to detect an effect on test scores of 3 points or more.