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
# Copyright 2015, Nextlabs Inc.
# Author:: Amila Silva
#
# All rights reserved - Do Not Redistribute
#
echo "                                                                                                                           ";
echo "                                                                                                                           ";
echo "                                                                                                                           ";
echo "    _______  _______  _       _________ _______                 _______  _______  _______           _______  _______       ";
echo "   (  ____ )(  ___  )( \      \__   __/(  ____ \|\     /|      (  ____ \(  ____ \(  ____ )|\     /|(  ____ \(  ____ )      ";
echo "   | (    )|| (   ) || (         ) (   | (    \/( \   / )      | (    \/| (    \/| (    )|| )   ( || (    \/| (    )|      ";
echo "   | (____)|| |   | || |         | |   | |       \ (_) /       | (_____ | (__    | (____)|| |   | || (__    | (____)|      ";
echo "   |  _____)| |   | || |         | |   | |        \   /        (_____  )|  __)   |     __)( (   ) )|  __)   |     __)      ";
echo "   | (      | |   | || |         | |   | |         ) (               ) || (      | (\ (    \ \_/ / | (      | (\ (         ";
echo "   | )      | (___) || (____/\___) (___| (____/\   | |         /\____) || (____/\| ) \ \__  \   /  | (____/\| ) \ \__      ";
echo "   |/       (_______)(_______/\_______/(_______/   \_/         \_______)(_______/|/   \__/   \_/   (_______/|/   \__/      ";
echo "                                                                                                                           ";
echo "                                                                                                                           ";
echo "                                                                                                 version : @cc_version@    ";
echo "                                                                                                                           ";
echo "                                                                                                                           ";
echo "                                                                                                                           ";
echo "                                                                                                                           ";
# The program should be executed by root
[ "$(whoami)" != "root" ] && exec sudo -- "$0" "$@"

export START_DIR=$( dirname "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" )

echo "Current working directory:${START_DIR}"
echo "Uncompressing engine_linux to temp folder"
unzip -o -q "${START_DIR}/engine/engine_linux.zip" -d /opt
echo "Finished Uncompressing chef"

echo "Copy required gems to chef embedded ruby"
unzip -o -q "${START_DIR}/engine/gems_linux.zip" -d /tmp
cp -rf /tmp/gems/gems/* /opt/chef/embedded/lib/ruby/gems/2.1.0/gems/
cp -rf /tmp/gems/specifications/* /opt/chef/embedded/lib/ruby/gems/2.1.0/specifications/
cp -rf /tmp/gems/extensions/x86_64-linux/2.1.0/* /opt/chef/embedded/lib/ruby/gems/2.1.0/extensions/x86_64-linux/2.1.0/
echo "Finished copy gems"

echo "Installation Starting..."
/opt/chef/bin/chef-client --config "${START_DIR}/bin/config.rb" -o ControlCenter::main

echo "Removing and Cleaning files"

rm -rf /opt/chef
rm -rf /tmp/gems
rm -rf /tmp/client.rb
rm -rf "${START_DIR}/local_mode_cache"
rm -rf "${START_DIR}/nodes"

echo "Installation completed"
