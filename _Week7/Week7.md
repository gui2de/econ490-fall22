# Week 7 Homework Assignment

## Outline

This week, you will be working off of your previous survey and adding features to it.

## Step 1 : Add three features to your survey

You will add the following three features to your survey :
- Case management for tracking the completion status and number of attempts of your survey for each respondent
- Language label for Stata labeling (language "stata")
- Encryption

For **case management**, you will first need to create a case database for your survey, which is like a sample frame or a listing of people expected to fill out the survey. It doesn't have to be long - a minimum of 10 cases is sufficient (you are welcome to make it longer though, if it makes sense for your survey).

The case dataset must :
- be a csv
- include the following string variables
    - a unique identifier for observations called `id`
    - a name for observations called `label`
    - a variable called `formids` which contains the surveycto form ID of your form (aka the form we want to collect data with for these cases)
    - a variable called `users` which includes our shared username "covid19.studentsurvey@gmail.com" for all cases
    - as many variables needed or relevant for your survey, if you are planning to pull any data for data collection completion (eg phone numbers, demographics, etc.)

You will upload your csv by **appending** it to the existing `cases_shared` Cases database in our SurveyCTO server. To do so, find the dataset called Cases for Shared Form in SurveyCTO (inside the ECON490 group), click upload, and upload your csv while keeping selected "Append this data". Because we are all sharing the same cases database, you would erase your peers data if you merged or replaced instead. Also remember that the IDs you define for your sample frame must be created in a way that ensures they are unique with respect to other classmate's forms case IDs as well (similarly because we are sharing a case dataset). Include a reference to your initials or name in your case IDs to avoid any duplicate IDs with other people's forms.

You will use case management features in your form to allow for tracking how many times a respondent has been attempted at being surveyed, as well as tracking their survey completion status. You should create and publish into the cases dataset the following variables : 
- `num_calls` tracking the number of calls (or visits) that were made for this respondent
- `last_survey_status` tracking the status of the last survey for this respondent 

For **encryption**, you will use the keys we have created in class. The keys will not be shared in the class repo but on slack, and should be stored locally on your computer outside of the class repo. In order to encrypt your form, copy the PUBLIC key in the appropriate column in the Settings tab of your form. You will use the private key only to be able to download your form data. Remember that any variable that you are using to push/pull data to and from must be marked as Publishable in your form once your form is encrypted. Also note that because SurveyCTO doesn't allow users to encrypt a form after it has been deployed, you will have to delete your form from SurveyCTO and upload it again using that same Google Sheet.

For the **stata template**, once you have defined a new language in your form (both in the survey tab and the choices tab), you can download it from the surveycto by navigating to your form in the Design tab, click Download and select Stata .do template.

## Step 2 : Upload it to SurveyCTO and test it by submitting mock observations

Using the login information, upload your survey to SurveyCTO and use the error prompts while uploading the survey to fix any bugs, and the testing interface to test your code.

Once your survey is complete, submit a few mock observations to the server to test your case management updates. Because your form will be using case management, you need to access your survey from the following link [https://gui2de.surveycto.com/collect](https://gui2de.surveycto.com/collect) while being logged into surveycto, selecting Case Management, and finding your own cases to start filling out the form.

## Step 3: Submit your work on Github for review

As per usual, pull the latest version of the develop branch and create your own branch to submit this week's assignment.

For this assignment, you will add to your indivdiual folder on the class repository:
- Your case dataset (a .csv)
- A new paragraph in last week's markdown file including some context about who are the observations of your case databases. Make sure the links to your survey still work (they shouldn't have changed).

When creating your pull request into develop, this week you will not request a review from a peer, but you will request a review from your instructor Béatrice (github username: BeaLeydier). Béatrice and Roy will find your case observations on surveycto and fill out your form to create some more observations for you.

## Step 4 : Generate Stata templates and download your data

Once you have mock observations submitted for your survey, download your data (Export tab on surveycto), generate and run the stata template using your stata labels. Store both the dofile and the data in your folder of the class repository, and commit those changes. Note that the dta files should be ignored by the git repository, which means they will stay on your local repository but not pushed to the remote repo on github and not tracked by version control.

## Step 5 : Update your survey after reviewing your mock data

Remember to update the Changes Log tab of your survey, and, once the survey is functional and to your liking, merge your branch into develop.
