# Week 5 Homework Assignment

## Outline

This week, instead of working individually, you will work out a homework assignment
with the rest of your group, developing a simple Stata program and demonstrating its use.
It will have three parts to complete, and you should coordinate with your team
about how best to approach the work using what you know about Stata and Git now.

## Part 1

The first part of the assignment will be to create a simple, reusable Stata program.
Create a new directory with your group name and create a new do-file.
This should be file called `program.do`  based on the `program` command.
The program can have any name you want and do anything you like,
but it must take flexible inputs and create a standardized output.
For example, you could create a program that takes a list of variables
and outputs standard diagnostics for them,
or a program that produces a standardized graph format based on some specifications,
or a program that produces regression or summary statistics tables.

## Part 2

The second part of the assignment is to demonstrate the use of your program!
You should create a do-file called `demonstration.do`.
First, you must set a dynamic folder path using a global macro and clear the environment.
Second, you should run your `program.do` file to load the program into memory.
Third, you should demonstrate several use cases for your program
and save any outputs into the same folder.
You should use one of the built-in datasets (type `sysuse dir` for a list).

## Part 3

The third part is to create documentation for your command.
Create a `README.md` file in your group's directory,
then write an explanation of how to use your command and what the user should expect.
Look at other Stata help files for examples of this type of documentation.
You do not need to match the format exactly, but Markdown has a variety of
simple formatting tools that will allow you to get the point across.
Feel free to include links or screenshots as necessary, but focus on writing well.

## Finishing Up

When you are done, create a pull request with your working materials to the `develop` branch.
This week, do not request a review from the group in general.
Instead, request a review from all the members of the group after yours:
Group 1 should request the members of Group 2, and so on (G5 should request G1).
All members should then run the other group's code and provide feedback
on the function, execution, and documentation, including suggestions for new features or options.
The original group should respond to all suggestions with thoughtful responses about their viability,
and should implement at least one request from the reviewing group.
The reviewing group should then leave an approving review when they are done
(as usual, you do not need to do a second round of reviews).
