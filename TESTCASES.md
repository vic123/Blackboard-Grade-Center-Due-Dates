# Test Cases

__Refer to GCDD v.09.33.__
 

### BB Installation  
__Scenario:__ Install BB from System Admin / Building Blocks / Installed tools / Upload Building Blocks, make it Available in both list boxes.  
__What to check:__ Successful installation and making BB available


## Browser Dependent tests

### BB Settings page  
__Scenario:__ Open Grade Center Due Dates Settings page from System Admin / Building Blocks / Installed tools page.  
__What to check:__ Page opens, default initial value of “Time part of all due dates” is set to 10 PM or previously configured value if it is reinstallation/update of BB v.0.9 or higher. Same is for “Log verbosity” – DEBUG2 or previous value, . Navigation away without warning messages on unsaved data modifications.

### Modification of settings  
__Scenario:__ Modify “Time part of all due dates”, pay attention to modification of every time part – Hours, Minutes, AM/PM. Modify “Log Severity”. Click cancel or any other link. Cancel navigation away, Submit.  
__What to check:__ Indication of modified fields, warning on unsaved data modifications *(does not work in Safari 4), successful save of modifications.

### Overall view of “individual due dates” and “due dates by grading period” pages  
__Scenario:__ Open “individual due dates” page from Classes / some Class / Class Tools / Set Grade Center Due Dates link. Click on “Edit Due Dates By Grading Period”. Cancel both forms.
__What to check:__ Overall view, missing of save (SAVE SUCCESS and WARNINGS…) related messages in "inlineReceipt" tag above BB title, Cancel working as back button, no warning messages on unsaved data modifications.

### Basic Submit operation of “individual due dates” page  
__Scenario:__ Prepare data and perform all possible modifications (Is Available – from on to off and from off to on, one new Due Date, one empty Due Date, one Due Date with wrong date format, Due Dates modified by hand and with Calendar popup. Try clicking Cancel and/or any other link that would cause loss of modifications. Submit.  
__What to check:__ Page has to show warn on cancel, warn on wrong date format, change this Due Date field to original value, reload and show new values. Green "Changes Saved" should show up above page title. Check that data was really modified through alternative column edit forms of Grade Center.

### Basic Submit operation of “due dates by grading period” page  
__Scenario:__ Prepare data and perform all possible modifications (Is Available – from on to off and from off to on, one new Due Date, one empty Due Date, one Due Date with wrong date format, Due Dates modified by hand and with Calendar popup. Try clicking Cancel and/or any other link that would cause loss of modifications. Submit.  
__What to check:__ Page has to show warn on cancel, warn on wrong date format, change this Due Date field to original value, reload and show new values. Green "Changes Saved" should show up above page title. Check that data was really modified through alternative column edit forms of Grade Center.



## Browser Independent tests

### Settings page

* Implication of settings  
__Scenario:__ Modify “Time part of all due dates” and “Log Severity”, "Show time part of due dates", "Date and time formats".  
__What to check:__ That modified due dates are saved with new time value (visible in Content Assessments edit pages), logged records correspond to specified verbosity, time part of due dates is hidden/shown, modification of "Date and time formats" influences saving of date/time data.


### Individual due dates page

* Row level error handling during Submit of “individual due dates” page  
__Scenario:__ Create new test column. Modify some of its data on “individual due dates”, delete column from another browser or tab, try submitting of “individual due dates” page.  
__What to check:__ yellow "WARNING…" message should show up above page title, containing name and id of deleted column. 

* Re-ordering of records of “individual due dates” page  
__Scenario:__ load “individual due dates” page and click on every column heading.  
__What to check:__ records have to resort according to column selected. As a general rule rows with empty or unchecked field values has to be sorted out first, string data has to be sorted according to alphabetical order.

* Deny of “individual due dates” Submit after logout  
__Scenario:__ login in one browser instance, open another instance with File/New/Window, open “individual due dates” form in one of them and then do logout in another browser. Modify some value in another browser and click Submit.  
__What to check:__ Login form should appear, modified data has to remain intact.

* Access of “individual due dates” page with lower than administrative credentials  
__Scenario:__ Login as ordinary user having teacher, teaching assistance or course builder role. Open “individual due dates” form, make some modifications for each editable field kind and submit data.  
__What to check:__ No specific errors should occur, data has to be saved. 

* Deny of “individual due dates” access for students (and other regular user roles different from instructor, teaching assistance, course builder or custom role with isActAsInstructor() flag set)  
__Scenario:__ Preserve shortcut to BB module from navigation menu (should be similar to http://idlatestbb.com/webapps/IDLA-gradecenter_duedates-BB_bb60/gc_duedates.jsp?course_id=_2_1 ). Then login as a student and paste preserved link in address field.  
__What to check__: error page should show up with access denied message. 

* Access of “individual due dates” by Administrator when it is not enrolled into course in any role  
__Scenario:__ Login as ordinary user having teacher, teaching assistance,  course builder role, custom role with isActAsInstructor() flag set. Open “individual due dates” form, make some modifications for each editable field kind and submit data.  
__What to check:__ “individual due dates” page should show up and allow edit operations.

* Adequate “individual due dates” page behavior when course does not have any non-calculated Grade Center Columns  
__Scenario:__ Ensure that course doesn’t have any non-calculated Grade Center Columns. Open “individual due dates”.  
__What to check:__ “individual due dates” should load as usual, list should just show "no items found".

* When "Show time part of due dates" is enabled, time part of individual due dates is accessible, "Time part of all due dates" is shown on individual due dates page and when enabled preserves its value on submit  
__Scenario:__ Enable "Show time part of due dates" Open “individual due dates”, save individual times and save with "Time part of all due dates" enabled.  
__What to check:__ Corect saving of data, including times of kind 12:xx AM/PM, preserving of "Time part of all due dates" when enabled (when disabled it is resetting its value to administrative "Time part of all due dates" by current design).


### Due dates by grading period page

* Row level error handling during Submit of “due dates by grading period” page  
__Scenario:__ Create new test period (without any associated columns). Set its due date, delete it in another browser window. Submit.  
__What to check:__ yellow "WARNING…" message should show up above page title, containing name and id of deleted period. 

* Re-ordering of records  
__Scenario:__  load “due dates by grading period” page and click on “Name” column heading.  
__What to check:__ records have to resort in back and forward alphabetical order.

* Deny of “due dates by grading period” Submit after logout  
__Scenario:__ login in one browser instance, open another instance with File/New/Window, open “due dates by grading period” form in one of them and then do logout in another browser. Modify some value in another browser and click Submit.  
__What to check:__ Login form should appear, modified data has to remain intact.

* Access of “due dates by grading period” page with lower than administrative credentials  
__Scenario:__ Login as ordinary user having teacher, teaching assistance or course builder role. Open “individual due dates” form, make some modifications for each editable field kind and submit data.  
__What to check:__ No specific errors should occur, data has to be saved.

* Deny of “due dates by grading period” access for students (and other regular user roles different from instructor, teaching assistance or course builder)  
__Scenario:__ Modify shortcut to “individual due dates” by inserting “_period” into “gc_duedates.jsp” (should become similar to http://idlatestbb.com/webapps/IDLA-gradecenter_duedates-BB_bb60/gc_period_duedates.jsp?course_id=_2_1 ). Then login as a student and paste preserved link in address field.  
__What to check:__ error page should show up with access denied message.

* Access of “individual due dates” by Administrator when it is not enrolled into course in any role  
__Scenario:__ Log in as Administrator, go to System Admin tab/Classes/Classes, search for a class where Administrator is not enrolled, click on the class link, open “individual due dates”, open “due dates by grading period”.  
__What to check:__ “due dates by grading period” page should show up and allow edit operations.

* Adequate “due dates by grading period” page behavior when course does not have any Grading Periods  
__Scenario:__ Ensure that course doesn’t have Grading Periods. Open “individual due dates”, open “due dates by grading period”.  
__What to check:__ “due dates by grading period” should show “No grading periods are available for this class” and "no items found".

* When "Show time part of due dates" is enabled, time part of period dates is accessible. 
__Scenario:__ Enable "Show time part of due dates". Open “individual due dates”, , open “due dates by grading period”, modify/save period  times.  
__What to check:__ Corect saving of data, including times of kind 12:xx AM/PM.


### Error page

* Error page information  
__Scenario:__ Simulate an unhandled exception (may be caused by attempt to access BB with student-role user, or the one appearing after attempt to access BB after logout).  
__What to check:__ Message prompting to submit this error as bug report should appear with link to bug tracking system. Page should contain last exception trace, alphabetical list of parameters and their values passed to the page, log records of all levels (debug, info, etc.) recorded after latest page refresh including stack trace of any exceptions happened including latest one (i.e. a bit duplicated info as long as this trace was visualized already).


### “To Do” module update

* Update of “To Do” with due date of regular Grade Center Column not associated with Grading Period  
__Scenario:__ Ensure that column is created from Grade Center interface (not Content area) and is not associated with Grading Period. It may be of any Category. Open “individual due dates” page in browser of one vendor and login as a student of the class in the browser of another vendor. Modify due date in “individual due dates” to (a) ten days in the future from today (b) ten days in the past (c) one year in the past (d) 2 years in the future.  
__What to check:__ Check student’s “To Do” section in “My Institution” or class dashboard after each modification of die date. Use context menu of Actions link to refresh “To Do” (note - some physical delay may exist before “To Do” is updated on server side). “To Do” has to become updated in all 4 cases (“Notification Cleanup” administrative option of Notifications settings either does not related to “To Do” or may not working – case (c)).

* Update of “To Do” with due date of Grade Center Column created through Content’s “Create Assessment” menu – Test, Survey or Assignment -, not associated with Grading Period  
__Scenario:__ Ensure that column is created from Content interface and is not associated with Grading Period. Open “individual due dates” page in browser of one vendor and login as a student of the class in the browser of another vendor. Modify due date in “individual due dates” to (a) ten days in the future from today (b) ten days in the past (c) one year in the past (d) 2 years in the future.  
__What to check:__ Check student’s “To Do” section in “My Institution” or class dashboard after each modification of die date. Use context menu of Actions link to refresh “To Do” (note - some physical delay may exist before “To Do” is updated on server side). “To Do” has to become updated in all 4 cases (“Notification Cleanup” administrative option of Notifications settings either does not related to “To Do” or may not working).


* Same as 2 above tests with regular/content columns assigned to Grading Period with today between start/end dates or without start/end dates show same results.  

* Failed update of “To Do” with due date of regular Grade Center Column assigned with Grading Period which does not include today’s date in between start/end dates  
__Scenario:__ Open “individual due dates” page in browser of one vendor and login as a student of the class in the browser of another vendor. Modify due date in “individual due dates” to (a) ten days in the future from today (b) ten days in the past (c) one year in the past (d) 2 years in the future.  
__What to check:__ If column’s due date was present in “To Do” module then it is deleted. “To Do” is not updated with new value in any of cases.

* Successful update of “To Do” with due date of “content” Grade Center Column assigned with Grading Period which does not include today’s date in between start/end dates  
__Scenario:__ Open “individual due dates” page in browser of one vendor and login as a student of the class in the browser of another vendor. Modify due date in “individual due dates” to (a) ten days in the future from today (b) ten days in the past (c) one year in the past (d) 2 years in the future.  
__What to check:__ “To Do” is updated in all 4 cases.

 