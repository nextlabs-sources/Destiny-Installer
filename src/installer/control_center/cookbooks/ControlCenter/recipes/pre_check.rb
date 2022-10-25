#
# Cookbook Name:: ControlCenter
# Recipe:: Pre Checks
#            - Port Checks
#            - disk space Checks
#            - Super user access
#            - Super user password complexity
#            - Data transportation check
#            - DB check
#            - AD Check
#            - SMTP
#
# Copyright 2015, Nextlabs Inc.
# Author:: Amila Silva & Duan Shiqiang
#
# All rights reserved - Do Not Redistribute
#
# All the code in this recipe is meant to run during cookbook compile phase,
# It checks some aspects of the system, and if the system is not under expected status,
# the recipe will raise an exception with meaningful message, then the chef run should be stopped

require 'socket'
require 'timeout'

Chef::Log.info('[Precheck] Start precheck')

# For install scenario, check whether the web service port is listened
# For uninstall and upgrade scenario, we won't know the web_service_port
#   but we have a helper method to check whether the existing server is running or not
#   later in advanced check it's checked
begin
  if Server::Config.port_open?( 'localhost', node['web_service_port'] )
    Chef::Log.info("[Precheck] Checking #{node['web_service_port']} at localhost")
    raise("Port #{node['web_service_port']} not available), existing server running?")
  end
end if node['installation_mode'] == 'install'

# only check disk space if installation_mode is install or upgrade
if node['installation_mode'] == 'install' || node['installation_mode'] == 'upgrade'
  !Server::Config.disk_space_available?(node) ?
      raise('Don\'t have enough space on disk') :
      Chef::Log.info('[Precheck] The disk has enough space for the installation')
end

# only check license if installation_mode is install and it has management server component
if node['installation_mode'] == 'install' && node['dms_component'].to_s.strip.eql?('ON')
  if node['license_file_location'] == nil || node['license_file_location'] == '' ||
      !::File.exist?(node['license_file_location'])
    raise('License file specified is not valid')
  else
    begin
      licenseJarFile = File.join(node['dist_server_dir'], 'server', 'license', 'license.jar')

      p licenseDataFileDirLocation = File.dirname(node['license_file_location'])
      
      classpath = Dir[node['dist_support_folder'] + '/*.jar'].join(node['classpath_separator']) + node['classpath_separator'] +
                  licenseJarFile + node['classpath_separator'] + licenseDataFileDirLocation
                  
      valid_license_result = Utility::LicenseChecker.validate_license(node['license_file_location'], classpath, licenseJarFile, node['jre_x_path'])
      rescue Exception => ex
        raise("Got exception when trying to validate the license: #{ex.message}")
      end
      
      if !valid_license_result
        raise('License file specified is not valid')
      else
        Chef::Log.info('[Precheck] License file validation succeed')
      end
  end
end

# check administrator's password complexity
# only check if installation mode is install
if node['installation_mode'] == 'install' && node['install_as_master'] && (node['dms_component'].to_s.strip.eql? 'ON')
  if node['admin_user_password'] == nil || node['admin_user_password'] == ''
    raise('Administrator password cannot be null or empty')
  else
    valid = (node['admin_user_password'] =~ /^(?:(?=.*\d)(?=.*[A-Z])(?=.*[a-z])(?=.*[^A-Za-z0-9]))(?!.*(.)\1{2,})[A-Za-z0-9!~`<>,;:_=?*+#.'\\"&%()\|\[\]\{\}\-\$\^\@\/]{10,128}$/)
    if !valid
      raise('Administrator password does not comply with the password complexity policy')
    end
  end
end

# check key store's password complexity
if node['installation_mode'] == 'install'
  if node['key_store_password'] == nil || node['key_store_password'] == ''
    raise('Key store password cannot be null or empty')
  else
    valid = (node['key_store_password'] =~ /^(?:(?=.*\d)(?=.*[A-Z])(?=.*[a-z])(?=.*[^A-Za-z0-9]))(?!.*(.)\1{2,})[A-Za-z0-9!~`<>,;:_=?*+#.'\\"&%()\|\[\]\{\}\-\$\^\@\/]{10,128}$/)
    if !valid
      raise('Key store password does not comply with the password complexity policy')
    end
  end
end

# check trust store's password complexity
if node['installation_mode'] == 'install'
  if node['trust_store_password'] == nil || node['trust_store_password'] == ''
    raise('Trust store password cannot be null or empty')
  else
    valid = (node['trust_store_password'] =~ /^(?:(?=.*\d)(?=.*[A-Z])(?=.*[a-z])(?=.*[^A-Za-z0-9]))(?!.*(.)\1{2,})[A-Za-z0-9!~`<>,;:_=?*+#.'\\"&%()\|\[\]\{\}\-\$\^\@\/]{10,128}$/)
    if !valid
      raise('Trust store password does not comply with the password complexity policy')
    end
  end
end

# check if data transportation settings are correct
if node['installation_mode'] == 'install' && node['install_as_master'] && (node['dms_component'].to_s.strip.eql? 'ON')
  if node['data_transportation_mode'] == nil || (node['data_transportation_mode'] != 'PLAIN' && node['data_transportation_mode'] != 'SANDE')
    raise('Data transportation mode should be either PLAIN or SANDE')
  else
    if node['data_transportation_mode'] == 'SANDE'
      if node['data_transportation_shared_key'] == nil || node['data_transportation_shared_key'] == ''
        raise('Data transportation shared key specified is not valid')
      end

      if node['data_transportation_plain_text_import'] == nil || node['data_transportation_plain_text_import'] == ''
        raise('Please specify if allowed to import plain text policy bundle')
      end

      if node['data_transportation_plain_text_export'] == nil || node['data_transportation_plain_text_export'] == ''
        raise('Please specify if allowed to export plain text policy bundle')
      end

      if node['data_transportation_plain_text_import'] != 'true' && node['data_transportation_plain_text_import'] != 'false'
        raise('Allowed to import plain text policy bundle should either true or false')
      end

      if node['data_transportation_plain_text_export'] != 'true' && node['data_transportation_plain_text_export'] != 'false'
        raise('Allowed to export plain text policy bundle should either true or false')
      end
    end
  end
end
# Advance checks

# Existing server installation check
has_server_installed = Server::Config.has_any_server_installed?(node)
Chef::Log.info("[Precheck] Detected existing server #{Server::Config.get_current_server_version(node)} " +
    "at #{Server::Config.get_current_installation_dir(node)}") if has_server_installed


if has_server_installed

  server_location = Server::Config.get_current_installation_dir(node)
  server_version = Server::Config.get_current_server_version(node)

  if node['installation_mode'] == 'install'
    # can't proceed install if there's an existing server installed
    # exit with proper message

    if platform?('windows')
      error_msg = 'Control Center Server setup already exists in registry, ' +
        "registy path: #{node['REGISTY_KEY_NAME']}, " +
        "install path: #{server_location}, " +
        "server version: #{server_version}"
    else
      error_msg = 'Control Center Server setup already exists in config_file, ' +
        "config_file Path: #{Server::Config.linux_server_config_path(node)}, " +
        "install_path: #{server_location}" +
        "server version: #{server_version}"
    end
    Chef::Log.error(error_msg)
    raise('Existing control center server found in system, exit.')
  elsif node['installation_mode'] == 'remove'
    # only same version can be uninstalled by the installer, we compare only major version and minor version (8.0 can uninstall 8.0.1)
    if server_version.to_f() == node['version_number'].to_f()
      Chef::Log.info("[Precheck] Policy Server found to proceed with #{node['installation_mode']}")
    else
      error_msg = "Existing server version #{server_version} is not supported for uninstall"
      raise(error_msg)
    end
  elsif node['installation_mode'] == 'upgrade'
    # only OPN can be upgraded
    if Server::Config.get_installed_console_mode(node) == "OPL"
      error_msg = "Existing server console installation mode OPL is not supported for upgrade"
      raise(error_msg)
    end

    # only version lower than installer version can be upgraded
    if Server::Config.server_version_newer?(server_version, node['version_number'])
      Chef::Log.info("[Precheck] Policy Server found to proceed with #{node['installation_mode']}")
    else
      error_msg = "Existing server version #{server_version} is not supported for upgrade"
      raise(error_msg)
    end

    # checks whether existing server's logqueue folder is empty when upgrade
    logqueue_folder = ::File.join(server_location, 'server', 'logqueue')
    if ::File.directory?(logqueue_folder) && !Dir["#{logqueue_folder}/*"].empty?()
      error_msg = "Existing server's logqueue folder contains unprocessed log files, won't proceed"
      raise(error_msg)
    end

  end

  # Existing server running check
  raise('Control Center running, Please shutdown the server') if Server::Config.detect_service_running?(node)

else
  if node['installation_mode'] == 'upgrade' || node['installation_mode'] == 'remove'
    # no existing server found for upgrade or remove
    # can't proceed
    # exit with proper message
    raise("[Precheck] Unable to proceed #{node['installation_mode']}, no existing server found")
  end
end

# DB connectivity check (only check when fresh install)
begin

  begin
    db_connection_result = Utility::DB.test_db_connection(
      node['db_connection_url'].dup().gsub('"', '\"'),
      node['db_username'],
      node['db_password'],
      node['db_ssl_certificate'] == "" ? "NA" : node['db_ssl_certificate'],
      node['db_server_dn'],
      node['jre_x_path'],
      node['support_classpath'],
      tries=3,
      seconds=20)
  rescue Exception => ex
    raise("Got exception when trying to connect to database: #{ex.message}")
  end

  if !db_connection_result
    raise('Failed to connect to given Database')
  else
    Chef::Log.info('[Precheck] DB Connection test succeed')
  end

end if node['installation_mode'] == 'install' && Server::Config.init_db?(node)

# SMTP connectivity check (only check when fresh install)
begin

  begin
    smtp_connection_result = Utility::SMTP.test_SMTP_connection(
      node['mail_server_url'],
      node['mail_server_port'],
      node['mail_server_username'],
      node['mail_server_password'],
      node['mail_server_ssl'] )
  rescue Exception => ex
    raise("Got exception when trying to connect to given Mail Server: #{ex.message}")
  end
  
  if !smtp_connection_result
    raise('Failed to connect to given Mail Server')
  else
    Chef::Log.info('[Precheck] Succeed to connect to given Mail Server')
  end

end if node['installation_mode'] == 'install' &&
    node['mail_server_url'].to_s.strip.length != 0 && !node['skip_smtp_check']

unless platform?('windows')
  if !::File.exist?("/sbin/setcap")
    raise('setcap not installed.')
  end
end

Chef::Log.info('[Precheck] Finished precheck, good to go.')

