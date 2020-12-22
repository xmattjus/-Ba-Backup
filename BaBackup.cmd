@ECHO OFF
SETLOCAL EnableDelayedExpansion

REM Check if current Windows version is supported
CALL :CheckWindowsVersion

REM Check if required binaries exist
CALL :CheckProgramRequirements

REM Get the current system date and time
CALL :GetDateTime DateTime

REM Program variables
SET ProgName=[Ba]Backup V0.8.0
SET ProgramDir=%~dp0
SET ConfigFileName=config.txt
SET DestDir="C:\BaBackup"
SET TempDir=%TEMP%\BaBackup_%DateTime%
SET LogDir=%LOCALAPPDATA%\BaBackup
SET LogFile="%LogDir%\BaBackup_%DateTime%.log"

REM Make sure the log output folder exists and is writable by the user
IF NOT EXIST %LogDir%\ (
	MD %LogDir%
)
IF %ERRORLEVEL% NEQ 0 (
	ECHO "FATAL" "Unable to write to the file log folder, check the directory path and try again"
	GOTO :Error
)

REM Log file header
CALL :LogUtil "INFO" "%ProgName%"

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
CALL :RoboBackup "%ProgramDir%%ConfigFileName%"

REM Create a compressed archive (7z format) of the backup
CALL :LogUtil "INFO" "Compressing backup..."
.\bin\7za.exe a -t7z -mmt=2 -bso1 -bse1 -bsp1 %DestDir%\BaBackup_%DateTime%.7z %TempDir% | .\bin\tee.bat %LogFile% 1

REM Delete the temp folder
CALL :LogUtil "INFO" "Deleting temporary files and folders..."
RD /S /Q "%TempDir%" | .\bin\tee.bat %LogFile% 1

REM Program end
CALL :LogUtil "INFO" "Backup completed"

ENDLOCAL
EXIT /B 0

REM Windows versions below 6.1 (e.g. prior to Windows 7) are not supported
REM Source: https://stackoverflow.com/a/25978837
:CheckWindowsVersion (
	FOR /F "tokens=4-7 delims=[.] " %%i IN ('ver') DO (IF %%i==Version (SET version=%%j.%%k) ELSE (SET version=%%i.%%j))
	IF "%version%" == "6.1" EXIT /B 0
	IF "%version%" == "6.2" EXIT /B 0
	IF "%version%" == "6.3" EXIT /B 0
	IF "%version%" == "10.0" EXIT /B 0
	ECHO.
	ECHO %DATE% %TIME:~0,-3% FATAL : Unsupported Windows version detected, aborting...
	GOTO :Error

)

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

REM Validate the calling argument:
REM Must not be an empty string (first check)
REM Must be a txt file (second and third check)
REM Must not contain invalid characters (fourth check)
REM Source: https://www.robvanderwoude.com/battech_inputvalidation_commandline.php#ParameterFiles
:ValidateConfig <ConfigFilePath> (
    IF NOT EXIST "%~1" (
        CALL :LogUtil "FATAL" "Config file does not exist, aborting..."
        GOTO :Error
    )

    FINDSTR /R "& ' `" "%~1" > NUL
    IF NOT ERRORLEVEL 1 (
		CALL :LogUtil "FATAL" "Invalid characters found in the config file, aborting..."
		GOTO :Error
    )
    EXIT /B 0

)

REM Map each line of the config file to a string array element (first loop) 
REM Copy each dir or file contained in the array to the destination (second loop)
:RoboBackup <ConfigFilePath> (
    SET /A i=0

	REM The CALL instruction before the second and third SET commands is intended, no variables will be set otherwise!
    FOR /F "usebackq delims=" %%a IN ("%~1") DO (
        SET /A i+=1
        CALL SET array[%%i%%]=%%a
        CALL SET n=%%i%%
    )

    FOR /L %%i IN (1,1,%n%) DO (
		CALL :LogUtil "INFO" "Backup of "!array[%%i]!" started..."
		CALL :IsDir !array[%%i]!
		IF !ERRORLEVEL! EQU 0 (
			CALL :GetFolderName FolderName !array[%%i]!
			CALL ROBOCOPY !array[%%i]! "%TempDir%\!FolderName!" /S /E /Z /FFT /R:5 /TBD /MT:16 /V /FP /NP /NJH /NJS | .\bin\tee.bat %LogFile% 1
		) ELSE (
			CALL XCOPY !array[%%i]! %TempDir% | .\bin\tee.bat %LogFile% 1
		)
	)
    EXIT /B 0

)

REM Source: https://stackoverflow.com/a/143935
: IsDir <Path> (
	FOR /F "delims=" %%i IN ("%~1") DO SET MYPATH="%%~si"
	PUSHD %MYPATH% 2>NUL
	IF ERRORLEVEL 1 (
		EXIT /B 1
	) ELSE (
		POPD
		EXIT /B 0
	)

)

REM Get the folder name from an expanded path, e.g. 
REM "C:\Users\Test\Desktop\New folder - Copy" will output "New Folder - Copy"
:GetFolderName <ResultVar> <PathVar> (
    SET "%~1=%~nx2"
    EXIT /B 0

)

REM Log an event to both the console and a log file simultaneously
REM First arg should be one of the following: INFO, ERROR, FATAL
REM Second arg should be the description of the message
REM Both args need to be strings, e.g. CALL :LogUtil "INFO" "Hello World"
REM Source: https://stackoverflow.com/a/10719322
:LogUtil <Type> <Description> (
	ECHO.| .\bin\tee.bat %LogFile% 1
    ECHO %DATE% %TIME:~0,-3% %~1 : %~2| .\bin\tee.bat %LogFile% 1
    EXIT /B 0

)

:Error (
	ECHO.
	PAUSE

)