# Group 1, Week 8 Assignment
# Shaily Acharya, Sylvia Brown, Neel Desai


## Overview

Our simulation exercise simulates a sample dataset that can be used to estimate an individual's salary based on a variety of characteristics. In the sample model, the determinants of salary are GPA, undergraduate major, state in which their university is located, and university attended. Ultimately, the main outputs are 3 graphs that depict key characteristics of the dataset,  with the main graph depicting the number off clusters versus standard terror of the effect of GPA on salary. These graphs, along with a .csv file of the dataset, are included in this document. 

## simulate.do

The simulation do file defines the variables and the data generating processes that are behind our main output. 

The parameter that we vary is the number of strata in our sample. In this case, the number of strata corresponds to the number of states that we are sampling from.  We generate the state-level fixed effects using a chi squared distribution— the rationale behind this is purely because we wanted to practice using a variety of different distributions in the randomization processes of our assignment. Then, we uniformly randomize the number of universities within each state, and generate the university-level fixed effects using a normal distribution. Lastly, we uniformly randomize the number of students per university.

Once we define the relevant strata and fixed effects of our analysis, we continue on to generate the individual characteristics of the students. We generate variables for the parents' level of education (uniformly randomized), SAT score (randomized using a normal distribution), and AP credit (randomized using a Poisson distribution). Then, in order to generate the GPA variable that gets put in the regression for salary later in the program, we use the characteristics discussed above as well as a normally distributed randomization term. In order to generate university major-fixed effects, which also gets put into the regression for salary, we use uniform randomization. We define a local which represents the true coefficient on GPA, which we set as 5000. With these inputs, we then create the generative model for post-graduate salary on line 66, which is our main DGP. 

From line 69 to line 84, we are generating categorical variables based on the salary variable and the parents' education variables. In the next section off code, we add an individual ID variable which is a concatenation of the state, university, and student variables with a leading 0. By defining the individual ID in this way, the variable tells us identifying information about each individual, which is more useful than simple generating a randomized individual ID variable. 

Lastly, we run the regression of salary on GPA, undergraduate major, state in which their university is located, and university attended, in order to re-estimate the coefficient on GPA. The program ends by returning the beta coefficient and standard error on GPA, as well as the total sample size. 


## results.do

In the results do file, we run an example of this program in practice. We create a loop over the parameter index (number of state strata we sampled from). We then create a nested loop within the parameter loop in order to set the number of samples we draw. In this case, the outer loop indicates that we loop over 20 states, and the inner loop indicates that we will draw 5 samples. In the first iteration of the outer loop, 5 samples will be drawn from 1 state; in the 10th iteration. Of the outer loop, 5 samples will be drawn from a collection of 10 states (thus, the number of strata used to pull the samples is cumulative). 

We then save the results of the program in a matrix including columns for the number of states (clusters), the number of the sample (number_run), sample size, beta coefficient for GPA, and standard error for GPA. The csv of our final dataset is below:

[Results CSV](demonstration_results.csv)

We also generate three scatterplots. The first graph shows the number of clusters versus the sample size,  which obviously has a strong positive, linear correlation. The second graph shows the number of clusters versus the effect of GPA on salary, which appears to follow a somewhat normal distribution. This scatterplot varies a lot each time the program is run, and we suspect it is because we introduce randomness various times throughout the DGP, which could distort the true relationship between these two variables. Lastly, we have a scatterplot of the number of clusters versus the standard error of the GPA variable. We can see that as the number of clusters (states) drawn from decreases, the standard error increases, which is in line with our predictions. The scatterplots are below: 

![Final Scatterplots](salary_scatter.png)
