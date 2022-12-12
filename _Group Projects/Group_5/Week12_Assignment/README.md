## Group 5 Week 12 Assignment
## Noah's First Draft

### Dataset

We simulated a very simple dataset. We have 100 enumerators, each of whom asks a respondent for his/her name (coded as respondent_id), phone number, if he/she consents to the survey, and his/her age. The dataset also records the survey date, the survey start time, the start time of the consent question, the end time of that question, and the survey end time.

### Check 1: Duplicates

#### Potential Issue

One common issue with data collection is that respondents are recorded multiple times in the dataset. Such duplication may be caused by enumerator error. Another possibility is that respondent(s) knowingly respond to multiple enumerators for additional compensation. We identify two issues with such duplication. First, duplicate observations may diminish our dataset's representativeness of the target population. Second, respondents may give contradictory answers in separate survey administrations, which may diminish the accuracy of our dataset.

#### Check 1.1: Identity Index

This check compares the identity index, including name, age, sex, phone number, and GPS coordinate, of each survey administration (i.e., row). The data associated with these duplicates are exported to the "Identity Index Duplicates" sheet of the output Excel file. Records that have duplicates of the same identity index within a month will be flagged. We encourage the field manager to examine these duplicates and discuss his/her findings with the appropriate enumerators.

#### Check 1.2: Respondent Phone

This check is identical to the one above, except it identifies duplicates using respondent phone numbers. Ali explained in class that respondents may give false names or data when trying to "game the system," but they often give real phone numbers. Accordingly, we have implemented this check.

### Check 2: Consent Question Duration

We assume the consent question in our simulated data takes, at minimum, 30 seconds for the enumerator to read in full. This check flags enumerators who spend less than 30 seconds on the consent question and exports them to the "Consent Question Duration Flag" sheet of the output Excel file. Audio files will also be created to record and transcribe the consent statement process. An audio length that is shorter than the average will be flagged. Using these data, field managers can discuss the importance of survey consent with the appropriate enumerators.

### Check 3: Survey Duration

Given our simulated survey design, we expect each survey administration to last at least 2.5 minutes for respondents who consent. This check flags survey administrations where the respondent consented but the total survey duration was under 2.5 minutes. The flagged rows are exported to the "Survey Duration Flag" sheet of the output Excel file. Using these data, field managers can identify potentially deceitful enumerators and send followup surveys to the respondents in question to confirm the veracity of the data.
