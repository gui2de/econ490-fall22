## Survey Overview

This is a survey of Georgetown students and alumni who were enrolled in classes last semester (spring 2022). The survey collects basic information on respondents' coursework, including course names, hours spent studying/attending class, grades received, and opinions on instructors, inter alia.

For the Week 11 assignment, I added a new question seeking to suss out respondents' opinions on the quality of their course instructors. In my view, this is a sensitive question, as many respondents may be hesitant to share their true opinions, fearing reprisal. To that end, I use a list experiment whereby respondents are asked to indicate the number of statements they agree with from a list of statements about the course, one of which pertains to instructor quality.

I created four separate versions of this list experiment, two with positively phrased statements and the other two with negatively phrased ones. Moreover, within each positive/negative category, I phrased the statements in different ways. For example, positive version 1 has the statement "The primary instructor(s) of the class was/were engaging," positive version 2 has "The class was taught in an exciting and effective way," negative version 1 has "The primary instructor(s) of the class was/were ineffectual," and negative version 2 uses "The class was taught in a boring an ineffective way." Each respondent is asked one version of this question, which is randomly chosen from amongst the four options with equal probability. By averaging responses from a variety of question framings, we have the potential to mitigate against biases in our results and thus obtain more accurate measures of our respondents' real sentiments.

# Where Is Everything!?

In this directory, you will find my survey response data in the file week11_survey_data.csv and the Stata template in the week11_stata_template.do file. Both were downloaded from SurveyCTO and renamed for clarity.

Link to survey on Google Drive: https://docs.google.com/spreadsheets/d/1FgDB12Hy-yQu1YJfpqSidnRJVNnUb6A4ac8CyW9zA1o/edit?usp=sharing

Link to SurveyCTO form (note user must specify the case ID at the end of the URL): https://gui2de.surveycto.com/collect/nbs_week6?caseid=

## Checking with ietestform

I ran the ietestform command in Stata, which suggested I shorten the Stata variable labels, which were too long. I did so accordingly.

The ietestform report also suggested I make all questions required. Currently, I leave the name, grade, sex, race, and Hispanic/Latino origin questions optional. Respectfully, I disagree with the suggestion of ietestform. I believe these are sensitive questions that people may feel uncomfortable responding to. Accordingly, requiring these questions is, in my view, likely to produce false responses or unnecessarily lower the survey response rate.

Lastly, ietestform also takes issue with the Continent_Code value, which it claims is non-numeric. However, I do not see any issues/errors in the recorded data, nor when filling out the survey. I suspect ietestform is having trouble understanding that the choices are being drawn from an external dataset. However, I welcome reviewer's comment if he/she thinks my hunch is mistaken.