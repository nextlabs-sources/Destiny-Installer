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
rem Copyright 2015, Nextlabs Inc.
rem Author:: Amila Silva
rem
rem All rights reserved - Do Not Redistribute
rem

TITLE Control Center Server v@cc_version@

:::
:::
:::
:::      _______  _______  _       _________ _______                 _______  _______  _______           _______  _______ 
:::     (  ____ )(  ___  )( \      \__   __/(  ____ \|\     /|      (  ____ \(  ____ \(  ____ )|\     /|(  ____ \(  ____ )
:::     | (    )|| (   ) || (         ) (   | (    \/( \   / )      | (    \/| (    \/| (    )|| )   ( || (    \/| (    )|
:::     | (____)|| |   | || |         | |   | |       \ (_) /       | (_____ | (__    | (____)|| |   | || (__    | (____)|
:::     |  _____)| |   | || |         | |   | |        \   /        (_____  )|  __)   |     __)( (   ) )|  __)   |     __)
:::     | (      | |   | || |         | |   | |         ) (               ) || (      | (\ (    \ \_/ / | (      | (\ (   
:::     | )      | (___) || (____/\___) (___| (____/\   | |         /\____) || (____/\| ) \ \__  \   /  | (____/\| ) \ \__
:::     |/       (_______)(_______/\_______/(_______/   \_/         \_______)(_______/|/   \__/   \_/   (_______/|/   \__/
:::
:::
:::                                                                                                  version : @cc_version@
:::
for /f "delims=: tokens=*" %%A in ('findstr /b ::: "%~f0"') do @echo(%%A

for %%i in ("%~dp0..") do SET "START_DIR=%%~fi"
echo Current working directory: %START_DIR%

echo Creating C:\Temp folder
if not exist C:\Temp mkdir C:\Temp

echo Installation Starting...

call "%START_DIR%\engine\chef\bin\chef-client.bat" --config "%START_DIR%\bin\config.rb" -o ControlCenter::main

echo Removing and Cleaning files
IF EXIST "%TEMP%\chef" RMDIR "%TEMP%\chef" /S /Q

echo Installation completed
