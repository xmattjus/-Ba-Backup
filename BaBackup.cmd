@ECHO OFF
SETLOCAL EnableDelayedExpansion

REM Get the program start time to calculate the 
SET StartTime=%TIME%

REM Check if required binaries exist
CALL :CheckProgramRequirements

REM Get the current system date and time
CALL :GetDateTime DateTime

REM Program variables
SET ProgName="[Ba]Backup V1.1"
SET ProgramDir=%~dp0
SET ConfigFileName=filelist.txt
SET DestDir="C:\BaBackup"
SET TempDir=%TEMP%\Backup_%DateTime%
SET LogDir=%LOCALAPPDATA%\BaBackup
SET LogFile="%LogDir%\BaBackup_%DateTime%.log"
SET /A FileBackupCount=0
SET /A SourcesCount=0
SET /A ProgramExitCode=0

REM Make sure the log output folder exists and is writable by the user
IF NOT EXIST %LogDir%\ (
	MD %LogDir%
)
IF %ERRORLEVEL% NEQ 0 (
	ECHO "FATAL" "Unable to write to the file log folder, check the directory path and try again"
	GOTO :Error
)

REM Log file header
CALL :LogUtil "INFO" "%ProgName:~1,-1%"

REM Make sure the destination folder exists and is writable by the user
IF NOT EXIST %DestDir%\ (
	MD %DestDir%
)
IF %ERRORLEVEL% NEQ 0 (
	CALL :LogUtil "FATAL" "Unable to write to the destination folder, check the directory path and try again"
	GOTO :Error
)

REM Make sure the temporary folder exists and is writable by the user
IF NOT EXIST %TempDir%\ (
	MD %TempDir% | .\bin\tee.bat %LogFile% 1
)
IF %ERRORLEVEL% NEQ 0 (
	CALL :LogUtil "FATAL" "Unable to write to the temporary folder, check the directory path and try again"
	GOTO :Error
)

REM Check if the program config file is valid
CALL :ValidateConfig "%ProgramDir%%ConfigFileName%"

REM Backup the sources
CALL :PrepareBackup "%ProgramDir%%ConfigFileName%"

REM Create a compressed archive (7z format) of the backup,
REM if at least one file or folder has been copied successfully
IF NOT %FileBackupCount% EQU 0 (
	CALL :LogUtil "INFO" "Compressing backup..."
	.\bin\7za.exe a -t7z -mmt=2 -bb0 -v512m %DestDir%\Backup_%DateTime%.7z %TempDir% | .\bin\tee.bat %LogFile% 1
)

REM Delete the temp folder
CALL :LogUtil "INFO" "Deleting temporary files and folders..."
RD /S /Q "%TempDir%" | .\bin\tee.bat %LogFile% 1

REM Log backup results
IF %FileBackupCount% EQU %SourcesCount% (
	CALL :LogUtil "INFO" "Backup completed successfully."
	SET /A ProgramExitCode=0
)

IF %FileBackupCount% LSS %SourcesCount% (
	IF %FileBackupCount% NEQ 0 (
		CALL :LogUtil "ERROR" "Some files or folders have not been backup. Check the logs."
		SET /A ProgramExitCode=1
	)
	IF %FileBackupCount% EQU 0 (
		CALL :LogUtil "ERROR" "Unable to backup any files or folders. Check the logs."
		SET /A ProgramExitCode=2
	)
)

CALL :CalcProgramExecTime

ENDLOCAL
EXIT /B %ProgramExitCode%

REM Check if the required system programs are available
:CheckProgramRequirements (
	IF NOT EXIST ".\bin\date.exe" (
		ECHO.
		ECHO %DATE% %TIME:~0,-3% FATAL : Could not find date.exe, aborting...
		GOTO :Error
	)

	IF NOT EXIST ".\bin\7za.exe" (
		ECHO.
		ECHO %DATE% %TIME:~0,-3% FATAL : Could not find 7za.exe, aborting...
		GOTO :Error
	)

	IF NOT EXIST ".\bin\tee.bat" (
		ECHO.
		ECHO %DATE% %TIME:~0,-3% FATAL : Could not find tee.bat, aborting...
		GOTO :Error
	)

	CALL where.exe robocopy > NUL 2> NUL
	IF %ERRORLEVEL% NEQ 0 (
		ECHO.
		ECHO %DATE% %TIME:~0,-3% FATAL : Could not find robocopy.exe, aborting...
		GOTO :Error
	)
	EXIT /B 0
)

REM Get the system region-independent date and time with UnxUtils date.exe (e.g. 20200831_103029)
:GetDateTime (
	FOR /F "tokens=*" %%i IN ('.\bin\date.exe +"%%Y%%m%%d_%%H%%M%%S"') DO (
		SET %~1=%%i
	)
	EXIT /B 0
)

REM Validate the calling argument
REM Source: https://www.robvanderwoude.com/battech_inputvalidation_commandline.php#ParameterFiles
:ValidateConfig <ConfigFilePath> (
	CALL :LogUtil "INFO" "Reading config file..."
	
	IF NOT EXIST "%~1" (
		CALL :LogUtil "FATAL" "filelist.txt does not exist, aborting..."
		GOTO :Error
	)

	IF %~z1==0 (
		CALL :LogUtil "FATAL" "filelist.txt is empty, aborting..."
		GOTO :Error
	)

	FINDSTR /R "& ' `" "%~1" > NUL
	IF NOT ERRORLEVEL 1 (
		CALL :LogUtil "FATAL" "Invalid characters found in filelist.txt, aborting..."
		GOTO :Error
	)
	EXIT /B 0
)

REM Map each line of the config file to an array (first loop) 
REM Backup each dir or file contained in the array (second loop)
:PrepareBackup <ConfigFilePath> (
	SET /A i=0

	REM The CALL instruction before the second and third SET commands is intended, no variables will be set otherwise!
	FOR /F "usebackq delims=" %%a IN ("%~1") DO (
		SET /A i+=1
		CALL SET array[%%i%%]=%%a
		CALL SET n=%%i%%
	)

	REM 
	SET /A SourcesCount=%n%

	FOR /L %%i IN (1,1,%n%) DO (
		CALL :StartBackup "!array[%%i]!"
	)
	EXIT /B 0
)

REM Use a separate fuction to backup each dir or file
REM This way we can use the 8.3 filename for each item to backup as robocopy or xcopy argument
:StartBackup <Path> (
	CALL :IsDir %~s1
	IF !ERRORLEVEL! EQU 0 (
		CALL :LogUtil "INFO" "Backup of %~1\ started..."
		CALL :GetSourcePath "%~1" FolderName
		CALL ROBOCOPY "%~s1 " "%TempDir%\!FolderName! " /S /E /Z /FFT /R:3 /W:1 /TBD /MT:16 /NS /NC /NFL /NDL /NP /NJH /NJS /LOG+:%LogFile% /TEE
		REM Increment counter only on successful copy
		IF !ERRORLEVEL! LSS 8 (
			SET /A FileBackupCount+=1
			EXIT /B 0
		)
	) ELSE IF !ERRORLEVEL! EQU 1 (
		CALL :LogUtil "INFO" "Backup of %~1 started..."
		CALL :GetParentPath "%~1" FolderName
		CALL XCOPY %~s1 %TempDir%\!FolderName! | .\bin\tee.bat %LogFile% 1
		SET /A FileBackupCount+=1
		EXIT /B 0
	) ELSE (
		CALL :LogUtil "ERROR" "Backup of %~1 failed, skipping..."
		EXIT /B 1
	)
)

REM Check if the input <Path> variable is a folder (exit code 0),
REM is a file (exit code 1),
REM or is not a valid path (exit code 2)
REM Source: https://stackoverflow.com/a/143935
:IsDir <Path> (
	FOR /F "delims=" %%i IN ("%~1") DO SET MyPath="%%~si"
	PUSHD %MyPath% > NUL 2> NUL
	IF ERRORLEVEL 1 (
		IF NOT EXIST %MyPath% EXIT /B 2
		EXIT /B 1
	) ELSE (
		POPD
		EXIT /B 0
	)
)

REM Clean the input <InputPath> variable from the drive ":" character, e.g. 
REM "C:\Users\User\Desktop" will output "C$\Users\User\Desktop"
:GetSourcePath <InputPath> <OutputPath> (
	SET _drive=%~d1
	SET _path=%~pnx1
	IF NOT "%_drive:~0,2%" EQU "\\" (
		SET _drive2=%_drive:~0,1%
		SET _drive=!_drive2!$
	)
	SET "%~2=%_drive%%_path%"
	EXIT /B 0
)

REM Clean the input <InputPath> variable from the drive ":" character, e.g. 
REM "C:\Users\User\Desktop" will output "C$\Users\User\Desktop"
:GetParentPath <InputPath> <OutputPath> (
	SET _drive=%~d1
	SET _path=%~p1
	IF NOT "%_drive:~0,2%" EQU "\\" (
		SET _drive2=%_drive:~0,1%
		SET _drive=!_drive2!$
	)
	SET "%~2=%_drive%%_path%"
	EXIT /B 0
)

REM Calculate the program execution time
REM Source: https://stackoverflow.com/a/6209392
:CalcProgramExecTime (
	SET EndTime=%TIME%

	FOR /F "tokens=1-4 delims=:.," %%a IN ("%StartTime%") DO (
		SET start_h=%%a
		SET /A start_m=100%%b %% 100
		SET /A start_s=100%%c %% 100
		SET /A start_ms=100%%d %% 100
	)
	FOR /F "tokens=1-4 delims=:.," %%a IN ("%EndTime%") DO (
		SET end_h=%%a
		SET /A end_m=100%%b %% 100
		SET /A end_s=100%%c %% 100
		SET /A end_ms=100%%d %% 100
	)

	SET /A hours=%end_h%-%start_h%
	SET /A mins=%end_m%-%start_m%
	SET /A secs=%end_s%-%start_s%
	SET /A ms=%end_ms%-%start_ms%
	IF %ms% LSS 0 SET /A secs=%secs%-1 & SET /A ms=100%ms%
	IF %secs% LSS 0 SET /A mins=%mins%-1 & SET /A secs=60%secs%
	IF %mins% LSS 0 SET /A hours=%hours%-1 & SET /A mins=60%mins%
	IF %hours% LSS 0 SET /A hours=24%hours%
	IF 1%ms% LSS 100 SET ms=0%ms%

	CALL :LogUtil "INFO" "Total execution time: %hours% hours, %mins% minutes, %secs% seconds"
	EXIT /B 0
)

REM Log an event to both the console and a log file simultaneously
REM First arg should be one of the following: INFO, ERROR, FATAL
REM Second arg should be the description of the message
REM Both args need to be strings, e.g. CALL :LogUtil "INFO" "Hello World"
REM Source: https://stackoverflow.com/a/10719322
:LogUtil <Type> <Description> (
	ECHO.| .\bin\tee.bat %LogFile% 1
	ECHO %DATE% %TIME:~0,-3% %~1 : %~2 | .\bin\tee.bat %LogFile% 1
	EXIT /B 0
)

:Error (
	ECHO.
	REM PAUSE
)
