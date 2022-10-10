# Week 6 Homework Assignment

## Outline

This week, you will be coding your own survey on SurveyCTO. We are not prescribing the exact questions you need to be asking with your survey, but some types of modules you need to include. All these module types have been covered in the sample survey we coded together in class. You will code your survey using Google Sheets, upload and test it on SurveyCTO using the log in information below, and have someone else from your project group review your survey.

## Step 1 : Create a Google Sheets Template for SurveyCTO

1. Log into gui2de's SurveyCTO server (https://gui2de.surveycto.com/) with the following login information:
    `- User/email: covid19.studentsurvey@gmail.com`
    `- Pwd: pair.mutton.bust.antique`
1. Navigate to the ECON 490 group on the Desugn tab
1. Create a new form (give it a name and ID) and select "Download to Google Drive"
1. Open the file you just created in your Google Drive
1. Add a Cover tab and a Changes Log tab to the form

## Step 2 : Code your own survey

Using the Google Sheets template, you will code a survey for SurveyCTO containing the following modules :
- One identification including ID/name, phone number, email
- One demographics module including nationality, gender, age and other variables as relevant
- One module that involves listing things (roster of people, of classes, of habits etc) with a repeat group
- One module that involves quantifying something (time spent, income received, etc) including calculated checks on totals/sums
- At least one question with a likert scale (agree/disagree or true/false scale)
- At least one question pulling from an external dataset

We are not prescribing the exact questions your survey should contain. You should think of a specific target population for your survey, and the questions should be coherent for that population. It can, but doesn't have to, be related to your group project topic.

## Step 3 : Upload it to SurveyCTO and test it

Using the login information above, upload your survey to SurveyCTO and use the error prompts while uploading the survey to fix any bugs, and the testing interface to test your code.

Note that creating the survey (step 1) doesn't actually upload it to SurveyCTO, it simply creates the template for you to download. You need to upload it once by clicking "Upload Form Definition" and selecting your survey from Google Drive. After the survey has been uploaded once, you simply update it by clicking the Upload button next to the survey name (Upload Revised Form), and it will overwrite the previous form definition for the new one you link from Google Drive.

## Step 4: Submit your work on Github for peer review

As per usual, pull the latest version of the develop branch and create your own branch to submit this week's assignment.

For this assignment, you will simply submit a markdown file (.MD) containing the links to your survey. Under your own individual folder of the class repo, create a .MD document named appropriately, and in that markdown file, add two links:
- A link to your survey form in google drive (make sure in the settings of the sheet on google you have allowed anyone to comment on it)
- A link to your survey fill-out link for someone to fill out the survey. To find that link, go to the 2. Collect tab on SurveyCTO, navigate to your form and click "Share".

Feel free to add any other relevant context on your survey in that markdown file if you deem it relevant.

Create a Pull Request to merge this week's assignment (your .MD file) into the develop branch, and assign for review the next person within your project group as per alphabetical order (the list of students per group is under the _Group Projects folder of the class repo). Example with group 1: Sylvia will review Shaily's, Neel will review Sylvia's, and Shaily will review Neel.

## Step 5 : Review someone else's survey

Once someone asks your review on a survey, you should
1. Use the fill-out link for the survey and submit at least one mock response to survey, using this opportunity to test the survey coding. You may need to log in using the credentials above to fill out the survey.
1. Review the code in the google sheet and make any relevant comments/feedback on the github pull request.
