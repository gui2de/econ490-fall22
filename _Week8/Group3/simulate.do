// drop any program called 'schools'
cap prog drop schools

// new program schools will store results in r()
prog def schools, rclass
	syntax, rho(real) // input is intracluster correlation coefficient
	
	clear all
	
	set obs 200 // 200 clusters
	gen cluster_num = _n // to refer to each cluster
	gen obs_per_cluster = 75 + 10*runiform() // randomizing number of observations per cluster (school)
	expand obs_per_cluster // replace each cluster obs with "obs_per_cluster" many copies
	by cluster_num, sort: gen id = _n // assign ids to differentiate observations in each cluster 
	
	// generating actual intracluster correlation in the data
		// assuming total variance = 1
		local sd_u = sqrt(`rho') // u represents standard dev between clusters
		local sd_e = sqrt(1-`rho') // e is standard dev within clusters
		
		// sampling u and e
		by cluster_num (id), sort: gen u = rnormal(0, `sd_u') if _n == 1
		by cluster_num (id): replace u = u[1] // st dev between clusters is same for all
		gen e = rnormal(0, `sd_e')
		gen y = u + e
		mixed y || cluster_num:
		quietly estat icc
		scalar icc = r(icc2) // icc in the data
	
	// estimating design effect
	egen g = mean(obs_per_cluster) // average cluster size // note: mean() adds g to data set
	scalar design = sqrt(1+icc*(g-1)) // design effect -- larger design effect means a larger minimal detectable effect
end