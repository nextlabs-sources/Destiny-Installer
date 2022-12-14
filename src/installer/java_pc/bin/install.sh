#!/bin/bash
#
#  /$$   /$$                    /$$    /$$               /$$                      /$$$$$$
# | $$$ | $$                   | $$   | $$              | $$                     |_  $$_/
# | $$$$| $$ /$$$$$$ /$$   /$$/$$$$$$ | $$       /$$$$$$| $$$$$$$  /$$$$$$$        | $$  /$$$$$$$  /$$$$$$$
# | $$ $$ $$/$$__  $|  $$ /$$|_  $$_/ | $$      |____  $| $$__  $$/$$_____/        | $$ | $$__  $$/$$_____/
# | $$  $$$| $$$$$$$$\  $$$$/  | $$   | $$       /$$$$$$| $$  \ $|  $$$$$$         | $$ | $$  \ $| $$
# | $$\  $$| $$_____/ >$$  $$  | $$ /$| $$      /$$__  $| $$  | $$\____  $$        | $$ | $$  | $| $$
# | $$ \  $|  $$$$$$$/$$/\  $$ |  $$$$| $$$$$$$|  $$$$$$| $$$$$$$//$$$$$$$/       /$$$$$| $$  | $|  $$$$$$$/$$
# |__/  \__/\_______|__/  \__/  \___/ |________/\_______|_______/|_______/       |______|__/  |__/\_______|__/
#
#
# Java Policy Controller Installer v1.0 for Linux Systems
#
# Copyright 2015, Nextlabs Inc.
# Author:: Amila Silva
#
# All rights reserved - Do Not Redistribute
#
echo "                                                                                                                                                  ";
echo "                                                                                                                                                  ";
echo "                                                                                                                                                  ";
echo " _______  _______  _       _________ _______             _______  _______  _       _________ _______  _______  _        _        _______  _______ ";
echo "(  ____ )(  ___  )( \      \__   __/(  ____ \|\     /|  (  ____ \(  ___  )( (    /|\__   __/(  ____ )(  ___  )( \      ( \      (  ____ \(  ____ )";
echo "| (    )|| (   ) || (         ) (   | (    \/( \   / )  | (    \/| (   ) ||  \  ( |   ) (   | (    )|| (   ) || (      | (      | (    \/| (    )|";
echo "| (____)|| |   | || |         | |   | |       \ (_) /   | |      | |   | ||   \ | |   | |   | (____)|| |   | || |      | |      | (__    | (____)|";
echo "|  _____)| |   | || |         | |   | |        \   /    | |      | |   | || (\ \) |   | |   |     __)| |   | || |      | |      |  __)   |     __)";
echo "| (      | |   | || |         | |   | |         ) (     | |      | |   | || | \   |   | |   | (\ (   | |   | || |      | |      | (      | (\ (   ";
echo "| )      | (___) || (____/\___) (___| (____/\   | |     | (____/\| (___) || )  \  |   | |   | ) \ \__| (___) || (____/\| (____/\| (____/\| ) \ \__";
echo "|/       (_______)(_______/\_______/(_______/   \_/     (_______/(_______)|/    )_)   )_(   |/   \__/(_______)(_______/(_______/(_______/|/   \__/";
echo "                                                                                                                                                  ";
echo "                                                                                                                                                  ";
echo "                                                                                                                                                  ";
echo "                                                                                                                          version : @jpc_version@ ";
echo "                                                                                                                                                  ";

export START_DIR=$( dirname "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" )

echo "Current working directory:${START_DIR}"
echo "Moving engine_linux to tmp folder"
cp -r ${START_DIR}/engine/chef /opt

echo "Installation Starting..."
/opt/chef/bin/chef-client --config ${START_DIR}/bin/config.rb -o PolicyController::main

echo "Removing and Cleaning files"
rm -rf /opt/chef

echo "Installation completed"
