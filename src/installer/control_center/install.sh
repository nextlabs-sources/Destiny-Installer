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
# Control Center Server Installer v1.0 for Linux Systems
#
# Copyright 2016, Nextlabs Inc.
# Author:: Amila Silva & Duan Shiqiang
#
# All rights reserved - Do Not Redistribute
#
 
# The program should be executed by root
[ "$(whoami)" != "root" ] && exec sudo -- "$0" "$@"
export START_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ "$1" == "-s" ];
then
    chmod +x $START_DIR/bin/install.sh
    /bin/bash $START_DIR/bin/install.sh
else
    chmod +x $START_DIR/bin/install_ui.sh
    /bin/bash $START_DIR/bin/install_ui.sh
fi