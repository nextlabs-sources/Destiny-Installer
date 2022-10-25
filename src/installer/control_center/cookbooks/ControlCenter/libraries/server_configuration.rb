#
# Cookbook Name:: ControlCenter
# library:: server_configuration
#     this will handle all modifications to the configuration.xml file
#
# Copyright 2015, Nextlabs Inc.
# Author:: Amila Silva & Duan Shiqiang
#
# All rights reserved - Do Not Redistribute
#

require 'fileutils'
require 'win32/service' if RUBY_PLATFORM =~ /mswin|mingw|windows/
require 'win32/registry' if RUBY_PLATFORM =~ /mswin|mingw|windows/
require 'socket'
require 'timeout'

module Server
  module Config

    # a cache for detected existing server
    @@existing_server = nil

    # Control Center Policy Server service name before version 7.7 on windows
    SERVICE_NAME_WIN_MSI = 'EnterpriseDLPServer'

    # Control Center Registry Key name (under HKEY_LOCAL_MACHINE)
    REGISTY_KEY_NAME = %q[SOFTWARE\Wow6432Node\NextLabs,Inc.\ControlCenter]

    # Control Center config store registry key name (under HKEY_LOCAL_MACHINE)
    REGISTRY_CONFIG_STORE_KEY_NAME = %q[SOFTWARE\Wow6432Node\NextLabs\Compliant Enterprise\Control Center\Remembered Properties]

    #  Encrypt Password
    def self.encrypt_password(node, password)

      begin
        escapedPw = password.dup
        # This line must be first
        escapedPw.gsub!('^', '^^')

        # Or else it will replace the ^ added by these lines
        escapedPw.gsub!('&', '^&');
        escapedPw.gsub!('<', '^<');
        escapedPw.gsub!('>', '^>');
        escapedPw.gsub!('(', '^(');
        escapedPw.gsub!(')', '^)');
        escapedPw.gsub!('@', '^@');
        escapedPw.gsub!('|', '^|');
        escapedPw.gsub!('-', '^-')

        cryptJarFile = "#{node['dist_server_dir']}/tools/crypt/crypt.jar"
        cmd = %Q["#{node['jre_x_path']}" -jar "#{cryptJarFile}" -e -w "#{escapedPw}"]
        
        pipe = IO.popen(cmd)
        result = pipe.readline.strip
        if pipe != nil
          return result
        else
          puts 'Password encryption failed'
          return ''
        end
      rescue
        puts 'Unable to perform password encryption'
        return ''
      ensure
        if pipe != nil
          pipe.close
        end
      end

    end

    # Decrypt Password
    # This method required node has an attribute 'decrypt_jar' which is a path to decrypt.jar
    def self.decrypt_password(node, password)
      begin
        cryptJarFile = "#{node['dist_server_dir']}/tools/crypt/crypt.jar"
        classpath_separator = if  RUBY_PLATFORM =~ /mswin|mingw|windows/ then ';' else ':' end
        cmd = %Q[
        #{node['jre_x_path']}
        -cp "#{node['decrypt_jar'] + classpath_separator + cryptJarFile}"
        Decrypt #{password}
        ].gsub("\n", ' ')
        pipe = IO.popen(cmd)
        result = pipe.readline.strip
        if pipe != nil
          return result
        else
          puts 'Password decryption failed'
          return ''
        end
      rescue
        puts 'Unable to perform password decryption'
        return ''
      ensure
        if pipe != nil
          pipe.close
        end
      end
    end

    #  Replece the tokens in given file
    #   This method reads the file specified as the filename line by line
    #   replace according to the token and replacement
    #   save the result to a tempfile
    #   after all lines, override the original file Params:
    #   +token_value_hash+:: A hash with token as key and replacement value as value
    def self.replace_in_file( template_file_path, filename, token_value_hash )

      begin
        result_file = File.open(filename, "w:UTF-8")
        template_file = File.open(template_file_path, "r:UTF-8")

        template_file.each do |line|
          token_value_hash.each do |key, value|
            line.gsub!(key.to_s, value.to_s)
          end
          result_file.puts line
        end
        result_file.fdatasync unless RUBY_PLATFORM =~ /mswin|mingw|windows/
      rescue IOError => error
        puts 'IOError occured: ' + error.message
        raise error
      ensure
        result_file.close if result_file
        template_file.close if template_file
      end

    end

    # This method returns the default server.config path for storing information
    # needed for installer and service starting up such as
    # installation version, installation directory
    def self.linux_server_config_path(node)
      "/etc/#{node['linux']['service_name']}/server.conf"
    end

    def self.linux_server_config_store_path(node)
      "/etc/#{node['linux']['service_name']}/#{node['linux']['config_store_file_name']}"
    end

    # //////////////////////////////////////////////////////////
    # This method returns the directory where windows stores the
    # start menu entries for the server
    # //////////////////////////////////////////////////////////
    def self.win_start_shortcut_path
      return File.join(ENV['PROGRAMDATA'], "Microsoft/Windows/Start Menu/Programs/Control Center")
    end

    # This method scans the current system and populate an entry on node
    # The entry name is @@existing_server with attributes:
    #   exist: boolean
    #   version: string (e.g. "7.7", "8.0", "8.0.1")
    #   install_path: string (e.g. "C:/Program Files/Nextlabs/PolicyServer")
    def self.check_existing_server(node, force=false)

      begin

        @@existing_server = Hash.new

        case RUBY_PLATFORM
          when /mswin|mingw|windows/
            access = Win32::Registry::KEY_READ
            begin
              reg = Win32::Registry::HKEY_LOCAL_MACHINE.open(node['REGISTY_KEY_NAME'], access)
              # try to read the version and install_path
              version = reg.read_s('Version').strip()
              install_path = reg.read_s('INSTALLDIR').strip().gsub("\\", '/')

              @@existing_server['exist'] = true
              @@existing_server['version'] = version
              @@existing_server['install_path'] = install_path

            rescue Win32::Registry::Error
              @@existing_server['exist'] = false
              @@existing_server['version'] = nil
              @@existing_server['install_path'] = nil
            end
          when /linux/
            begin
              # First initialize the hash
              @@existing_server['exist'] = false
              @@existing_server['version'] = ''
              @@existing_server['install_path'] = ''

              File.foreach(linux_server_config_path(node)) { |x|
                if match = x.match(/INSTALL_HOME\s*="?\s*([^\0\"]+)/i)
                  @@existing_server['exist'] = true
                  @@existing_server['install_path'] = match.captures[0].strip()

                elsif match = x.match(/Version\s*="?\s*(\d+(\.\d+)+)/i)
                  @@existing_server['version'] = match.captures[0].strip()
                end
              }

            rescue Errno::ENOENT
              @@existing_server['exist'] = false
              @@existing_server['version'] = nil
              @@existing_server['install_path'] = nil
            end
          else
            puts "Sorry, your platform [#{RUBY_PLATFORM}] is not supported..."
        end

        # only if the directory get from registry exist
        # we treat it as exist
        if @@existing_server['exist'] && !File.directory?(@@existing_server['install_path'])
          @@existing_server['exist'] = false
          @@existing_server['version'] = nil
          @@existing_server['install_path'] = nil
        end

        # if for some reason, the version we get is nil,
        # we need to try read the version file under server directory
        if @@existing_server['exist'] && (@@existing_server['version'] == nil || @@existing_server['version'] == '')
          @@existing_server['version'] = get_version_from_version_file(
              ::File.join(@@existing_server['install_path'], node['version_file_name']))
        end

        # then, we try format the version number got
        begin
          @@existing_server['version'] = @@existing_server['version'].match(/(\d+(\.\d+)+)/i).captures[0]
        rescue Exception
          Chef::Log.warn("The version number #{version} get from registry is not matching our format")
        end if @@existing_server['exist']

        # lastly, if the install_path ends with '/', we need to remove it
        if @@existing_server['exist'] && @@existing_server['install_path'].end_with?('/')
          @@existing_server['install_path'].chop!
        end
      end if (!@@existing_server)

    end

    # try to get the version number from version file
    def self.get_version_from_version_file(file_path)
      if ::File.exist?(file_path)
        ::File.foreach(file_path) { |x|
          if match = x.match(/Policy Server version\s*:\s*(\d+(\.\d+)+)/i)
            return match.captures[0].strip()
          end
        }
      end
      nil
    end

    # Returns true if new_version large then old_version
    # It will check the major version, minor version and maintenance version number and also the 4th number in order
    # for example, version 8.0.1's major version is 8, minor version is 0, maintenance version is 1
    # then, 8.0.1 will be treated newer than 8.0.0
    def self.server_version_newer?(old_version, new_version)
      old_version_components = old_version.to_s().split('.')
      new_version_components = new_version.to_s().split('.')
      # make sure the component array is at least length 3
      raise("version not valid: " + old_version.to_s()) if old_version_components.length < 1
      raise("version not valid: " + new_version.to_s()) if new_version_components.length < 1
      # change all string in the array to int
      old_version_components.map! {|x| x.to_i() }
      new_version_components.map! {|x| x.to_i() }
      while old_version_components.length < 4 do
        old_version_components.push(0)
      end
      while new_version_components.length < 4 do
        new_version_components.push(0)
      end

      for i in 0..3
        if old_version_components[i] < new_version_components[i]
          return true
        elsif old_version_components[i] > new_version_components[i]
          return false
        end
      end
      return false
    end

    # //////////////////////////////////////////////////////////
    #  Returns true is an control center server is already installed
    # //////////////////////////////////////////////////////////
    def self.has_any_server_installed?(node)
      check_existing_server(node) unless @@existing_server
      return @@existing_server["exist"]
    end

    # //////////////////////////////////////////////////////////
    #  Get already existing server's version
    # //////////////////////////////////////////////////////////
    def self.get_current_server_version(node)
      check_existing_server(node) unless @@existing_server
      return @@existing_server["version"]
    end

    # //////////////////////////////////////////////////////////
    #  Get already existing server's installation directory
    # //////////////////////////////////////////////////////////
    def self.get_current_installation_dir(node)
      check_existing_server(node) unless @@existing_server
      return @@existing_server["install_path"]
    end

    # Checks whether existing server is installed using MSI installer
    def self.is_existing_server_msi?
      Win32::Service.exists?(SERVICE_NAME_WIN_MSI)
    end

    # //////////////////////////////////////////////////////////
    #  Checks whether console's index.html file exist
    # //////////////////////////////////////////////////////////
    def self.get_installed_console_mode(node)
      check_existing_server(node) unless @@existing_server
      cc_console_index_file = ::File.join(@@existing_server['install_path'], 'server', 'tomcat', 'webapps', 'console', 'index.html')
      
      if ::File.exist?(cc_console_index_file)
        return "OPN"
      end
      
      dkms_folder = ::File.join(@@existing_server['install_path'], 'server', 'tomcat', 'work', 'dkms')
      dabs_folder = ::File.join(@@existing_server['install_path'], 'server', 'tomcat', 'work', 'dabs')
      dms_folder = ::File.join(@@existing_server['install_path'], 'server', 'tomcat', 'work', 'dms')
      
      if (::File.exist?(dkms_folder) && ::File.exist?(dabs_folder) && !::File.exist?(dms_folder))
        return "OPN"
      end
      
      return "OPL"
    end

    # //////////////////////////////////////////////////////////
    #  Detect the control center service is exist and running
    # //////////////////////////////////////////////////////////
    def self.detect_service_running?(node)

      check_existing_server(node) unless @@existing_server

      if @@existing_server["exist"]
        case RUBY_PLATFORM
          when /mswin|mingw|windows/
            # server installed using MSI, service name is different
            if is_existing_server_msi?
              win_service_name = SERVICE_NAME_WIN_MSI
            else
              win_service_name = node["winx"]["service_name"]
            end
            return Win32::Service.status(win_service_name)[:current_state] != 'stopped'
          when /linux/
            if File.exist?(node['linux']['pid_file'])
              `[ -n "$(ps -p $(cat #{node['linux']['pid_file']}) -o comm=)" ]`
              if $?.exitstatus == 0
                return true
              end
            end
            return false
          else
            puts "Sorry, your platform [#{RUBY_PLATFORM}] is not supported..."
        end
      else
        puts "No existing server found on the system"
        return false
      end

    end

    # Get machine's hostname (deprecated, chef's node contains hostname info)
    def self.get_machine_name()
      Socket.gethostname
    end

    # Get machine's FQDN (deprecated, chef's node contains FQDN)
    def self.get_hostname
      Socket.gethostbyname(Socket.gethostname)[0].downcase
    end

    # //////////////////////////////////////////////////////////
    # Database initialization required
    # //////////////////////////////////////////////////////////
    def self.init_db?(node)
      if node['install_as_master'] && (node['dms_component'].to_s.strip.eql? 'ON')
        return true
      else
        return false
      end
    end

    # //////////////////////////////////////////////////////////
    # Get the DMS host
    # //////////////////////////////////////////////////////////
    def self.get_DMS_host(node)
      if (node['installation_type'].to_s.strip.eql? 'custom') && ( node['installed_cc_host'].to_s.strip.length != 0)
        node['installed_cc_host'].to_s.strip
      else
        (node['fqdn'] || node['hostname']).downcase()
      end
    end

    # //////////////////////////////////////////////////////////
    # Get the DMS port
    # //////////////////////////////////////////////////////////
    def self.get_DMS_port(node)
      if (node['installation_type'].to_s.strip.eql? 'custom') && (node['installed_cc_port'].to_s.strip.length != 0)
        node['installed_cc_port'].to_s.strip
      else
        node['web_service_port'].to_s.strip
      end
    end

    # //////////////////////////////////////////////////////////
    # Get the DAC host
    # //////////////////////////////////////////////////////////
    def self.get_DAC_host(node)
      if (node['installation_type'].to_s.strip.eql? 'custom') && (node['installed_cc_host'].to_s.strip.length != 0)
        node['installed_cc_host'].to_s.strip
      else
        (node['fqdn'] || node['hostname']).downcase()
      end
    end

    # //////////////////////////////////////////////////////////
    # Get the DAC port
    # //////////////////////////////////////////////////////////
    def self.get_DAC_port(node)
      if node['installation_type'].to_s.strip.eql? 'custom' && node['installed_cc_port'].to_s.strip.length > 0
        node['installed_cc_port'].to_s.strip
      else
        node['web_service_port'].to_s.strip
      end
    end

    # //////////////////////////////////////////////////////////
    #  Get Drive root of given directory (only support local disk)
    #  The directory must exist on linux to get correct drive root
    #  e.g. given "C:/Program Files/Nextlabs" will return C:
    #       given "/opt/nextlabs" returns /dev/sda1
    #  +installation_dir+:: should use / as path separator always
    # //////////////////////////////////////////////////////////
    def self.get_drive_root(installation_dir)
      if match = installation_dir.match(/^([A-Za-z]:)/)
        return match.captures[0]
      elsif RUBY_PLATFORM =~ /linux/
        # the path is linux path
        return `df "#{installation_dir}" | head -2 | awk '{print $1}' | tail -n1`.strip
      else
        puts "Sorry, your platform [#{RUBY_PLATFORM}] is not supported..."
      end
    end

    #  Check whether the disk drive has enough space for instalaltion dir
    def self.disk_space_available?(node)
      driveRoot = get_drive_root(node['installation_dir'])
      availableDiskSpace = node['filesystem'][driveRoot]['kb_available']
      unless availableDiskSpace == nil
        availableDiskSpace = (availableDiskSpace.to_f / 1024.0).round(2)
        return (node['required_disk_space_mb'].to_f < availableDiskSpace)
      else
        Chef::Log.warn("Ohai didn't detect kb_available information about #{driveRoot}, so assume disk space enough.")
        return true
      end
    end

    # //////////////////////////////////////////////////////////
    #  Check whether the port is listening on the ip
    # //////////////////////////////////////////////////////////
    def self.port_open?(ip, port, seconds=2)
      begin
        Timeout::timeout(seconds) do
          begin
            s = TCPSocket.new(ip, port)
            s.close
            return true
          rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ENETUNREACH, Errno::EAFNOSUPPORT
            return false
          end
        end
      rescue Timeout::Error
      end
      return false
    end

    # Check whether elasticsearch is required for installation
    # Only icenet type installation we don't need elasticsearch
    def self.elasticsearch_component?(node)
      node['cc_console_component'].to_s.strip.eql?('ON') || \
        node['dms_component'].to_s.strip().eql?('ON')
    end

    # Get existing server's DB info and populate node
    # this method will try to read from configuration.xml file the db username, encrypted_password, and connection_url
    # it overrides the attributes of node : db_connection_url, db_username, db_encrypted_password, database_type
    def self.get_and_populate_db_info_from_configuration_xml(path, node)
      require 'rexml/document'
      file = ::File.new(path, mode='r')
      doc = REXML::Document.new(file)
      connection_pool_ele = doc.elements['DestinyConfiguration'].elements.to_a('Repositories/ConnectionPools/ConnectionPool').first
      node.override['db_connection_url'] = connection_pool_ele.get_text('ConnectString').to_s.sub('jdbc:', '').strip()
      node.override['db_username'] = connection_pool_ele.get_text('Username').to_s.strip()
      node.override['db_encrypted_password'] = connection_pool_ele.get_text('Password').to_s.strip()
      if node['db_connection_url'].match(/^sqlserver/)
        node.override['database_type'] = 'MSSQL'
      elsif node['db_connection_url'].match(/^oracle/)
        node.override['database_type'] = 'ORACLE'
      elsif node['db_connection_url'].match(/^postgresql/)
        node.override['database_type'] = 'POSTGRES'
      else
        Chef::Log.warn("Can't get the database_type")
      end
      node
    end
    
    def self.load_properties(properties_filename, properties)
      File.open(properties_filename, 'r') do |properties_file|
        properties_file.read.each_line do |line|
          line.strip!
          i = line.index('=')
          if (i)
            properties[line[0..i - 1].strip] = line[i + 1..-1].strip
          else
            properties[line] = ''
          end
        end      
      end
      properties
    end
      
    # Get existing server's DB info and populate node
    # this method will try to read from application.properties file the db username, encrypted_password, and connection_url
    # it overrides the attributes of node : db_connection_url, db_username, db_encrypted_password, database_type
    def self.get_and_populate_db_info_from_application_properties(path, node)
      properties = {}
      properties = load_properties(path, properties)
      node.override['db_ssl_certificate'] = properties['db.ssl.certificate']
      node.override['db_connection_url'] = properties['db.url'].to_s.sub('jdbc:', '').strip()
      node.override['db_username'] = properties['db.username']
      node.override['db_encrypted_password'] = properties['db.password']
      
      if node['db_connection_url'].match(/^sqlserver/)
        node.override['database_type'] = 'MSSQL'
      elsif node['db_connection_url'].match(/^oracle/)
        node.override['database_type'] = 'ORACLE'
      elsif node['db_connection_url'].match(/^postgresql/)
        node.override['database_type'] = 'POSTGRES'
      else
        Chef::Log.warn("Can't get the database_type")
      end
      node
    end

    # Get existing server's smtp info and populate node
    # it overrides the attributes of node: mail_server_url, mail_server_port, mail_server_username, mail_server_encrypted_password, mail_server_from
    def self.get_and_populate_smtp_info_from_configuration_xml(path, node)
      require 'rexml/document'
      file = ::File.new(path, mode='r')
      doc = REXML::Document.new(file)
      message_handler_ele = doc.elements['DestinyConfiguration/MessageHandlers'].elements.to_a('MessageHandler').first
	    if message_handler_ele
        property_eles = message_handler_ele.elements.to_a('Properties/Property')
        property_eles.each do |ele|
          case ele.get_text('Name').to_s
          when 'server'
            node.override['mail_server_url'] = ele.get_text('Value').to_s()
          when 'port'
            node.override['mail_server_port'] = ele.get_text('Value').to_s()
          when 'username'
            node.override['mail_server_username'] = ele.get_text('Value').to_s()
          when 'password'
            node.override['mail_server_encrypted_password'] = ele.get_text('Value').to_s()
          when 'default_from'
            node.override['mail_server_from'] = ele.get_text('Value').to_s()
          else
            nil
          end
        end
      end
      node
    end

    # Get existing ssl password and populate node
    # this method will try to read from server.xml file
    # it overrides the attributes of node : encrypted_key_store_password and encrypted_trust_store_password
    def self.get_and_populate_encrypted_password_from_server_xml(path, node)
      require 'rexml/document'
      file = ::File.new(path, mode='r')
      doc = REXML::Document.new(file)
      web_connector_ele = doc.elements.to_a("Server/Service[@name='CE-Apps']/Connector").first
      node.override['encrypted_key_store_password'] = web_connector_ele.attributes['keystorePass']
      node.override['encrypted_trust_store_password'] = web_connector_ele.attributes['truststorePass']
      node
    end

    def self.get_and_populate_web_application_port_from_server_xml(path, node)
      require 'rexml/document'
      file = ::File.new(path, mode='r')
      doc = REXML::Document.new(file)
      web_connector_ele = doc.elements.to_a("Server/Service[@name='CE-Apps']/Connector").first
      node.override['web_application_port'] = web_connector_ele.attributes['port'] unless web_connector_ele.attributes['port'] == ''
      node
    end
    
    private_class_method(:get_drive_root, :check_existing_server, :get_version_from_version_file)

  end unless defined?(Server::Config) # https://github.com/sethvargo/chefspec/issues/562#issuecomment-74120922
end
