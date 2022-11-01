cap prog drop schools
prog def schools, rclass
	syntax, rho(real) // input is intracluster correlation
	
	clear all
	
	set obs 200 // 200 clusters
	gen cluster_num = _n
	gen obs_per_cluster = 75 + 10*runiform() // randomizing number of observations per cluster (school)
	expand obs_per_cluster
	by cluster_num, sort: gen id = _n
	
	// generating actual intracluster correlation in the data
		// assuming total variance = 1
		local sd_u = sqrt(`rho')
		local sd_e = sqrt(1-`rho')
		
		// sampling u and e
		by cluster_num (id), sort: gen u = rnormal(0, `sd_u') if _n == 1
		by cluster_num (id): replace u = u[1]
		gen e = rnormal(0, `sd_e')
		gen y = u + e
		mixed y || cluster_num:
		quietly estat icc
		scalar icc = r(icc2) // icc in the data
	
	// estimating design effect
	egen g = mean obs_per_cluster // average cluster size
	scalar design = sqrt(1+icc*(g-1)) // design effect -- larger design effect means a larger minimal detectable effect
end