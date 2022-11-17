***
***
* Econ 490: Week 4
* Antonio Marine
* due October 3, 2022
***
***

*****
*Problem 1.


cd "C:\Users\anton\Box\Econ490_Fall2022\Week4\04_assignment\data"

use village_pixel.dta, clear

describe

codebook

*****
*1a 
* Payout var should be consistent within a pixel
* Create a new dummy var (pixel_consistent), where var =1 if payout variable is NOT consistent within that pixel (i.e., =0 when all payouts are exactly the same, =1 if there is even a SINGLE different payout in the pixel)


tab pixel payout
* It is obvious that the payout var is consistent by pixel...
* But we can generate pixel_consistent using an if statement anyways.

* If payout values are the same within a pixel, then when we sort by pixel, and then by payout within each pixel, the first value and last payout will only be the same if all values of payout are the same.
bysort pixel (payout): gen pixel_consistent = 0 if payout[1] == payout[_N]

* If the first and last values of payout were different (i.e., inconsistent payout var), it would have a missing pixel_consistent value
replace pixel_consistent = 1 if missing(pixel_consistent)

tab pixel pixel_consistent

count if pixel_consistent != 0
* Once again it is clear that the payout var is consistent within each pixel since pixel_consistent is always 0.

***
*1b
* Usually households in each village are also in the same pixel, but it's possible that some villages are in multiple pixels
* Create a dummy (pixel_village) =0 for the entire village when all households from the village are within a particular pixel,
* =1 if households from a particular village are in multiple pixels.


* We can generate this dummy just as we generated the dummy from Q1a.
bysort village (pixel): gen pixel_village = 0 if pixel[1] == pixel[_N]

replace pixel_village = 1 if missing(pixel_village)

tab village pixel_village

***
*1c
* Only an issue if villages are in different pixels AND have different payout status, so we make three categories:
* villages that are entirely in a particular pixel (==1)
* villages in different pixels AND have same payout status ('create a list of all hhids in such villages') (==2)
* villages in different pixels AND have different payout status (==3)
* "hint:" 3 categories are mutually exclusive and exhaustive


* First we create a variable "village_consistent" that indicates whether payouts are consistent within a village (=0 if consistent, =1 if inconsistent)
bysort village (payout): gen village_consistent = 0 if payout[1] == payout[_N]

replace village_consistent = 1 if missing(village_consistent)

tab village village_consistent

count if village_consistent != 0
* It is apparent that some villages have inconsistent payout values 

* Now we generate a variable "vil_pix_pay" that indicates whether villages are entirely in one pixel (=1), in different pixels and same payout (=2), and in different pixels with inconsistent payout status (=3).

* pixel_village == 0 indicates that all the households from a village are within one pixel
gen vil_pix_pay = 1 if pixel_village == 0

* similarly, pixel_village == 1 indicates that that a village has households in multiple pixels; village_consistent == 0 indicates that payouts are consistent, == 1 means inconsistent payouts
replace vil_pix_pay = 2 if pixel_village == 1 & village_consistent == 0

replace vil_pix_pay = 3 if pixel_village == 1 & village_consistent == 1


* Finally we list all hhids in villages with households in different pixels but with the same payout status (vil_pix_pay == 2)

list hhid if vil_pix_pay == 2



