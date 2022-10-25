#
# Cookbook Name:: ControlCenter
# library:: progress_log
#     library for defining the log resource name for important progress made during cookbook convergence
#
# Copyright 2016, Nextlabs Inc.
# Author:: Duan Shiqiang
#
# All rights reserved - Do Not Redistribute
#

# The log messages are all started with "[Progress]" which can be used by UI to show progress message to user
# This module should be stay same as the same module used by installer cookbook

module ProgressLog

  PRECHECK_DONE = '[Progress] Precheck Finished'
  COPYFILE_STARTED = '[Progress] Copying files'
  COPYFILE_DONE = '[Progress] Finished copying files'

  INSTALL_DATABASE_MANIPULATE_STARTED = '[Progress] Starting database initialization'
  INSTALL_DATABASE_MANIPULATE_DONE = '[Progress] Finished database initialization'
  INSTALL_SERVICE_CREATE_STARTED = '[Progress] Creating services'
  INSTALL_SERVICE_CREATE_DONE = '[Progress] Finished creating services'

  REMOVE_NONEED_FILES_STARTED = '[Progress] Removing temporary files'
  REMOVE_NONEED_FILES_DONE = '[Progress] Removed temporary files'

  ADD_UNINSTALL_SCRIPTS_STARTED = '[Progress] Adding uninstall support'
  ADD_UNINSTALL_SCRIPTS_DONE = '[Progress] Finished adding uninstall support'

  INSTALL_FINISHED = '[Progress] Install finished'

  UPGRADE_BACKUP_SERVER_FILES_STARTED = '[Progress] Backing up existing server'
  UPGRADE_BACKUP_SERVER_FILES_DONE = '[Progress] Finished backing up existing server'
  UPGRADE_BACKUP_SERVICE_STARTED = '[Progress] Backing up registry/service_configs'
  UPGRADE_BACKUP_SERVICE_DONE = '[Progress] Finished backing up registry/service_configs'
  UPGRADE_RESTORE_OLD_SERVER_FILES_CONFIGS_STARTED = '[Progress] Restoring server files and configs'
  UPGRADE_RESTORE_OLD_SERVER_FILES_CONFIGS_DONE = '[Progress] Finished restoring server files and configs'
  UPGRADE_MODIFY_CONFIGURATION_FILES_STARTED = '[Progress] Processing configuration files for upgrade'
  UPGRADE_MODIFY_CONFIGURATION_FILES_DONE = '[Progress] Finished processing configuration files for upgrade'
  UPGRADE_DATABASE_MANIPULATE_STARTED = INSTALL_DATABASE_MANIPULATE_STARTED
  UPGRADE_DATABASE_MANIPULATE_DONE = INSTALL_DATABASE_MANIPULATE_DONE
  UPGRADE_CREATE_NEW_SERVICE_STARTED = '[Progress] Creating new services'
  UPGRADE_CREATE_NEW_SERVICE_DONE = '[Progress] Finished creating new services'
  UPGRADE_DELETE_EXISTING_SERVICE_STARTED = '[Progress] Deleting existing services'
  UPGRADE_DELETE_EXISTING_SERVICE_DONE = '[Progress] Finished deleting existing services'
  UPGRADE_MODIFY_EXISTING_SERVICE_STARTED = '[Progress] Modifying existing services'
  UPGRADE_MODIFY_EXISTING_SERVICE_DONE = '[Progress] Finished modifying existing services'
  UPGRADE_FINISHED = '[Progress] Upgrade finished'

  REMOVE_STARTED = '[Progress] Remove server started'
  REMOVE_FINISHED = '[Progress] Remove server finished'

end unless defined?(ProgressLog)
