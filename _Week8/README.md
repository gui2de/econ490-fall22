# Week 8 Homework Assignment

## Outline

This week, instead of working individually, you will work out a homework
assignment with the rest of your group, developing a Stata simulation
and demonstrating its use. It will have three parts to complete, and you
should coordinate with your team about how best to approach the work
using what you know about Stata and Git now. 

## Part 1: Program the simulation framework

The first part of the assignment will be to create a reusable
Stata program to conduct the simulations. Create a new directory with
your group name _inside this directory_ and create a new do-file. This
should be file called `simulate.do`, and, like in Week 5, it will be 
based on the `program` command. The  `simulate.do` file should use Stata
syntax to define an `rclass` program that does the following:

- Clear the data in Stata's memory
- Create new data according to at least one parameter that you determine
  - This can include varying a correlation parameter
  - This should include structures like strata and clusters
  - This should include ID variables
  - This should include at least five characteristic variables of
different types 
- Calculate some kind of statistics over your simulated data
- Use the `return` functionality to create r-class statistics in Stata's
memory 

## Part 2

The second part of the assignment is to use your program within in
iteration loop and extract results from it. Create another do-file
called `results.do`. In this file, you should clear the memory
environment of temporary objects (specifically, matrices), since you
will use these to record the results of simulations. Then, do the
following: 

- Set the working directory
- Set the randomization seed
- Start a loop over a parameter index (such as sample size)
- Start a loop over an arbitrary `i` index
  - You can make this a small number of iterations at first to test that
your program is working, then make it a larger number later on 
- Run your program `i` times, passing the varying parameter index each
time 
- Extract the relevant `return` results into a matrix or temporary
dataset, including the parameter value 
- Export at least one table (as CSV) and at least one graphic (as PNG)
describing the results of your simulation 

## Part 3

The third part is to create documentation for your simulation and a
summary of its results. Create a `README.md` file in your group's
directory, then write an explanation of what your simulation does and
what you have learned from conceiving it, programming it, and studying
its outputs. You should use Markdown formatting to insert the graph
and table into your description of your results where appropriate and to
discuss them in detail. Take your time to explain all the parameters,
the inputs, the data generating process, and the results.  

## Finishing Up

When you are done, create a pull request with your working materials to
the `develop` branch. This week, do not request a review from the group
in general. Instead, request a review from all the members of the group
**before** yours: Group 1 should request the members of Group 5, and so
on (G5 should request G4). You can find the list of group members (and
their github username) in the Excel file at the root of the _Group
Projects folder of the repository. All members should then run the other
group's code and provide feedback on the function, execution, and
documentation, including suggestions for new features or options. The
original group should respond to all suggestions with thoughtful
responses about their viability, and should implement at least one
request from the reviewing group. The reviewing group should then leave
an approving review when they are done (as usual, you do not need to do
a second round of reviews). 
