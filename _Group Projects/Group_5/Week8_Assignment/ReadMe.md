# Week 8 - Group 5 - Simulating data for our charter school experiment in which we study whether attending a charter school leads to better student performance compared to public schools.

# Date: October 30, 2022

# Overview of charter_simulation 

# We define an r-class program which first of all generates an ID variable for each student.

# We set our observations at 5000, which is the number of applicants to PK3 lottery each year

# We generate a variable to define child ability (IQ) which is normally distributed with a mean of 100 and sd of 15, per the scaling of the Wechsler Intelligence Scale for Children

# We generate 135 charter school IDs and proceed under the assumption that each child randomly applies to one

# We cap school capacity at 30

# We generate a variable indicating the quality of public schools, which is a made-up score with a mean of 100 and an sd of 15

# Similarly, we generate one for charter schools where mean is one SD above that of public quality distribution; we make this assumption because our literature review shows charters tend to produce higher test scores 

# We generate a loop that counts the number of kids applying to charter per row and replaces applicants with the number of kids applying to the same charter

# The oversubscribed variable is binary, whereby 0=there are spots available, 1 = no spots left

# We proceed to set up our lottery mechanism: we assign each kid who applied to an oversubbed school a random number and  then rank them. If the child's rank is below or equal to total capacity (capped at 30), then the child will take the value 1 in the "admitted " variable; otherwise 0

# We generate test scores in charter and public schools using the Cobb-Douglas education production function, where a = 0.5; we chose the number based on the education production function used by Polachek, Kniesner, and Harwood (1978) in the Journal of Educational Statistics

# We use this to determine whether the child will choose to attend charter or public school 

# We finally perform an instrumental variable regression where admitted is the instrument, attend is the endogenous variable, and ts_actual is our dependent variable and extract the coefficients

# We generate a beta-hat variable indicating mean predicted change in the child's test score from attending charter, relative to if the child had attended public school

# We generate a beta variable indicating mean actual change in the child's test score from attending charter, relative to if the child had attended public" 

# Scalars returned and stored as locals

# We proceed to the results file 