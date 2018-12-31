# Grade Center Due Dates Building Block Description

#### Abbreviations:

* GCDD – Grade Center Due Dates Building Block
* Bb – Blackboard

#### Documentation refers to GCDD v.0.9

#### Compatibility: Bb v.9.1 SP5 (9.1.50119.0) and higher

Grade Center Due Dates Building Block (later on referred as GCDD) allows users to set due dates and/or availability for columns in the Grade Center individually or by grading period.

## Pages
 
### Grade Center Due Dates Settings
__Location__: *System Admin / Building Blocks / Installed tools / Grade Center Due Dates Settings*  
__Permissions__: System Administrator system role

#### Summary:
The time setting on this page (10:00 PM by default) is the default time used for the GCDD. This means that when due dates are set using this tool, their time defaults to however this is set.

#### Fields:
* Time part of all due dates – the time used for all due dates set using the GCDD course tool.
* Log Verbosity – this will override global Bb logging verbosity.

### Grade Center Due Dates - individual due dates (all assignments listed)
__Location__: Classes / some Class / Class Tools / Set Grade Center Due Dates  
__Permissions__: Class Builder, Teacher, Teaching Assistant course membership roles, System Administrator system role

#### Summary:
On this page users can individually set due dates for all non-calculated Grade Center Columns. Users can also click on the Grade Center Column name to get to the Edit Column Information page. There is also a link at the top of the page to set due dates by grading period which will show that  page (details for which are below). The default due date time is set globally in the building block Settings page (as described above).

#### Fields: 
* Grading Period – Title of column's Grading Period  
    Links to Grade Center "Edit Grading Period" page  
* Name – Name of Grade Center Column  
    Links to Grade Center "Edit Column Information" page  
    Hovering over this hyperlink shows the Grade Center Column description.  
* Category – Category of the Grade Center Column  
    Links to class’s Content Area (if Content Area exists for the class).
* Is Available – Toggle this to make the Grade Center Column visible or invisible to students.
* Due Date – This is where users input the due date for each Grade Center Column. Remember that the time for each due date defaults to the time specified in the Setttings page.  


### Grade Center Due Dates - set due dates by grading period  
__Location__: activated with “Edit Due Dates by Grading Period Button” from “individual due dates” page  
__Permissions__: Class Builder, Teacher, Teaching Assistant course membership roles, System Administrator system role

#### Summary:
On this page users can enter one due date for an entire grading period. After clicking the submit button, the specified date is applied to every Grade Center Column associated with that grading period. For example, setting a due date of 2/1/2011 on this page will set all Grade Center Columns unit 1 to 2/1/2011. A blank due date box does nothing to the due dates for that grading period. Again, the time for the specified dates comes from the administrative setting described above.

Users can also click on "Grading Period Name" to get to the Edit Grading Period page.

Upon submit (or clicking on “Edit Individual Due Dates” button) user is redirected to the “individual due dates” page.

#### Fields:

* Name – name of Grading Period  
    Links to Grade Center "Edit Grading Period" page (under Manage -> Grading Periods).
* Due Date – Editable date only field. Upon submit, the inputted dates will be applied to every Grade Center Column associated with the specified Grading Period.

### Error page:
The error page is designed to provide useful information for GCDD developers in case of any unhandled exceptions. It contains the last exception message and trace, an alphabetical list of parameters and the values they passed to the page, log records of all levels (debug, info, etc.) recorded after the most recent page refresh including exception stack traces. The last exception trace is duplicated as a log record by design for simpler and more stable code of the error page itself.

## Behavioral Features and Specifics
### Indication of modified fields:
Fields modified by a user using the GCDD are marked with exclamation icon appearing to the left of the modified field.

### Warning of unsubmitted data:
In cases where the user navigates away from any of BB pages but has modified some fields on the form, a pop-up notification requests their confirmation that the entered data will be lost. If not confirmed, the navigation will be canceled and entered data preserved.

### Correctly update notifications in “TO DO” Module:
BB correctly updates notifications so that the “To Do” module shows the due date changes.

#### Notes:
Check that System Admin / Tools and Utilities / Notifications are enabled.

Check that personal “Edit Notification Settings” are configured appropriately.

Note that if today's date is between the start/end dates of the grading period, then "To Do" is updated as expected. But if today's date is outside of grading period start/end dates, then "To Do" is updated only for "Content" type grade columns. So columns created within the Grade Center interface do not appear in “To Do”.

### Unsafe concurrent access:
Currently GCDD does not check whether submitted data was concurrently modified by someone else. If values were changed in a different browser or by another user while someone had this open, they will overwrite changes that had just been made by that other person.

## Additional documentation:
* [CHANGELOG](CHANGELOG.md)  
* [TESTCASES](TESTCASES.md)

## Reported issues
* Incompatibility with Bb SaaS v3500.3  
__Error details__:  
Unable to compile class for JSP: 
An error occurred at line: 282 in the jsp file: /gc_duedates.jsp  
RECEIPT_KEY cannot be resolved or is not a field  
279: ReceiptMessage.messageTypeEnum.WARNING);  
280: } else rm = new ReceiptMessage("Changes Saved", ReceiptMessage.messageTypeEnum.SUCCESS);  
281: ro.addMessage(rm);  
282: request.getSession().setAttribute(InlineReceiptTag.RECEIPT_KEY, ro);  
283: // Retrieve the course identifier from the URL and construct formURL for response.sendRedirect(formURL) to itself  
284: String formURL = requestScope.getIndividualDueDatesURL();  
285: if ("on".equals(requestScope.getRequest().getParameter("isCommonDueTimeParam"))) {  

