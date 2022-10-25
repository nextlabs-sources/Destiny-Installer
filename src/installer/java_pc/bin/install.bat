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
rem Java Policy Controller Installer v1.0 for Windows Systems
rem
rem Copyright 2015, Nextlabs Inc.
rem Author:: Amila Silva
rem
rem All rights reserved - Do Not Redistribute
rem

TITLE Policy Controller v@jpc_version@

:::
:::
:::
:::   _______  _______  _       _________ _______             _______  _______  _       _________ _______  _______  _        _        _______  _______
:::  (  ____ )(  ___  )( \      \__   __/(  ____ \|\     /|  (  ____ \(  ___  )( (    /|\__   __/(  ____ )(  ___  )( \      ( \      (  ____ \(  ____ )
:::  | (    )|| (   ) || (         ) (   | (    \/( \   / )  | (    \/| (   ) ||  \  ( |   ) (   | (    )|| (   ) || (      | (      | (    \/| (    )|
:::  | (____)|| |   | || |         | |   | |       \ (_) /   | |      | |   | ||   \ | |   | |   | (____)|| |   | || |      | |      | (__    | (____)|
:::  |  _____)| |   | || |         | |   | |        \   /    | |      | |   | || (\ \) |   | |   |     __)| |   | || |      | |      |  __)   |     __)
:::  | (      | |   | || |         | |   | |         ) (     | |      | |   | || | \   |   | |   | (\ (   | |   | || |      | |      | (      | (\ (
:::  | )      | (___) || (____/\___) (___| (____/\   | |     | (____/\| (___) || )  \  |   | |   | ) \ \__| (___) || (____/\| (____/\| (____/\| ) \ \__
:::  |/       (_______)(_______/\_______/(_______/   \_/     (_______/(_______)|/    )_)   )_(   |/   \__/(_______)(_______/(_______/(_______/|/   \__/
:::
:::
:::                                                                                                                             version : @jpc_version@
:::
for /f "delims=: tokens=*" %%A in ('findstr /b ::: "%~f0"') do @echo(%%A

for %%i in ("%~dp0..") do SET "START_DIR=%%~fi"
echo Current working directory: %START_DIR%

IF EXIST "%TEMP%\chef" RMDIR "%TEMP%\chef" /S /Q

echo Copying chef install files
xcopy "%START_DIR%\engine\chef" "%TEMP%\chef" /s /i /e /q

echo Installation Starting...

call "%TEMP%\chef\bin\chef-client.bat" --config "%START_DIR%/bin/config.rb" -o PolicyController::main

echo Removing and Cleaning files
IF EXIST "%TEMP%\chef" RMDIR "%TEMP%\chef" /S /Q

echo Installation completed
