# Week 9 Homework Assignment

## Outline

This week, instead of working individually (again), you will work out a homework
assignment with the rest of your group, developing another Stata simulation
and demonstrating its use. It will have three parts to complete, and you
should coordinate with your team about how best to approach the work
using what you know about Stata and Git now.
This time, the simulation task is intended to advance your group project, and the results from this assignment should be included in your final group project submission.
Specifically, the task is to simulate something like the actual dataset that you would expect to collect or obtain for your proposed project, and to investigate the statistical power of your proposed analysis. We do not expect you to do any advanced mathematics or econometrics -- simple linear regression (OLS) will do!
We do, however, expect you to show how OLS estimation would be biased in at least one case; and we expect you to provide a reasonable assessment of either the variance or required sample size for your key question based on the structure of the data (for example, clusters and strata).

## Part 1: Program the simulation framework

The first part of the assignment will be -- as usual -- to create a reusable
Stata program as the basis for your simulations. Create a new directory with
your group name _inside this directory_ and create a new do-file. This
should be file called `estimation.do`, and, like in Week 5 and Week 8, it will be
based on the `program` command. The  `estimation.do` file should use Stata
syntax to define an `rclass` program that does the following:

- Clear the data in Stata's memory
- Create new data that corresponds to the structure, sample size, and treatment/randomization or other parameter of interest in your proposed experiment
- Includes a _true effect size_ parameter that you are trying to estimate
- Includes an _option_ called `biased` that allows you to produce a **biased** estimate
- Use the `return` functionality to create r-class statistics in Stata's
memory

## Part 2

The second part of the assignment is to use your program within in
iteration loop and extract results from it. Create another do-file
called `power-calculations.do`. In this file, you should clear the memory
environment of temporary objects (specifically, matrices), since you
will use these to record the results of simulations. Then, do the
following:

- Set the working directory
- Set the randomization seed
- Start a loop as required for your simulation
- Extract the relevant `return` results into a matrix or temporary
dataset, including the parameter value
- Calculate either the minimum sample size or the minimum detectable effect for the unbiased version of your experiment
- Demonstrate the bias of your experiment in the biased version
- Export at least one table (as CSV) and at least one graphic (as PNG)
describing the results of your simulation (and be prepared to expand on this in your final project)

## Part 3

The third part is to create documentation for your simulation and a
summary of its results. Create a `README.md` file in your group's
directory, then write an explanation of what your simulation does and
what you have learned from conceiving it, programming it, and studying
its outputs. You should use Markdown formatting to insert the graph
and table into your description of your results where appropriate and to
discuss them in detail. Take your time to explain all the parameters,
the inputs, the data generating process, and the results.

In particular, you should carefully explain the source of the bias in your biased simulation.
Think carefully about the microdata structures that might disrupt your study when implementing and explaining this simulation and its results!

## Finishing Up

When you are done, create a pull request with your working materials to
the `main` branch. Again, do not request a review from the group
in general. Instead, create a draft pull request and then request a review from all the members of the group
**two after** yours:

- Group 1 requests Group 3
- Group 2 requests Group 4
- Group 3 requests Group 5
- Group 4 requests group 1
- Group 5 requests Group 2

You can find the list of group members (and
their github username) in the Excel file at the root of the _Group
Projects folder of the repository. All members should then run the other
group's code and provide feedback on the simulation structure, execution, and
documentation, including comments on the biased estimator. The
original group should respond to all suggestions with thoughtful
responses about their viability, and should implement at least one
request from the reviewing group. As usual, you do not need to do
a second round of reviews; remove the draft status on the PR and we will merge it into `main`.
