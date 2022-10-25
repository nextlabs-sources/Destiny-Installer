#
# Cookbook Name:: ControlCenter
# Recipe:: Bootstrap Recipe
#
# Copyright 2015, Nextlabs Inc.
# Author:: Amila Silva & Duan Shiqiang
#
# All rights reserved - Do Not Redistribute
#
# All the code in this recipe is meant to run during cookbook compile phase,
# Since the recipe is responsible to set some attributes at override level, create some temp directory, etc
# After the recipe is compiled, following attributes will be set:
# * temp_dir: will be set to system temp dir if no default specified
# * local_app_data: only on windows, will be set to local app data folder path, ex: C:/Users/admin/AppData/Local
# * dist_folder: The distribution folder (has the artifacts to be installed into the system) (when install and upgrade)
# * log_dir: The folder for other recipes to store necessary log files
# * backup_dir: The folder for other recipes to backup necessary files (for existing server)
# * dist_server_dir: The folder under dist_folder storing mainly server files (when install and upgrade)
# * dist_support_dir: The folder under dist_folder storing mainly files supports the installation (when install and upgrade)
# * installation_dir: The installation folder
# * support_classpath: The classpath string (jars separated by platform dependent separator) used for some cookbook library
#     ruby methods to use, the classpath should contain all jars in dist_support_dir (when install and upgrade)
# * jre_x_path: The java executable path, some cookbook library ruby methods may use it to call some java scripts
# * es_home: The elasticsearch home path (under installation directory)
# * decrypt_jar: The path to decrypt_jar (used by Server::Config.decrypt_password method)
# * version_number: The short version number such as 7.7, 8.0 etc
# * build_number: The build number such as 72PS-main
# * built_date: The built date of the installer
#
# For upgrade, it also populates those attributes to node
# * db_connection_url: The db_connection_url
# * db_username: The db username
# * db_encrypted_password: The encrypted password for db account
# * database_type: The db type (MSSQL or ORACLE or PQSQL)
# * mail_server_url
# * mail_server_port
# * mail_server_username
# * mail_server_encrypted_password
# * mail_server_from
# * encrypted_key_store_password: The encrypted key store password
# * encrypted_trust_store_password: The encrypted trust store password
# * web_application_port: The web application port for existing server
# The recipe also checks existing server's installed war files to determine whether the existing server is a
# complete installation, icenet installation or management server installation (two types of custom installation)
# it will set necessary attributes for library "server_configuration" to work correctly
# The recipe also check on console's index.html file to determine console_install_mode value. Existence of this file
# will set console_install_mode to OPN


require 'tmpdir'
require 'fileutils'

raise('START_DIR environment variable is not set, abort') if (ENV['START_DIR'] == nil)


node.override['temp_dir'] = ::Dir.tmpdir unless node.attribute?('temp_dir')
if ::File.basename(node['temp_dir']) != node['temp_basename']
  node.override['temp_dir'] = ::File.join(node['temp_dir'], node['temp_basename'])
  # then we need to create the directory
  directory "#{node['temp_dir']}" do
    recursive true
    action :nothing
  end.run_action(:create)
end

Chef::Log.info("[Bootstrap] Override attribute 'temp_dir' to #{node['temp_dir']}")

if node.platform?('windows')
  node.override['local_app_data'] = ENV['localappdata'].gsub("\\", '/')
  Chef::Log.info("[Bootstrap] Override attribute 'local_app_data' to #{node['local_app_data']}")
else
  # for linux, we use /usr/share as local_app_data directory
  node.override['local_app_data'] = '/usr/share'
  Chef::Log.info("[Bootstrap] Override attribute 'local_app_data' to #{node['local_app_data']}")
end

node.override['log_dir'] = ::File.join(ENV['START_DIR'].gsub("\\", '/'), node['temp_log_dir'])
Chef::Log.info("[Bootstrap] Override attribute 'log_dir' to #{node['log_dir']}")
node.override['dist_folder'] = ::File.join(ENV['START_DIR'].gsub("\\", '/'), node['dist_folder_name'])
Chef::Log.info("[Bootstrap] Override attribute 'dist_folder' to #{node['dist_folder']}")
node.override['backup_dir'] = ::File.join(node['temp_dir'], node['temp_backup_folder_name'])
Chef::Log.info("[Bootstrap] Override attribute 'backup_dir' to #{node['backup_dir']}")
node.override['dist_server_dir'] = ::File.join(node['dist_folder'], node['dist_server_folder_name'])
Chef::Log.info("[Bootstrap] Override attribute 'dist_server_dir' to #{node['dist_server_dir']}")
node.override['dist_support_folder'] = ::File.join(node['dist_folder'], node['dist_support_folder_name'])
Chef::Log.info("[Bootstrap] Override attribute 'dist_support_folder' to #{node['dist_support_folder']}")

if node['installation_mode'].to_s.strip.eql?('install')

  # if the installation_dir basename specified is not same as node["install_server_folder_name"]
  # append node["install_server_folder_name"] to it
  if ::File.basename(node['installation_dir']) != node['install_server_folder_name']
    node.override['installation_dir'] = ::File.join(node['installation_dir'], node['install_server_folder_name'])
  end

  # then we need to create the directory
  directory "#{node['installation_dir']}" do
    recursive true
    action :nothing
  end.run_action(:create)

  # for management server type installation, if console_install_mode is legacy (OPL), change cc_console_component to OFF
  if node['dms_component'].to_s.strip.eql?('ON') && node['console_install_mode'].to_s.strip.eql?('OPL')
    node.override['cc_console_component'] = 'OFF'
    Chef::Log.info("[Bootstrap] Override attribute 'cc_console_component' to #{node['cc_console_component']}")
  end

elsif node['installation_mode'].to_s.strip.eql?('upgrade') || node['installation_mode'].to_s.strip.eql?('remove')

  # then we need to get existing server's installation directory
  # warn: the existing_server_dir returned may be nil or ""
  # since user input is not guaranteed correct
  # and there may not be any server for us to remove or upgrade
  existing_server_dir = Server::Config.get_current_installation_dir(node)

  unless existing_server_dir.to_s.eql?('')
    Chef::Log.info("[Bootstrap] Detected existing server installation dir: #{existing_server_dir}")
    unless node['installation_dir'] == existing_server_dir
      node.override['installation_dir'] = existing_server_dir
      Chef::Log.info("[Bootstrap] Updated installation_dir to: #{existing_server_dir}")
    end
  end

  if node['installation_dir'] == nil || node['installation_dir'] == '' || !::File.directory?(node['installation_dir'])
    raise("The installation folder: '#{node['installation_dir']}' doesn't exist for #{node['installation_mode']}")
  end

end

node.override['es_home'] = ::File.join(node['installation_dir'], 'server', 'data', 'search-index')
Chef::Log.info("[Bootstrap] Override attribute 'es_home' to #{node['es_home']}")

# checks the installed war files
if node['installation_mode'] == 'upgrade'

  # for upgrade, we use console_install_mode as OPL
  node.override['console_install_mode'] = 'OPL'

  dms_war = ::File.join(node['installation_dir'], 'server', 'apps', node['components_war_map']['dms'])
  dabs_war = ::File.join(node['installation_dir'], 'server', 'apps', node['components_war_map']['dabs'])
  dkms_war = ::File.join(node['installation_dir'], 'server', 'apps', node['components_war_map']['dkms'])
  cc_console_war = ::File.join(node['installation_dir'], 'server', 'apps', node['components_war_map']['cc_console'])
  cc_console_index_file = ::File.join(node['installation_dir'], 'server', 'tomcat', 'webapps', 'console', 'index.html')
  
  # check if landing page file exist for console system to determine console_install_mode
  if ::File.exist?(cc_console_index_file)
    node.override['console_install_mode'] = 'OPN'
  end
  
  if ::File.exist?(dms_war)
    # regard as a mostly complete installation
    %w[dms_component dac_component dps_component dem_component admin_component reporter_component
      ].each {|comp|
      node.override[comp] = 'ON'
    }
    if ::File.exist?(cc_console_war)
      node.override['cc_console_component'] = 'ON'
    else
      node.override['cc_console_component'] = 'OFF'
    end
  else
    # custom installation (mostly icenet)
    %w[dms_component dac_component dps_component dem_component admin_component reporter_component
      cc_console_component].each {|comp|
      node.override[comp] = 'OFF'
    }
  end

  # we check dabs and dkms separately
  if ::File.exist?(dabs_war) then node.override['dabs_component'] = 'ON' else node.override['dabs_component'] = 'OFF' end
  if ::File.exist?(dkms_war) then node.override['dkms_component'] = 'ON' else node.override['dkms_component'] = 'OFF' end

  # decide whether it's a complete or custom installation
  %w[dms_component dac_component dps_component dem_component admin_component reporter_component
      dabs_component dkms_component cc_console_component].select { |comp| node[comp].eql?('OFF') }.empty?() ? \
      node.override['installation_type'] = 'complete' : node.override['installation_type'] = 'custom'

  # let's get the db details from either application.properties or configuration.xml
  if ::File.exist?(::File.join(node['installation_dir'], 'server/configuration/application.properties'))
    Server::Config.get_and_populate_db_info_from_application_properties(
            ::File.join(node['installation_dir'], 'server/configuration/application.properties'),
            node
    )
    Chef::Log.info('Got db info from existing application.properties')
    Chef::Log.debug("Override node attribute 'db_ssl_certificate' to #{node['db_ssl_certificate']}")
    Chef::Log.debug("Override node attribute 'db_connection_url' to #{node['db_connection_url']}")
    Chef::Log.debug("Override node attribute 'db_username' to #{node['db_username']}")
    Chef::Log.debug("Override node attribute 'db_encrypted_password' to #{node['db_encrypted_password']}")
    Chef::Log.debug("Override node attribute 'database_type' to #{node['database_type']}")
  elsif ::File.exist?(::File.join(node['installation_dir'], 'server/configuration/configuration.xml'))
    Server::Config.get_and_populate_db_info_from_configuration_xml(
        ::File.join(node['installation_dir'], 'server/configuration/configuration.xml'),
        node
    )
    Chef::Log.info('Got db info from existing configuration.xml')
    Chef::Log.debug("Override node attribute 'db_connection_url' to #{node['db_connection_url']}")
    Chef::Log.debug("Override node attribute 'db_username' to #{node['db_username']}")
    Chef::Log.debug("Override node attribute 'db_encrypted_password' to #{node['db_encrypted_password']}")
    Chef::Log.debug("Override node attribute 'database_type' to #{node['database_type']}")
  end

  # let's get the smtp details from configuration.xml
  if ::File.exist?(::File.join(node['installation_dir'], 'server/configuration/configuration.xml'))
    Server::Config.get_and_populate_smtp_info_from_configuration_xml(
        ::File.join(node['installation_dir'], 'server/configuration/configuration.xml'),
        node
    )
    Chef::Log.info('Got smtp info from existing configuration.xml')
    Chef::Log.debug("Override node attribute 'mail_server_url' to #{node['mail_server_url']}")
    Chef::Log.debug("Override node attribute 'mail_server_port' to #{node['mail_server_port']}")
    Chef::Log.debug("Override node attribute 'mail_server_username' to #{node['mail_server_username']}")
    Chef::Log.debug("Override node attribute 'mail_server_encrypted_password' to #{node['mail_server_encrypted_password']}")
    Chef::Log.debug("Override node attribute 'mail_server_from' to #{node['mail_server_from']}")
  end

  # Then get the ssl password from server.xml
  Server::Config.get_and_populate_encrypted_password_from_server_xml(
      ::File.join(node['installation_dir'], 'server/configuration/server.xml'),
      node
  )
  Chef::Log.info('Got ssl certs password info from server.xml')
  Chef::Log.debug("Override node attribute 'encrypted_key_store_password' to #{node['encrypted_key_store_password']}")
  Chef::Log.debug("Override node attribute 'encrypted_trust_store_password' to #{node['encrypted_trust_store_password']}")

  # Then get web_application_port from server.xml
  Server::Config.get_and_populate_web_application_port_from_server_xml(
      ::File.join(node['installation_dir'], 'server/configuration/server.xml'),
      node
  )
  Chef::Log.info('Got web application port from server.xml')
  Chef::Log.info("Override node attribute 'web_application_port' to #{node['web_application_port']}")

  # default data transportation settings, this value is to by pass pre-check operation
  if node['data_transportation_mode'] == nil
    node.override['data_transportation_mode'] = 'PLAIN'
  end

  Chef::Log.info("[Bootstrap] Override attribute 'installation_type' to #{node['installation_type']}")
  %w[dms_component dac_component dps_component dem_component admin_component reporter_component
        dabs_component dkms_component cc_console_component].each {|comp|
    Chef::Log.info("[Bootstrap] Override attribute '#{comp}' to #{node[comp]}")
  }
end


directory "#{node['log_dir']}" do
  recursive true
  action :nothing
end.run_action(:create)

# Set JRE path information (for some libraries)
begin

  node.override['classpath_separator'] = platform?('windows') ? ';' : ':'

  if node['installation_mode'].to_s.strip.eql?('install') || node['installation_mode'].to_s.strip.eql?('upgrade')
    node.override['jre_path'] = ::File.join(node['dist_server_dir'], 'java', 'jre')
    node.override['support_classpath'] = Dir[node['dist_support_folder'] + '/*.jar'].join(node['classpath_separator'])
  else
    node.override['jre_path'] = ::File.join(node['installation_dir'], 'java', 'jre')
  end

  node.override['instance_jre_path'] = ::File.join(node['installation_dir'], 'java', 'jre')
  if platform?('windows')
    node.override['jre_x_path'] = ::File.join(node['jre_path'], 'bin/java.exe')
    node.override['instance_jre_x_path'] = ::File.join(node['instance_jre_path'], 'bin/java.exe')
  else
    node.override['jre_x_path'] = ::File.join(node['jre_path'], 'bin/java')
    node.override['instance_jre_x_path'] = ::File.join(node['instance_jre_path'], 'bin/java')
  end

  # grant_temp_jre_execution_permission
  log 'granted_jre_execution_permission' do
    message '[Bootstrap] Granted temp jre execution permission'
    action :nothing
  end

  execute 'chmod-jre' do
    command %Q[chmod +x "#{::File.join(node['jre_path'], 'bin')}"/*]
    action :nothing
    not_if { platform?('windows') }
    notifies :write, 'log[granted_jre_execution_permission]', :immediately
  end.run_action(:run)

  node.override['decrypt_jar'] = "#{Chef::Config['file_cache_path']}/decrypt.jar"
  cookbook_file node['decrypt_jar'] do
    source 'decrypt.jar'
    action :nothing
  end.run_action(:create)

end

# decrypt database password
if node['installation_mode'] == 'upgrade'
  node.override['db_password'] = ::Server::Config.decrypt_password(node, node['db_encrypted_password'])
end

# Set version_number, build_number and built_date attribute
# the values are coming from the version file under START_DIR
version_file = ::File.join(ENV['START_DIR'].gsub("\\", '/'), node['version_file_name'])
raise("version file missing: #{version_file}") unless ::File.exist?(version_file)

::File.foreach(version_file) { |x|
  if version_match = x.match(/Policy Server version\s*:\s*(\d+(\.\d+)+)/i)
    # full version number should be like 8.0.0.999
    node.override['version_number'] = version_match.captures[0].strip()
    Chef::Log.info("[Bootstrap] Override attribute 'version_number' to: #{node['version_number']}")
  elsif built_date_match = x.match(/Built-Date\s*:\s*(\d{4}-\d{2}-\d{2})/i)
    # build_date should be like 2016-04-04
    node.override['built_date'] = built_date_match.captures[0].strip()
    Chef::Log.info("[Bootstrap] Override attribute 'built_date' to: #{node['built_date']}")
  elsif build_number_match = x.match(/Build Number\s*:\s*([\w\-]+)/i)
    node.override['build_number'] = build_number_match.captures[0].strip()
    Chef::Log.info("[Bootstrap] Override attribute 'build_number' to: #{node['build_number']}")
  end
}
