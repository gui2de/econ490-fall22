// Use case 1 - Fegor
sysuse lifeexp.dta, clear
regcompare lexp gnppc popgrowth

*This summary table shows the regression comparison of life expentancy using GNP per capita and population growth as regressors. The gnppc variable is statistically significant as well as the multiple regression with population growth. The interaction term with pop. growth is also significant. This shows that gnppc and population growth of a country are separate important factors of life expentancy. 


// Use case 2 - Antonio

// Use case 3 - Abigail
sysuse bplong.dta, clear
regcompare bp sex agegrp

** Based on the summar table, we find that the mutiple regression model may have the
	* best fit for this data. The coefficients are both significant, and the 
	* R-squared values and F-statistic indicate that the multiple regression
	* model may explain more of the variation in blood pressure levels than
	* the other models. This model indicates that sex and age are both
	* important factors for blood pressure levels, but their interaction may not
	* be as important.
	
