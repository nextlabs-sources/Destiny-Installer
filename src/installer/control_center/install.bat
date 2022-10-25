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
rem Control Center Server Installer v1.0 for Windows Systems
rem
rem Copyright 2016, Nextlabs Inc.
rem Author:: Amila Silva & Duan Shiqiang
rem
rem All rights reserved - Do Not Redistribute
rem

TITLE Control Center Server v@cc_version@

for /f "delims=: tokens=*" %%A in ('findstr /b ::: "%~f0"') do @echo(%%A
for %%i in ("%~dp0.") do SET "CURRENT_DIR=%%~fi"

IF "%1" == "-s" (
	call "%CURRENT_DIR%/bin/install.bat"
) ELSE (
    call "%CURRENT_DIR%/bin/install_ui.bat"
)


