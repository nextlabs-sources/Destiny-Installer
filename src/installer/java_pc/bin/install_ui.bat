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
rem Java Policy Controller Installer GUI Launcher for Windows Systems
rem
rem Copyright 2015, Nextlabs Inc.
rem Author:: Duan Shiqiang & Amila Silva
rem
rem All rights reserved - Do Not Redistribute
rem
rem version : @jpc_version@
rem

TITLE Policy Controller v@jpc_version@

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

SET UI_LOG_LOCATION=%START_DIR%\installer.log
:: Location for storing generated json properties file from UI for later reference
SET PROPERTIES_FILE_LOCATION=%START_DIR%\jpc_properties_ui.json

IF EXIST "%TEMP%\chef" RMDIR "%TEMP%\chef" /S /Q
IF EXIST "%TEMP%\gems" RMDIR "%TEMP%\gems" /S /Q
IF EXIST "%TEMP%\jpc_properties.json" DEL "%TEMP%\jpc_properties.json" /Q

ECHO Copying chef install files
xcopy "%START_DIR%\engine\chef" "%TEMP%\chef" /s /i /e /q
xcopy "%START_DIR%\engine\gems" "%TEMP%\gems" /s /i /e /q

SET GEM_HOME=%TEMP%\gems

ECHO Starting GUI installer
CALL "%TEMP%\chef\embedded\bin\ruby.exe" "%START_DIR%/bin/ui/app.rb"

ECHO Removing and Cleaning files
IF EXIST "%TEMP%\chef" RMDIR "%TEMP%\chef" /S /Q
IF EXIST "%TEMP%\gems" RMDIR "%TEMP%\gems" /S /Q
IF EXIST "%TEMP%\jpc_properties.json" DEL "%TEMP%\jpc_properties.json" /Q
ECHO Finished Removing and Cleaning files
