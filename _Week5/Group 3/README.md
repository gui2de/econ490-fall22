# Title
**regcompare** comparing linear regression models

# Description
**regcompare** compares four specifications of ordinary least squares regressions given one dependent variable and two independent variables. 

First, it specifies a simple linear model with the dependent variable and first predictor listed. Second, it specifies a simple linear model with the dependent variable and second predictor listed. Third, it specifies a multiple regression model with the dependent variable and both listed predictors. Finally, it specifies a multiple regression model with the dependent variable, both listed predictors, and an interaction term between the two predictor variables. **regcompare** summarizes these four models by reporting the regression coeffiencients and their significance as well as the model's number of observations, R-squared, adjusted R-squared, and root mean squared error.

# Syntax
regress depvar indepvar1 indepvar2

# Example
We have health record data containing a patient's identification number, age group (agegrp), sex (sex), and blood pressure reading (bp) before and after treatment. Suppose we are interested in how blood pressure levels are influenced by sex and age but are unsure as to the best model specification. We can use **regcompare** to compare four specifications and guide our model development:

sysuse bplong.dta, clear
regcompare bp sex agegrp

This outputs a summary table with a column for each of the models: sex (a simple regression of bp on sex), agegrp (a simple regression of bp on agegrp), multiple (a multiple regression of bp on sex and agegrp), and interaction (a multiple regression of bp on sex, agegrp, and sex*agegrp).

From the results, we can see that both simple regression models produce significant coefficients on their respective regressors, but with small R-squared values.

In the multiple regression model without an interaction term, both coefficients are significant, and the R-squared and F-statistics are substantial.

In the multiple regression model with an interaction term, only the age group variable is significant, though the R-squared and F-statistics are both substantial.

These results are valuable in selecting a final model. Depending on our research goal, our ultimate specification may be different, but **regcompare** provides important information in order to make an informed model decision.

# Additional Notes
The number of observations column can be helpful in understanding which variables have missing values and how a multiple regression specification affects sample size.

The four models are saved in the session memory, so additional tests such as likelihood-ratio tests (**lrtest**) can be run to further compare model specifications.