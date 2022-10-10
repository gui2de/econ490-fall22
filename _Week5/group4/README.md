# Week 5 Homework Assignment, Group 4: `graphsum`

## Overview

`graphsum` creates basic graphs and summary statistics for two variables in a system dataset. It takes in 3 inputs—`sysdata`, `var1`, and `var2`—and outputs 4 graphs and 3 matrices. It loads the system data called ``sysdata’.dta` and it creates a scatter plot with a fitted line where `var1` is the dependent variable and `var2` is the independent variable, a histogram of `var1`, a histogram of `var2`, and a combined graph with both histograms side by side. The graphs are stored in the working directory. It also produces summary statistics for `var1` and `var2` and stores them in matrices, and it runs a robust regression of `var1` on `var2` and stores the coefficient matrix.

## Using the Program
Run `graphsum sysdata var1 var2`, replacing `sysdata` with the name of the system data (i.e. auto), `var1` with the dependent variable (i.e. price), and `var2` with the independent variable (i.e. mpg).

## Graphs and Matrices
The scatter plot with a fitted line is saved as `sysdata_scatter_var1_var2.gph`.
The histogram of `var1` is saved as `sysdata_hist_var1.gph`.
The histogram of `var2` is saved as `sysdata_hist_var2.gph`.
The combined histogram graph is saved as `sysdata_hist_var1_var2.gph`.

The matrices are stored as `sysdata_summary` and `sysdata_reg_results`.
