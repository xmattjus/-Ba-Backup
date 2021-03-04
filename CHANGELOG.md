# Changelog

## [1.0.1](https://github.com/xmattjus/BaBackup/tree/HEAD) (2021/03/04)

**Improvements:**

- The RoboBackup function has been diveded in two different functions (PrepareBackup and StartBackup), improving program reliability ([xmattjus](https://github.com/xmattjus))
- Improve the backup results logging. The program return code will be set 0 if all files and folders have been copied successfully, 1 if some files or folders were not copied successfully and 2 if no filed or folders were copied ([xmattjus](https://github.com/xmattjus))

**Fixed bugs:**

- Fixed network path backup ([xmattjus](https://github.com/xmattjus))

## [1.0](https://github.com/xmattjus/BaBackup/tree/HEAD) (2020/12/28)

**Improvements:**

- Removed Windows version check, the program doesn't use any Windows features besides robocopy.exe, and there is already a check in place to be sure it is present in the OS ([xmattjus](https://github.com/xmattjus))
- Disabled robocopy file and directory logging to speed up the backup process, copy errors will still be reported ([xmattjus](https://github.com/xmattjus))

## [0.8.1](https://github.com/xmattjus/BaBackup/tree/HEAD) (2020/12/22)

**Improvements:**

- Log total program execution time on program end ([xmattjus](https://github.com/xmattjus))

## [0.8](https://github.com/xmattjus/BaBackup/tree/HEAD) (2020/12/22)

**Improvements:**

- Use a JScript/Batch hybrid script to log the program output to both the console and a log file (replace the existing tee.bat) ([xmattjus](https://github.com/xmattjus))
- Code refactoring ([xmattjus](https://github.com/xmattjus))
- Improve program requirements detection ([xmattjus](https://github.com/xmattjus))
- Add OS detection ([xmattjus](https://github.com/xmattjus))
- Improve error handling ([xmattjus](https://github.com/xmattjus))

## [0.7](https://github.com/xmattjus/BaBackup/tree/HEAD) (2020/12/17)

**Improvements:**

- Program rename to Batch Backup ([xmattjus](https://github.com/xmattjus))
- Implement program logging to both the console and a logfile with tee.bat ([xmattjus](https://github.com/xmattjus))
- Rename function "LogToFile" to "LogUtil" ([xmattjus](https://github.com/xmattjus))
- Improve directory / file detection logic with the new function IsDir ([xmattjus](https://github.com/xmattjus))
- End program if the destination and temp folders are not writable by the user ([xmattjus](https://github.com/xmattjus))
- Make the check for invalid characters more permissive to enable backup of valid Windows folders (e.g "Program files (x86)") ([xmattjus](https://github.com/xmattjus))
- Program will now check if the configuration file is inside the same folder ([xmattjus](https://github.com/xmattjus))
- Implement more attributes to the robocopy command to enable network drive folders backup ([xmattjus](https://github.com/xmattjus))
- Removed file header from the actual batch program file ([xmattjus](https://github.com/xmattjus))

**Fixed bugs:**

- Fix temp folder deletion ([xmattjus](https://github.com/xmattjus))

## [0.6](https://github.com/xmattjus/BaBackup/tree/HEAD) (2020/09/09)

**Improvements:**

- Use REM instead of double colons for documentation ([xmattjus](https://github.com/xmattjus))
- Check if robocopy is present on the system ([xmattjus](https://github.com/xmattjus))
- Use an input file (.txt) for sources to copy ([xmattjus](https://github.com/xmattjus))
- Validate input file before executing program ([xmattjus](https://github.com/xmattjus))
- Other improvements ([xmattjus](https://github.com/xmattjus))

## [0.5](https://github.com/xmattjus/BaBackup/tree/HEAD) (2020/09/07)

**Improvements:**

- Do not delete temp files on robocopy error ([xmattjus](https://github.com/xmattjus))
- Print the message type (INFO, ERROR) in the log ([xmattjus](https://github.com/xmattjus))
- Use 7z file format for better compression ratio ([xmattjus](https://github.com/xmattjus))

## [0.4](https://github.com/xmattjus/BaBackup/tree/HEAD) (2020/09/04)

**Improvements:**

- Use an argument as the source directory ([xmattjus](https://github.com/xmattjus))
- Create a function to get the current system date and time ([xmattjus](https://github.com/xmattjus))

## [0.3](https://github.com/xmattjus/BaBackup/tree/HEAD) (2020/09/01)

**Improvements:**

- Change robocopy destination folder to %TEMP% ([xmattjus](https://github.com/xmattjus))

## [0.2](https://github.com/xmattjus/BaBackup/tree/HEAD) (2020/08/31)

**Improvements:**

- Get current date and time with UnxUtils date.exe instead of using WMIC ([xmattjus](https://github.com/xmattjus))

## [0.1](https://github.com/xmattjus/BaBackup/tree/HEAD) (2020/08/24)

- First release

