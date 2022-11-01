cap prog drop regcompare
prog def regcompare
	syntax anything
	local y: word 1 of `anything'
	local x1: word 2 of `anything'
	local x2: word 3 of `anything'
	gen `x1'`x2' = `x1'*`x2'
	quietly reg `y' `x1', robust
	estimates store `x1'
	quietly reg `y' `x2', robust
	estimates store `x2'
	quietly reg `y' `x1' `x2', robust
	estimates store multiple
	quietly reg `y' `x1' `x2' `x1'`x2', robust
	estimates store interaction
	estimates table `x1' `x2' multiple interaction, star stats(N r2 r2_a F rmse)
end
