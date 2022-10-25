#
# Cookbook Name:: ControlCenter
# Recipe:: remove server 
#           -  uninstall Server
#
# Copyright 2016, Nextlabs Inc.
# Author:: Amila Silva & Duan Shiqiang
#
# All rights reserved - Do Not Redistribute
#
require 'fileutils'
Chef::Resource::RubyBlock.send(:include, Utility::RoboFileUtils)

log ProgressLog::REMOVE_STARTED

if platform?('windows')

  # stop elasticsearch service
  ControlCenter_win_elasticsearch_service 'stop_windows_es_service' do
    service_name    node['elasticsearch_service_name']
    action          :stop
    ignore_failure  true
    only_if       { ::File.directory?node['es_home'] }
  end

  # remove elasticsearch service
  # if the es_home doesn't exist, nothing will be done
  # if the step fails, not necessarily to abort, so we just ignore_failure
  ControlCenter_win_elasticsearch_service 'remove_windows_es_service' do
    es_home       node['es_home']
    java_home     ::File.join(node['installation_dir'], 'java', 'jre')
    service_name  node['elasticsearch_service_name']
    action        :delete
    ignore_failure true
    only_if       { ::File.directory?(es_home) }
  end

  # Remove server from services
  # if the step fails, not necessarily to abort, so we just ignore_failure
  ControlCenter_windows_service 'remove_windows_service' do
    service_name      node['winx']['service_name']
    registry_key_name "HKEY_LOCAL_MACHINE\\#{node['REGISTY_KEY_NAME']}"
    procrun_path      ::File.join(node['installation_dir'], 'server/tomcat/bin/PolicyServer.exe')
    ignore_failure     true
    action            :delete
  end

  # Remove start menu links
  directory 'delete_windows_start_menu' do
    path Server::Config.win_start_shortcut_path()
    recursive true
    action :delete
  end

  # remove windows config store registry
  ControlCenter_config_store_win 'remove_windows_config_store' do
    registry_key_name   "HKEY_LOCAL_MACHINE\\#{node['REGISTRY_CONFIG_STORE_KEY_NAME']}"
    action              :delete
  end

else

  # stop control center service
  service 'stop_compliantenterprise_service' do
    service_name    node['linux']['service_name']
    ignore_failure  true
    action          :stop
  end
  
  # stop elastic search service
  service 'stop_elasticsearch_service' do
    service_name    node['elasticsearch_service_name']
    ignore_failure  true
    action          :stop
  end
  
  # remove elasticsearch service
  # if the es_home doesn't exist, nothing will be done
  # if the step fails, not necessarily to abort, so we just ignore_failure
  ControlCenter_linux_elasticsearch_service 'remove_linux_es_service' do
    es_home         node['es_home']
    service_name    node['elasticsearch_service_name']
    only_if         { ::File.directory?(es_home) }
    ignore_failure  true
    action          :delete
  end

  # Remove service from linux
  # if the step fails, not necessarily to abort, so we just ignore_failure
  ControlCenter_linux_service 'remove_linux_service' do
    service_name    node['linux']['service_name']
    config_path     Server::Config.linux_server_config_path(node)
    ignore_failure  true
    action  :delete
  end

  # remove linux config store file
  ControlCenter_config_store_linux 'remove_linux_config_store' do
    config_store_path   Server::Config.linux_server_config_store_path(node)
    action              :delete
  end

end

# No need to remove database tables

# Remove server files
ruby_block 'remove_server_files' do
  block do
    robo_rm_rf(node['installation_dir'])
  end
end
