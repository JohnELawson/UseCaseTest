@ECHO OFF
REM Database update script
REM Written by John Lawson on 28th Feb 2016

ECHO Database Upgrade Script

setlocal EnableDelayedExpansion
SET dbUser=root
SET dbPasswd=rootpw
SET mysqlInstallLocation="C:\Program Files\MySQL\MySQL Server 5.7\bin\mysql"
SET databaseVersonTable=dbversion
SET getVersionSQL="SELECT MAX(version) FROM installed"

REM loop files in dir
SET /a endPointer=0
SET minPointer=0
FOR %%G IN (*.sql) DO (
  REM if they match
  ECHO %%G | FINDSTR /RI "^[0-9]" >NUL 2>&1
  IF errorlevel 1 (nul) ELSE (
    REM add the file to array
    SET sqlFiles[!endPointer!]=%%G
    SET /a endPointer+=1
  ) 
)

REM Exit if no sql files were found
IF "%endPointer%" == "0" (
  ECHO No matching sql files found. 
  ECHO Exiting Script.
  PAUSE
  EXIT
)

REM print all files found
REM no need to sort as windows orders correctly
ECHO The following sql update files were found:
FOR /F "tokens=1* delims==" %%s IN ('SET sqlFiles[') do (
  ECHO %%t
)

REM Find the current database version
!mysqlInstallLocation! --user=!dbUser! --password=!dbPasswd! -D!databaseVersonTable! -se !getVersionSQL! >> version.txt
SET /p databaseVersion=<version.txt


REM loop over sql scripts
SET count=0
FOR /F "tokens=1* delims==" %%s IN ('SET sqlFiles[') do (
  REM Extract file name version
  REM SET s=%%t
  SET scriptVersion=020 
  REM !s:~0,3%!
  
  
  REM ECHO d: !databaseVersion! s: !scriptVersion! 

  REM If script version is higher than installed version execute it
  IF !datavaseVersion! LSS !scriptVersion! (
    ECHO Executing script: %%t
 	!mysqlInstallLocation! --user=!dbUser! --password=!dbPasswd! -D!databaseVersonTable! < %%t
 	REM Update db version
    !mysqlInstallLocation! --user=!dbUser! --password=!dbPasswd! -D!databaseVersonTable! -se "INSERT INTO installed (version, date) VALUES ('!scriptVersion!', CURRENT_TIMESTAMP)"
    REM Update script dv versioni
    !mysqlInstallLocation! --user=!dbUser! --password=!dbPasswd! -D!databaseVersonTable! -se "SELECT MAX(version) FROM installed" >> version.txt
    SET /p databaseVersion=<version.txt
    REM Check if any scripts executed
    SET updated=1
  )
)

REM if no scripts were executed
if "%updated%" == "0" (
  echo Database is up to date! No scripts were executed. Exiting.
) else (
  echo The database version is now: !databaseVersion!. Finished database update script.
)
PAUSE