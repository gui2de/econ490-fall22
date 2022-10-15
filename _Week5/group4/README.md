# Week 5 Homework Assignment, Group 4: `graphsum`

## Overview

`graphsum` creates basic graphs and summary statistics for two numeric variables in a system dataset. It takes in 3 inputs—`sysdata`, `var1`, and `var2`—and outputs 4 graphs and 3 matrices. It loads the system data called ``sysdata’.dta` and it creates a scatter plot with a fitted line where `var1` is the dependent variable and `var2` is the independent variable, a histogram of `var1`, a histogram of `var2`, and a combined graph with both histograms side by side. The graphs are stored in the working directory. It also produces summary statistics for `var1` and `var2` and stores them in matrices, and it runs a robust regression of `var1` on `var2` and stores the coefficient matrix.

## Setup
Set your working directory such that it contains the program.do file. Then in the command line, input:

run program.do

## Using the Program
Run `graphsum sysdata var1 var2`, replacing `sysdata` with the name of the system data (use the command: "sysuse dir" to browse applicable datasets), `var1` with the dependent variable, and `var2` with the independent variable. `var1` and `var2` should be numerical or encoded categorical variables.

## Graphs and Matrices
The scatter plot with a fitted line is saved as `sysdata_scatter_var1_var2.gph`.
The histogram of `var1` is saved as `sysdata_hist_var1.gph`.
The histogram of `var2` is saved as `sysdata_hist_var2.gph`.
The combined histogram graph is saved as `sysdata_hist_var1_var2.gph`.

The matrices are stored as `sysdata_summary` and `sysdata_reg_var1_var2_results`. They can be viewed using the matlist command.

## Example

graphsum auto price mpg

Four graphs are saved to the working directory: a scatter plot with a fitted line named "auto_scatter_price_mpg.gph", histograms of the two variables named "auto_hist_price.gph" and "auto_hist_mpg.gph", and the combined histograms in a file named "auto_hist_price_mpg.gph". Two matrices are stored in memory. The matrix names are "auto_summary" and "auto_reg_price_mpg_results".
