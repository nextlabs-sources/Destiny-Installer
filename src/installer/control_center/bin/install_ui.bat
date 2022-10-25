@ECHO OFF
rem
rem  /$$   /$$                    /$$    /$$               /$$                      /$$$$$$
rem | $$$ | $$                   | $$   | $$              | $$                     |_  $$_/
rem | $$$$| $$ /$$$$$$ /$$   /$$/$$$$$$ | $$       /$$$$$$| $$$$$$$  /$$$$$$$        | $$  /$$$$$$$  /$$$$$$$
rem | $$ $$ $$/$$__  $|  $$ /$$|_  $$_/ | $$      |____  $| $$__  $$/$$_____/        | $$ | $$__  $$/$$_____/
rem | $$  $$$| $$$$$$$$\  $$$$/  | $$   | $$       /$$$$$$| $$  \ $|  $$$$$$         | $$ | $$  \ $| $$
rem | $$\  $$| $$_____/ >$$  $$  | $$ /$| $$      /$$__  $| $$  | $$\____  $$        | $$ | $$  | $| $$
rem | $$ \  $|  $$$$$$$/$$/\  $$ |  $$$$| $$$$$$$|  $$$$$$| $$$$$$$//$$$$$$$/       /$$$$$| $$  | $|  $$$$$$$/$$
rem |__/  \__/\_______|__/  \__/  \___/ |________/\_______|_______/|_______/       |______|__/  |__/\_______|__/
rem
rem
rem Control Center Server Installer GUI Launcher for Windows Systems
rem
rem Copyright 2015, Nextlabs Inc.
rem Author:: Duan Shiqiang & Amila Silva
rem
rem All rights reserved - Do Not Redistribute
rem
rem version : v@cc_version@
rem

TITLE Control Center Server v@cc_version@

:: BatchGotAdmin
:-------------------------------------
REM  --> Check for permissions
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

REM --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params = %*:"=""
    echo UAC.ShellExecute "cmd.exe", "/c %~s0 %params%", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"
:--------------------------------------

for %%i in ("%~dp0..") do SET "START_DIR=%%~fi"

ECHO Current working directory: %START_DIR%

SET UI_LOG_LOCATION="%START_DIR%/installer.log"
:: Location for storing generated json properties file from UI for later reference
SET CHEF_JSON_PROPERTIES_FILE_BACKUP_LOCATION="%START_DIR%\cc_properties_ui.json"

ECHO Creating C:\Temp folder
IF NOT EXIST C:\Temp MKDIR C:\Temp

ECHO Starting GUI installer
CALL "%START_DIR%\engine\chef\embedded\bin\ruby.exe" "%START_DIR%\bin\ui\app.rb"

ECHO Removing and Cleaning files
IF EXIST "%TEMP%\client.rb" DEL "%TEMP%\client.rb" /Q
IF EXIST "%TEMP%\cc_properties.json" DEL "%TEMP%\cc_properties.json" /Q
IF EXIST "%TEMP%\local-mode-cache" RMDIR "%TEMP%\local-mode-cache" /S /Q
IF EXIST "%START_DIR%\local-mode-cache" RMDIR "%TEMP%\local-mode-cache" /S /Q
IF EXIST "%START_DIR%\nodes" RMDIR "%TEMP%\local-mode-cache" /S /Q
ECHO Finished Removing and Cleaning files
