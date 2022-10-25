#
# Cookbook Name:: ControlCenter
# Recipe:: Main Recipe
#
# Copyright 2015, Nextlabs Inc.
# Author:: Amila Silva & Duan Shiqiang
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'ControlCenter::bootstrap'

include_recipe 'ControlCenter::pre_check'

log ProgressLog::PRECHECK_DONE

case node['installation_mode']
  when 'install'
    include_recipe 'ControlCenter::install_server'
    include_recipe 'ControlCenter::clean_up'
    include_recipe 'ControlCenter::add_remove_support'
    log ProgressLog::INSTALL_FINISHED
  when 'remove'
    include_recipe 'ControlCenter::remove_server'
    log ProgressLog::REMOVE_FINISHED
  when 'upgrade'
    include_recipe 'ControlCenter::upgrade_server'
    include_recipe 'ControlCenter::clean_up'
    include_recipe 'ControlCenter::add_remove_support'
    log ProgressLog::UPGRADE_FINISHED
  else
    raise("Installation mode is not supported: #{node['installation_mode']}")
end
