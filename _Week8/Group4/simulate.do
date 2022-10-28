cap prog drop income_sim

prog define income_sim, rclass

clear

syntax anything
set obs `anything'

gen state = 1+mod(_n,10)
sort state
gen id = _n
gen age = rnormal(35,5)
drop if age < 18
gen educ_yrs = trunc(rnormal(12+(state/2),1))
drop if educ_yrs < 0
gen dist_from_city = rnormal(25-state,5)
drop if dist_from_city < 0
gen family_size = trunc(rnormal(4,1))
drop if family_size < 1
gen experience = runiform(0,age-18)

gen income_k = 2*experience + .5*age + (-.3)*dist_from_city + 1*family_size + 1.5*educ_yrs + rnormal(0,4)

reg income_k age educ_yrs dist_from_city family_size experience, cluster(state)

local b_age = _b[age]
local b_educ_yrs = _b[educ_yrs]
local b_dist_from_city = _b[dist_from_city]
local b_family_size = _b[family_size]
local b_experience = _b[experience]

return scalar b_age = `b_age'
return scalar b_educ_yrs = `b_educ_yrs'
return scalar b_dist_from_city = `b_dist_from_city'
return scalar b_family_size = `b_family_size'
return scalar b_experience = `b_experience'


end
