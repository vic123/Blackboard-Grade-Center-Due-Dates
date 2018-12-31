# Test Cases for GCDD 0.6 and BB7-0.7 versions.

__When tagged with (BB9) - version able to work with Blackboard v.9 only.__   
__When tagged with (BB7) - version compatible with Blackboard v.7.3 and higher.__

1. Building Block start  
__Scenario:__ Start BB from navigation menu.  
__What to check:__ Overall view, missing of save (SAVE SUCCESS and WARNINGS…) related messages in "inlineReceipt" tag above BB title, working global navigation links.  
__Test Status:__
1. Basic Cancel operation  
__Scenario:__ Edit several fields, press Cancel button.  
__What to check:__ (BB9) Page has to reload and show initial values. / (BB7) Should act as "go back".  
__Test Status:__
1. Basic Submit operation  
__Scenario:__ Prepare data and perform all possible modifications (Is Available – from on to off and from off to on, same for Has Due Date, one new Due Date without time set, one Due Date with time set, one Due Date with modified Date, one Due Date with modified time)   
__What to check:__ Page has to reload and show new values, Due Date without time should get current time value, column with turned off due date has to contain (BB9) empty date and time controls / (BB7) current date and time. "SAVE SUCCESSFUL" should show up between page title and Step 1. Check that data was really modified through alternative column edit forms of Evaluation/Grade Center.  
__Test Status:__
1. Row level error handling during Submit (BB9 only, cannot be simulated with BB7)  
__Scenario:__ Modify Is Available on 2 rows, on one of them turn on Due Date (has to be off initially), but do not fill anything into date control.  
__What to check:__ "WARNING…" message should show up between page title and Step 1, containing name of the column left with empty date. Data (Is Available) should get modified on one row and left unchanged on the row containing error.  
__Test Status:__
1. Common due time Submit  
__Scenario:__ check on " Use same time for all due dates?" in step 1, optionally modify default (BB9) 11:59 PM / (BB7) 11:55 PM . Submit.  
__What to check:__ Due dates of all columns that have due dates should get time value specified.  
__Test Status:__
1. Re-ordering of records  
__Scenario:__ load BB form and click on every column heading.  
__What to check:__ records have to resort according to column selected. As a general rule rows with empty or unchecked field values has to be sorted out first, string data has to be sorted according to alphabetical order.  
__Test Status:__
1. Side column reordering effects (BB9 only, cannot be simulated with BB7)  
__Scenario:__ perform form submit that generates error message, edit some data that should provide another error, perform single column reorder operation.  
__What to check:__ records have to get restored to their initial values and error text should remain intact.  
__Test Status:__
1. Deny of Submit after logout  
__Scenario:__ login in one browser instance, open another instance with File/New/Window, open BB form in one of them and then do logout in another browser. Modify some value in another browser and click Submit.  
__What to check:__ Login form should appear, intended to be modified data has to remain intact.  
__Test Status:__
1. BB access and submit with lower than administrative credentials.  
__Scenario:__ Login as ordinary user having instructor, teaching assistance (teach_assist_001/ teach_assist_001 on test server) or course builder role. Open BB form, make some modifications for each editable field kind and submit data.  
__What to check:__ No specific errors should occur, data has to be saved.  
__Test Status:__
1. Error page information:  
__Scenario:__ Simulate an unhandled exception (should be caused by attempt to access BB with student-role user).  
__What to check:__ Message prompting to submit this error as bug report should appear with link to bug tracking system. Page should contain last exception trace, alphabetical list of parameters and their values passed to the page, log records of all levels (debug, info, etc.) recorded after latest page refresh including stack trace of any exceptions happened including latest one (i.e. a bit duplicated info as long as this trace was visualized already).  
__Test Status:__
1. Deny of BB access for students (and other regular user roles different from instructor, teaching assistance or course builder).  
__Scenario:__ Preserve shortcut to BB module from navigation menu (http://localhost/webapps/IDLA-gradecenter_duedates-bb_bb60/gc_duedates.jsp?course_id=_3_1 on test server). Then login as a student (student_001/student_001 on test server) and paste preserved link in address field.  
__What to check:__ error page should show up with access denied message.
__Test Status:__
1. Allow BB access for Administrator when it is not enrolled into course in any role.  
__Scenario:__ Log in as Administrator, go to System Admin tab/Classes/Classes, search for a class where Administrator is not enrolled, click on the class link, open BB.  
__What to check:__ BB should show up and allow edit operations.  
__Test Status:__
1. Adequate BB behavior when course does not have any non-calculated Grade Center Columns  
__Scenario:__ Create a new course and delete all columns in Evaluation/Grade Center. Open BB for a course.  
__What to check:__ BB should load as usual, list should just show "no items found"  
__Test Status:__

 