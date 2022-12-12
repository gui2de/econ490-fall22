Survey in Google Drive: https://docs.google.com/spreadsheets/d/1fqEk9A0csNlsbbqakaz4w96p1dPLc02MlecEi68MLIM/edit?usp=sharing

Survey fill-out link (SurveyCTO): https://gui2de.surveycto.com/forms/am_week11/designer.html?view=test&caseid=

My survey seeks to explore what changes to the Washington metropolitan area's public transit systems might affect how people with personal vehicles travel. Perhaps the travel habits of the personal vehicle users are shaped by their disappointment with the current system, so they would potentially drive less or even give up their vehicle if the system were improved.

Thus, I have restricted the survey to people who 
1) have a personal vehicle
2) live in D.C., Maryland, or Virginia
3) are at least 18 years old (and less than 150, to prevent typos from affecting the responses).

After getting consent, the first sections determine respondents' eligibility to take the survey and extract demographics information.

Then, we gather information about respondents' travel habits by asking where they travel on at least a monthly basis, how often they travel there, how often they do so alone using their personal vehicle, and what other ways they travel to each destination.

	Notably, when we ask how often respondents travel alone to each destination using their personal vehicle, we first remind them that driving alone is an extremely prevalent form of traveling. By loading the question like this, we hopefully prevent respondents from downplaying how often they travel alone. Respondents could reasonably feel pressured to lie about this since the survey seeks to promote transit use.

Then, we ask how certain improvements or policy changes might affect respondents' tendency to ride the bus or rail, and whether some combination of changes could actually cause them to get rid of their vehicle. Before doing so, we include a "cheap talk script" that seeks to reduce hypothetical bias. We do so by noting how people often overstate how hypothetical policies would affect them and asking respondents to answer as if they were making a real choice. We also remind them that riding transit more could mean (although not necessarily imply) that they would drive their vehicle less.

Finally, if respondents say that improvements to the transit system might lead them to get rid of their vehicle, there is an open text box allowing them to explain what those changes would be.

The observations in the case database are adults who we believe live in the DMV area. We are uncertain whether they still live there or have a personal vehicle, but the survey will end for such respondents if they indicate this is the case.

-----

*** ietestform results:

The ietestform report listed three "errors" in my form.

1. The report believed it was an error that there was a non-numeric value in the [value] column of the choice sheet.
However, this instance was when I pulled a list of choices from the external states dataset, so I believe I did this right.

2 & 3. The report flagged two instances where I had non-required non-note type fields.

One instance was a date-type field where I asked for the respondent's birthday-- this was a mistake, so I made this required.

The other instance was that I made the last question optional, which was the open text box for those that responded that they could potentially get rid of their vehicle.
I did this intentionally because when I take surveys, I don't mind selecting between choices or giving very short answers, but I am more likely to stop taking the survey if it's required that I fill out a long text box.
I am curious whether it is still considered "bad practice" to make this question unrequired, so I am looking forward to your feedback.