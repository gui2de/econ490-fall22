----
Title: Group 1 Week 5 Homework Assignment
Authors: Sylvia Brown, Neel Desai, Shaily Acharya
Date: October 9, 2022
Output: one_way_anova.do
----

##Overview

This program creates a matrix of ANOVA results and a box plot of the outcome variable over each group variable that was used in the ANOVA test. It is not data-specific; the program is generic and the user can apply it to their own data. 

##Explanation of program

###Part one: Preparation

Before any calculations are done, you will need to define arguments and load the dataset. Then, the program will count the length of the dataset, create a matrix of the elements in the group variable, calculate the number of groups, and append two empty columns to the matrix of group names. 

###Part two: Calculations

The program will then calculate the overall mean of the data, and add the mean and group size t the matrix of group names. Next, the program will calculate sum of squares between (SSB), sum of squares total (SST) and the sum of squared errors (SSE). To round out the calculations, the program will calculate the rest of the ANOVA matrix (error, F-statistic, p-statistic, et cetera). 

###Part three: Final outputs

The program will assemble the final ANOVA matrix and add column and row names. After displaying the ANOVA results, the program will produce a box plot of the outcome variable over each group. 