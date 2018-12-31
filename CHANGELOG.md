## Change log entries format: 
GCDD Version (Maturity) - Release date - initial compatible Bb version 

## v.0.9.38 (Stable) - 2018-12-30 - Bb 9.1 SP5 (9.1.50119.0)
* Migrated documentation from http://projects-archive.oscelot.org/gf/project/gc_duedates/wiki/ Wiki with minor fixes, updated changelog.
* Fixed and updated GCDD version number (please note that 0.9.36 and 0.9.37 releases published on Oscelot install as v.0.9.34, in the wars published on GitHub it is fixed).
* Binaries remained same as in v.0.9.37, marked v.0.9.38 as stable.

## v.0.9.37 (Beta) - 2016-10-02 - Bb 9.1 SP5 (9.1.50119.0)
Fixed potential open redirect vulnerability detected by Bb security assessment.

Modified redirect URLs to hard-coded values. Tested with Release 9.1.140152.0 (9.1 sp14).
 
## v.0.9.36 (Stable) - 2016-10-02 - Bb 9.1 SP5 (9.1.50119.0)
Fixed issue detected by Bb security assessment:  
"User input data is used in a loop(for loop) without being validated for maximum limit. A very high value could cause the application to get stuck in the loop and to be unable to continue to other operations."  

Added administrative settings for validation of maximum amount of submitted data.

## v.0.9.34 (Stable) - 2012-10-30 - Bb 9.1 SP5 (9.1.50119.0)
Fixed NullPointerException on Bb 9.1 SP8 and higher upon ordinary user access.

## v.0.9.33 (Alpha) - 2012-07-31 - Bb 9.1 SP5 (9.1.50119.0)
* Restored (as optional) capability to access individual due times (controlled through BB setting).  
* Fixed bug saving "12:30 AM as 12:30 PM" and "12:30 PM as 12:30 AM on the next day".
* Made date and time string format configurable through BB settings.
* Added access rights to custom course roles with isActAsInstructor() flag set.

## v.0.9.32 (Stable) - 2011-09-16 - Bb 9.1 SP5 (9.1.50119.0)
* Fixed problem with saving of Due Date when it is entered by hand
* Added "Grading Period" read-only column (linked to "Edit Grading Period") to "individual due dates" page
* Modified default sorting to sort by "Grading Period" (implemented as first by "Grading Period" and then by "Name")
* Improved error (warning on not all changes saved) reporting with causes of last exception (messages of nested exceptions)
* Version naming convention is complemented (suffixed) with SVN revision number

## v.0.9 (Beta) - 2011-09-07 - Bb 9.1 SP5 (9.1.50119.0)
* Bb API is switched to newer blackboard.platform.gradebook2 from blackboard.data.gradebook
* Bb version required is 9.1 SP5 (9.1.50119.0). Test with 9.0.440.0 failed with “Attribute label invalid for tag datePicker according to TLD” error, intermediate Bb releases were not tested
* New page added – “Grade Center Due Dates - set due dates by grading period”
* New page added – “Grade Center Due Dates Settings”
* “Same time for all due dates” (common due time) is moved to new page Grade Center Due Dates Settings
* Configurable logging verbosity
* Columns “Column” (Grade Center Column order) and “Has Due Date?” are removed
* Indication of modified fields
* Warning of unsubmitted data
* Correctly update notifications in “TO DO” Module
* Links to "Edit Grade Center Column", Content area, "Edit Grading Period" pages

## v.0.8 (Stable) - 2011-01-25 - Bb 9.0 (v.9.0.351.13)
Fixed bug caused errors with Bb 9.0 SP5 (v.9.0.613.0) when common time was checked and no time was specified at least for one of due dates (WebRoot/gc_duedates.jsp and WebRoot/WEB-INF/js/gc_duedates.js)  
Plus:
* Added enabling/disabling of common due time control depending on state of check box (gc_duedates.jsp and gc_duedates.js).
* Modified "SAVE SUCCESSFUL" to "Changes Saved" message upon successful submit. (gc_duedates.jsp)
* Upgraded project metadata to Eclipse Version: Helios Service Release 1, Build id: 20100917-0705 (.project, .settings/.*)
* Shifted to version 0.8 (WebRoot/WEB-INF/bb-manifest.xml)
* Put under SVN Bb and third party libraries as per Bb version (lib/*)

## v.BB7-0.7 (Stable) - 2010-01-08 - Bb 7.3
### Special release compatible with old Bb versions.
* Introduced LineItemDateField because Common Due time required similar handling/conversion of form parameters as LineItemDueDateField did, it is different from simpler processing in v.9.0.
* Naming of datetime form parameters is a bit different.
* All bbNG tags are substituted with bbUI ones.
* datePicker tag inside of the list is substituted with direct include of date-picker.jsp is a way not causing java.io.IOException: Illegal to flush within a custom tag.
* Registration naming is modified to gc_duedates_BB7, can be installed together with main trunk for version 9.0.

## v.0.7 (Stable) - 2010-01-08 - Bb 9.0 (v.9.0.351.13)
* Removed unnecessary custom JavaScript.
* Added receipt tag for handling of SUCCESS/WARNING messages.
* Better submit/redirect handling.
* Lib is moved outside of the project for “cheaper” tagging and branching.
* Fixes in error.jsp - check for null exception and exception.getCause().
* Custom check and redirection to login page.

## v.0.6 (Stable) - 2009-06-08 - Bb 9.0 (v.9.0.351.13)
* Turned off debug logging mode where all messages with lower than warning severity were logged as warnings.
* Added sessionId and verbosity level fields to log messages written to log but to discard from messages shown on error page.
* Added message showing sessionId so that error page messages can be easily matched with the ones stored in log file.
* Removed application name from log messages stored in page-context variable for possible later output on error page.
* Added help link to plugin processing description at project's home on oscelot.
* Fixed "double date-picker" problem.
* Removed version number from plugin link and directory names.
* Defined test cases for GDCDD releases targeted for Bb 7.3 and 9.0 versions families [TESTCASES-Bb7.3&9.0](TESTCASES-Bb7.3&9.0.md)

## v.0.5 (Beta) - 2009-05-31 - Bb 9.0 (v.9.0.351.13)
* Refactored MinutesPerPoint class into LineitemHelper, introduced LineItemField class and its successors,
* Refactored save procedure to use sequence of "CheckAndSave" actions for processing of several columns instead of if structure.
* Status column was removed, instead of that name of failed to be saved column is displayed in top message.
* Renamed "Type" column to "Category".
* Renamed "Has DueDate?"  column to "Has Due Date?".
* Added check on user role to be assistant/instructor/course builder.
* Removed lib jars from WebRoot\WEB-INF\lib.
* Implemented a way to collect and print log messages happened after last page reload (i.e. in page scope) directly to error page.
* Added ordering by name of parameters displayed on error page.

## v.0.3 (Alpha) - 2009-05-27 - Bb 9.0 (v.9.0.351.13)
* Initial prototype
