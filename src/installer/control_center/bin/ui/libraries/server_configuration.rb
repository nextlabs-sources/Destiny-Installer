#
# library:: server_configuration
#     library for check existing server installation details
#     such as whether there's existing server installed, and it's version
#
# Copyright 2015, Nextlabs Inc.
# Author:: Duan Shiqiang
#
# All rights reserved - Do Not Redistribute
#
require 'win32/service' if RUBY_PLATFORM =~ /mswin|mingw|windows/
require 'win32/registry' if RUBY_PLATFORM =~ /mswin|mingw|windows/
require 'fileutils'

module Server
  module Config

    # a cache for detected existing server
    @@existing_server = nil

    # Control Center Policy Server service name before version 7.7 on windows
    SERVICE_NAME_WIN_MSI = 'EnterpriseDLPServer'

    # Control Center Registry Key name (under HKEY_LOCAL_MACHINE)
    REGISTY_KEY_NAME = %q[SOFTWARE\Wow6432Node\NextLabs,Inc.\ControlCenter]

    

    # //////////////////////////////////////////////////////////
    # This method returns the default server.config path for storing information
    # needed for installer and service starting up such as 
    # installation version, installation directory
    # ////////////////////////////////////////////////////////// 
    def self.linux_server_config_path(node)
      return "/etc/#{node['linux']['service_name']}/server.conf"
    end


    # ////////////////////////////////////////////////////////// 
    # This method scans the current system and populate an entry on node
    # The entry name is @@existing_server with attributes: 
    #   exist: boolean
    #   version: string (e.g. "7.7")
    #   install_path: string (e.g. "C:/Program Files/Nextlabs/PolicyServer")
    # //////////////////////////////////////////////////////////
    def self.check_existing_server(node, force=false)

      begin

        @@existing_server = Hash.new

        case RUBY_PLATFORM
          when /mswin|mingw|windows/
            access = Win32::Registry::KEY_READ
            begin
              reg = Win32::Registry::HKEY_LOCAL_MACHINE.open(REGISTY_KEY_NAME, access)
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

    def self.stop_service(node)
      if detect_service_running?(node)
        case RUBY_PLATFORM
          when /mswin|mingw|windows/
            # server installed using MSI, service name is different
            if is_existing_server_msi?
              win_service_name = SERVICE_NAME_WIN_MSI
            else
              win_service_name = node["winx"]["service_name"]
            end
            `net stop #{win_service_name}`
            # net stop doesn't return anything other than 0
            unless detect_service_running?(node)
              return true
            else
              return false
            end
          when /linux/
            `service #{node['linux']['service_name']} stop`
            if $?.exitstatus == 0
              return true
            else
              return false
            end
          else
            puts "Sorry, your platform [#{RUBY_PLATFORM}] is not supported..."
        end
      end
    end
    
  end
end
