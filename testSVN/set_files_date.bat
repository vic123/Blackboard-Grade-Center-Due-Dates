..\bin\filetouch /W /A /C /D 01-01-2000 file_with_old_date.txt
rem - filetouch does not set folder date with command below - only folder contents
rem ..\bin\filetouch /W /A /C /S /R /D 01-02-2000 FolderWithOldDate/
rem and 
..\bin\filetouch /W /A /C /S /D 01-02-2000 ./*.*