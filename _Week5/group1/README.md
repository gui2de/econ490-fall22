# Group 1 Week 5 Homework Assignment
## Shaily Acharya, Sylvia Brown, Neel Desai
## Last updated October 9, 2022

## This is a demo change from Office Hours on 10/11/22.

## Overview

This program creates a matrix of one-way ANOVA results and a box plot of the outcome variable over each group variable that was used in the ANOVA test. It is not data-specific; the program is generic and the user can apply any dataset that is built into Stata (i.e., that can be called with `sysuse`).

## Files
This repository includes:

- **one_way_anova.do**: The one-way ANOVA program in a .do file.
- **demonstration.do**: A .do file that demonstrates a variety of uses of the one-way ANOVA program.
- **README.md**: This README file providing documentation of the program.

## Explanation of Program

Below is an explanation of how to run the program.

### Part One: Preparation

Before running the program, make sure that `one_way_anova.do` is saved in a convenient directory. Next, run the `one_way_anova.do` file. You may do this in a number of ways, including by opening and running the .do file or by changing your working directory to the directory where the .do file is stored and running `do one_way_anova` in Stata. Next, you will need to define the inputs to the program. The program accepts three inputs: 1) the name of the built-in data set you would like to use, 2) the variable representing the outcome variable (which must be continuous), and 3) the variable representing the groups you would like to compare the mean of the outcome variable between (which must be categorical).

Note that this program does not test the assumptions necessary for ANOVA; the user should be sure to check that their data satisfies the six ANOVA assumptions. For more information on these assumptions and how to test for them, see [Laerd Statistics's "One-way ANOVA in SPSS Statistics" page](https://statistics.laerd.com/spss-tutorials/one-way-anova-using-spss-statistics.php).

### Part Two: Run the Program

The program will first count the length of the dataset, create a matrix of the elements in the group variable, calculate the number of groups, and append two empty columns to the matrix of group names. The program will then calculate the overall mean of the data, and add the mean and group size to the matrix of group names. Next, the program will calculate sum of squares between (SSB), sum of squares total (SST) and the sum of squared errors (SSE). Finally, the program will calculate the rest of the ANOVA matrix (error, F-statistic, p-statistic, etc.), compile the ANOVA matrix, and generate the box plot.

The program drops observations that have missing values for at least one of the outcome variable or the group variable.

### Part Three: Final Outputs

The program will output the final ANOVA matrix and a box plot of the outcome variable over each group. The results are not stored but appear in the Results portion of the Stata console. Users may save the output by running their own code after running the program.

## Demonstrating the Program

To view a demonstration of how the program runs, run or call the `one_way_anova.do` file, then run or call the `demonstration.do` file. This file will then illustrate a number of uses of the one-way ANOVA program.
