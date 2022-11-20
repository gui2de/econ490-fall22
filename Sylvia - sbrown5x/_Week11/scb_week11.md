# Week 6 Assignment: Consumer Finance Survey
## Sylvia Brown

This survey asks some simple questions on respondents' use of financial technology platforms and mobile apps.

## Materials

* The [link](https://docs.google.com/spreadsheets/d/1Ez2EQOQg-gr4vMVsr0jxVUDqhwCA-A7-v_D5QIC8W6w/edit?usp=sharing) to my survey spreadsheet.

## Reflections on iefieldtest Report

The issues in my survey as detailed by my `iefieldtest` report are as follow:

* In five instances, I included too long a label for my Stata labels (i.e., over 80 characters). Going forward, I need to check that my Stata labels are sufficiently concise.
* `iefieldtest` pointed out that I hadn't made made several "text"-type questions required. In fact, I had meant to write "note" for these sections but had written "text" instead; I need to be careful when specifying question types going forward.
* `iefieldtest` pointed out that I made a "note"-type question required. However, I purposefully made this question required because I use it to catch whether answers to previous questions do not add up to the total reported in an earlier question. Therefore, this required note-type question doesn't represent an error.
* `iefieldtest` pointed out that in seven instances, I made a question with "label" in the "appearance" field required,which is not recommended. Reading through the [link they provide for more information](https://dimewiki.worldbank.org/Ietestform#Required_Column), they don't mention anything about instances where "label" is included in the "appearance" field, but they do explain why a "note"-type question should not be required, and I assume the same logic applies to questions where "label" is in the "appearance" field.