WEEK 8 HW - Group 3

# simulate.do Description

We have defined an rclass program that uses the intracluster correlation coefficient ("ICC") as an input.

To use the program, type [schools, rho(VALUE)] where "VALUE" is the ICC you want to look at.

We then set the number of clusters and generate a way of referring to each cluster.

By generating obs_per_cluster and expanding, we are essentially replacing each cluster observation with "obs_per_cluster" observations. This can be thought of as students within a school (cluster).

Then we generate (student) ids to differentiate the observations in each cluster.

...

We later create a new variable that is the mean of subjects sampled in each cluster.

Then we calculate the design effect.

# results.do Description

results.do loads the schools program defined in simulate.do. 

Then it runs the program with different ICC values, running each 100 times and storing the results in the results matrix.

Then it ... ____

# Notes on the ICC

The intracluster correlation coefficient is a measure of how clustered data are related. Considering this can prevent falsely reporting significance. This is because similarity among the observations in clusters makes it more difficult to detect the true differences between study arms by reducing response variability. The ICC measures this similarity.

ICC, along with cluster size and number of clusters, can be ued to calculate "effective sample size" in a clustered design. 

Note that accounting for similarities among clustered subjects usually results in power loss. Then, more subjects are required.

Also note that u is a 'cluster-level intercept' and e represents the residual.

# Design effect

The design effect adjusts the required sample size for cluster sampling to make up for info lost from the clustered design.

A larger ICC often means a larger design effect, so the sample size would have to increase.

Similarly, large cluster sizes can have significant effects.