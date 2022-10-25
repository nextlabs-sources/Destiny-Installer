#!/usr/bin/env bash
# Java Policy Controller Installer GUI start script
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
# Java Policy Controller Installer GUI Launcher for Linux Systems
#
# Copyright 2015, Nextlabs Inc.
# Author:: Duan Shiqiang & Amila Silva
#
# All rights reserved - Do Not Redistribute
#
# version : @jpc_version@
#

# The program should be executed by root
[ "$(whoami)" != "root" ] && exec sudo -- "$0" "$@"

# Ignore SIGINT
# This is needed, because to stop the installation half way, we send
# SIGINT to the process group which includes the this script process
trap '' INT

# START_DIR is used by UI and chef recipes, must be set before procceed
export START_DIR=$( dirname "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" )
# Location for storing generated json properties file from UI for later reference
export PROPERTIES_FILE_LOCATION=${START_DIR}/jpc_properties_ui.json

echo "Current working directory:${START_DIR}"

export UI_LOG_LOCATION=${START_DIR}/installer.log

echo "Uncompressing engine_linux"
unzip -o -q ${START_DIR}/platform/ppc64_suse/engine_linux_ppc64le.zip -d /opt
cp -r ${START_DIR}/engine/gems /tmp

cp -rf /tmp/gems/gems/* /opt/chef/embedded/lib/ruby/gems/2.1.0/gems/
cp -rf /tmp/gems/specifications/* /opt/chef/embedded/lib/ruby/gems/2.1.0/specifications/
cp -rf /tmp/gems/extensions/x86_64-linux/2.1.0/* /opt/chef/embedded/lib/ruby/gems/2.1.0/extensions/powerpc64le-linux/2.1.0/
echo "Finished uncompressing engine"

echo "Starting GUI installer"
chmod -R 755 /opt/chef
GEM_HOME=/tmp/gems /opt/chef/embedded/bin/ruby ${START_DIR}/bin/ui/app.rb

echo "Removing and Cleaning files"
if [ -d /opt/chef ]; then
	rm -rf /opt/chef
fi
if [ -d /tmp/gems ]; then
	rm -rf /tmp/gems
fi
if [ -f /tmp/client.rb ]; then
	rm -f /tmp/client.rb
fi
if [ -f /tmp/jpc_properties.json ]; then
	rm -f /tmp/jpc_properties.json
fi
if [ -d /tmp/local-mode-cache ]; then
	rm -rf /tmp/local-mode-cache
fi
echo "Installation completed"
