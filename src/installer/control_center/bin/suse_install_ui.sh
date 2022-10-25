#!/usr/bin/env bash
# 
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
# Control Center Server Installer GUI Launcher for SUSE Linux Systems
#
# Copyright 2015, Nextlabs Inc.
# Author:: Duan Shiqiang & Amila Silva
#
# All rights reserved - Do Not Redistribute
#
# version : v@cc_version@
#

# The program should be executed by root
[ "$(whoami)" != "root" ] && exec sudo -- "$0" "$@"

# Ignore SIGINT
# This is needed, because to stop the installation half way, we send
# SIGINT to the process group which includes this script process
trap '' INT

# START_DIR is used by UI and chef recipes, must be set before procceed
export START_DIR=$( dirname "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" )

echo "Current working directory:${START_DIR}"

export "UI_LOG_LOCATION=${START_DIR}/installer.log"
# Location for storing generated json properties file from UI for later reference
export "CHEF_JSON_PROPERTIES_FILE_BACKUP_LOCATION=${START_DIR}/cc_properties_ui.json"

echo "Copying jre bundle"
rm -rf "${START_DIR}/dist/Policy_Server/java"
mkdir "${START_DIR}/dist/Policy_Server/java"
chmod -R 755 "${START_DIR}/dist/Policy_Server/java"
cp -rf "${START_DIR}/platform/ppc64_suse/java/"* "${START_DIR}/dist/Policy_Server/java"
echo "Java jre bundle copied"

echo "Copying Chef Client bundle"
rm -rf "${START_DIR}/engine/engine_linux.zip"
cp -rf "${START_DIR}/platform/ppc64_suse/engine_linux_ppc64le.zip" "${START_DIR}/engine/engine_linux.zip"
echo "Chef Client bundle copied"

echo "Copying jsvc binary"
rm -rf "${START_DIR}/cookbooks/ControlCenter/files/default/jsvc"
cp -rf "${START_DIR}/platform/ppc64_suse/jsvc" "${START_DIR}/cookbooks/ControlCenter/files/default/jsvc"
echo "jsvc binary copied"

echo "Replacing uninstall shell script"
rm -rf "${START_DIR}/cookbooks/ControlCenter/templates/default/uninstall.sh.erb"
cp -rf "${START_DIR}/cookbooks/ControlCenter/templates/default/uninstall_ppc64.sh.erb" "${START_DIR}/cookbooks/ControlCenter/templates/default/uninstall.sh.erb"
echo "Uninstall shell script replaced"

echo "Uncompressing engine_linux"
unzip -o -q "${START_DIR}/engine/engine_linux.zip" -d /opt
echo "Finished uncompressing engine"

echo "Copy required gems to chef embedded ruby"
unzip -o -q "${START_DIR}/engine/gems_linux.zip" -d /tmp
cp -rf /tmp/gems/gems/* /opt/chef/embedded/lib/ruby/gems/2.1.0/gems/
cp -rf /tmp/gems/specifications/* /opt/chef/embedded/lib/ruby/gems/2.1.0/specifications/
cp -rf /tmp/gems/extensions/x86_64-linux/2.1.0/* /opt/chef/embedded/lib/ruby/gems/2.1.0/extensions/powerpc64le-linux/2.1.0/
echo "Finished copy gems"

echo "Fixing installer file permissions"
chmod +x "${START_DIR}/dist/Policy_Server/java/bin"/* "${START_DIR}/dist/Policy_Server/java/jre/bin"/*
echo "Finished fixing installer file permissions"

echo "Starting GUI installer"
chmod -R 755 /opt/chef
/opt/chef/embedded/bin/ruby "${START_DIR}/bin/ui/app.rb"

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
if [ -f /tmp/cc_properties.json ]; then
	rm -f /tmp/cc_properties.json
fi
if [ -d /tmp/local-mode-cache ]; then
	rm -rf /tmp/local-mode-cache
fi
echo "installation completed"
