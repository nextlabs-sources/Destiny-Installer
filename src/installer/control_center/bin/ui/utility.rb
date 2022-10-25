#! /usr/bin/env ruby
# encoding: utf-8
#
# Java Policy Controller Installer GUI Utility
#
#@author::     Duan Shiqiang
#@copyright::  Nextlabs Inc.
#
require 'json'
require 'resolv'
require 'tmpdir'

module Utility

  ReadableNames = JSON.parse(File.read(
      File.join(File.dirname(__FILE__), "message_properties.json"), :encoding => "utf-8"))
  
  # use three level up folder as START_DIR
  # the START_DIR should contain the cookbook folder
  START_DIR = File.expand_path('../../..', __FILE__)
  ORIGINAL_LOG_LOCATION = ( ENV['UI_LOG_LOCATION'] || File.join(START_DIR, 'installer.log') ).gsub("\\", "/")
  # CHEF_JSON_PROPERTIES_FILE_LOCATION is the location where after installation, the cc_properties.json file
  # been copied to for later reference.
  CHEF_JSON_PROPERTIES_FILE_BACKUP_LOCATION = \
      ( ENV['PROPERTIES_FILE_BACKUP_LOCATION'] || File.join(START_DIR, "cc_properties_ui.json") ).gsub("\\", "/")

  # The service name of the control center
  CC_SERVICE_NAME = "CompliantEnterpriseServer"
  LICENSE_FILE_NAME = "license.dat"

  module Validator
    # validator modules includes some valiators that are 
    # methods that accept an input
    # and returns (valid, error_msg) 
    @@validator_errors_msgs = ReadableNames["validator_errors"] ? ReadableNames["validator_errors"] : 
        nil

    def self.validate_ip ip
      # ip address or localhost
      # for validate ip adreess, refer to http://goo.gl/RsnfkC
      valid = ((ip.eql? "localhost") || ip =~ Resolv::IPv4::Regex) ? true : false
      error_msg = valid ? "" : 
          ( ( @@validator_errors_msgs and @@validator_errors_msgs["ip"] ) or "not a valid ip" )
      return valid, error_msg
    end

    def self.validate_hostname hostname
      # valid hostname, refer to http://goo.gl/x2x0dY'
      validate_hostname_lambda = lambda { |hostname|
        if hostname.length > 255 then
          return false
        end
        hostname = hostname[0..-2] if ( hostname[-1].eql? "." )
        if hostname.split(".").select { |chunk| 
          chunk =~ /^(?!-)[A-Z\d\-_]{1,63}(?<!-)$/i
          }.length == hostname.split(".").length then
          return true
        else
          return false
        end
      }

      valid = validate_hostname_lambda.call hostname
      error_msg = valid ? "" :
          ( ( @@validator_errors_msgs and @@validator_errors_msgs["hostname"] ) or "not a valid ip hostname" )
      return valid, error_msg
    end

    def self.validate_port port
      valid = ((port =~ /^[1-9]\d{0,4}$/) and port.to_i <= 65535) ? true : false
      error_msg = valid ? "" :
          ( ( @@validator_errors_msgs and @@validator_errors_msgs["port"] ) or "not a valid port" )
      return valid, error_msg
    end

    def self.validate_dir dir
      # if the directory does not exits it will return false
      valid = (FileTest.directory? dir) ? true : false
      error_msg =  valid ? '' :
          ( ( @@validator_errors_msgs and @@validator_errors_msgs["dir"] ) or "the directory is not exist or valid" )

      return valid, error_msg
    end

    def self.linux_installation_dir dir
      # if the installation is under linux, then path with space will result into some strange behavior
      if RUBY_PLATFORM =~ /linux/
        valid = dir.include?(' ') ? false : true
        error_msg = valid ? '' :
            ( ( @@validator_errors_msgs and @@validator_errors_msgs["dir_contain_space"] ) or "the directory path should not contain space" )
      else
        valid = true
        error_msg = ''
      end
      return valid, error_msg
    end

    def self.validate_file_exist path
      valid = (FileTest.file? path) ? true : false
      error_msg = valid ? "" :
          ( ( @@validator_errors_msgs and @@validator_errors_msgs["file"] ) or "the file you specified is not exist" )
      return valid, error_msg
    end
    
    def self.validate_non_empty input
      valid = ((input != nil) and (input != ""))
      error_msg =  valid ? "" :
          ( ( @@validator_errors_msgs and @@validator_errors_msgs["non_empty"] ) or "should not be empty" )
      return valid, error_msg
    end

    def self.validate_store_password input
      valid = (input =~ /^(?:(?=.*\d)(?=.*[A-Z])(?=.*[a-z])(?=.*[^A-Za-z0-9]))(?!.*(.)\1{2,})[A-Za-z0-9!~`<>,;:_=?*+#.'\\"&%()\|\[\]\{\}\-\$\^\@\/]{10,128}$/)
      error_msg =  valid ? "" :
          ( ( @@validator_errors_msgs and @@validator_errors_msgs["key_tool_password"] ) or "must be between 10 and 128 non-whitespace characters, and must contain at least one number, one lowercase letter, one uppercase letter, one non-alphanumeric character, and contain no more than two identical consecutive characters" )
      return valid, error_msg
    end

    def self.validate_user_password input
      valid = (input =~ /^(?:(?=.*\d)(?=.*[A-Z])(?=.*[a-z])(?=.*[^A-Za-z0-9]))(?!.*(.)\1{2,})[A-Za-z0-9!~`<>,;:_=?*+#.'\\"&%()\|\[\]\{\}\-\$\^\@\/]{10,128}$/)
      error_msg = valid ? "" :
          ( ( @@validator_errors_msgs and @@validator_errors_msgs["user_password"] ) or "must be between 10 and 128 non-whitespace characters, and must contain at least one number, one lowercase letter, one uppercase letter, one non-alphanumeric character, and contain no more than two identical consecutive characters" )
      return valid, error_msg
    end
    
    def self.validate_transportation_mode input
      valid = (input =~ /^(PLAIN|SANDE)/)
      error_msg = valid ? "" :
          ( ( @@validator_errors_msgs and @@validator_errors_msgs["data_transportation_mode"] ) or "should be PLAIN or SANDE" )
      return valid, error_msg
    end
    
    def self.validate_shared_key input
      valid = (input =~ /^[A-Za-z0-9]{43}=$/)
      error_msg = valid ? "" :
          ( ( @@validator_errors_msgs and @@validator_errors_msgs["data_transportation_shared_key"] ) or "should be 44 characters in length, starts with alphanumeric, ended with =" )
      return valid, error_msg
    end
    
    def self.validate_plain_text_import_flag input
      valid = (input =~ /^(ON|OFF)/)
      error_msg = valid ? "" :
          ( ( @@validator_errors_msgs and @@validator_errors_msgs["data_transportation_plain_text_import"] ) or "should be ON or OFF" )
      return valid, error_msg
    end
    
    def self.validate_plain_text_export_flag input
      valid = (input =~ /^(ON|OFF)/)
      error_msg = valid ? "" :
          ( ( @@validator_errors_msgs and @@validator_errors_msgs["data_transportation_plain_text_export"] ) or "should be ON or OFF" )
      return valid, error_msg
    end
  end

  class Item

    attr_reader :installation_dir, :super_user_name, 
                :license_file_location, :admin_user_password, 
                :trust_store_password, :key_store_password, 
                :installation_mode, :installation_type, 
                :dms_component, :dac_component, :dps_component, 
                :dem_component, :admin_component, :cc_console_component,
                :reporter_component, :dabs_component, :dkms_component, 
                :installed_cc_host, :installed_cc_port, 
                :skip_smtp_check, 
                :web_service_port, :web_application_port, :config_service_port,
                :database_type, :db_connection_url, :db_connection_url_template, :db_username, :db_password, 
                :db_ssl_connection,:db_hostname, :db_port, :db_name, 
                :db_validate_server, :db_ssl_certificate, :db_server_dn, :db_validate_server_dn,
                :mail_server_url, :mail_server_port, :mail_server_username, 
                :mail_server_password, :mail_server_from, :mail_server_to,
                :console_install_mode, :data_transportation_mode,
                :data_transportation_shared_key, :data_transportation_plain_text_import,
                :data_transportation_plain_text_export
    
    attr_writer :installation_dir, :super_user_name, 
                :license_file_location, :admin_user_password, 
                :trust_store_password, :key_store_password, 
                :installation_mode, :installation_type, 
                :dms_component, :dac_component, :dps_component, :cc_console_component,
                :dem_component, :admin_component, 
                :reporter_component, :dabs_component, :dkms_component, 
                :installed_cc_host, :installed_cc_port, 
                :skip_smtp_check, 
                :web_service_port, :web_application_port, :config_service_port,
                :database_type, :db_connection_url, :db_connection_url_template, :db_username, :db_password,  
                :db_ssl_connection, :db_hostname, :db_port, :db_name, 
                :db_validate_server, :db_ssl_certificate, :db_server_dn, :db_validate_server_dn,
                :mail_server_url, :mail_server_port, :mail_server_username, 
                :mail_server_password, :mail_server_from, :mail_server_to, 
                :console_install_mode, :data_transportation_mode, 
                :data_transportation_shared_key, :data_transportation_plain_text_import,
                :data_transportation_plain_text_export

    SETUP_COMPONENTS = %w[
      dms_component
      dac_component
      dps_component
      dem_component
      admin_component
      reporter_component
      dabs_component
      dkms_component
      cc_console_component
    ]

    DATABASE_TYPES = %w[MSSQL ORACLE]
    DATABASE_DEFAULT_PORTS = {
      'MSSQL_PORT' => '1433',
      'ORACLE_PORT' => '1521',
      'POSTGRES_PORT' => '5432'
    }
    
    DB_CONNECTION_URL_TEMPLATES = {
      'MSSQL' => 'sqlserver://<HOSTNAME>:<PORT>;databaseName=<INSTANCE_NAME>',
      'MSSQL_SSL' => 'sqlserver://<HOSTNAME>:<PORT>;databaseName=<INSTANCE_NAME>;integratedSecurity=false;encrypt=true;trustServerCertificate=true',
      'MSSQL_SSL_VALIDATE' => 'sqlserver://<HOSTNAME>:<PORT>;databaseName=<INSTANCE_NAME>;integratedSecurity=false;encrypt=true;trustServerCertificate=false;hostNameInCertificate=<HOST_DN>',
      'ORACLE' => 'oracle:thin:@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=<HOSTNAME>)(PORT=<PORT>))(CONNECT_DATA=(SID=<INSTANCE_NAME>)))',
      'ORACLE_SSL' => 'oracle:thin:@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCPS)(HOST=<HOSTNAME>)(PORT=<PORT>))(CONNECT_DATA=(SID=<INSTANCE_NAME>)))',
      'ORACLE_SSL_VALIDATE' => 'oracle:thin:@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCPS)(HOST=<HOSTNAME>)(PORT=<PORT>))(CONNECT_DATA=(SID=<INSTANCE_NAME>))(SECURITY=(SSL_SERVER_CERT_DN="<HOST_DN>")))'
    }
    def initialize

      config_file_path = File.join(File.dirname(__FILE__), "config.json")
      
      external_config = nil
      begin
        external_config = JSON.parse(File.read(config_file_path))
        external_config_defaults = external_config["defaults"]
        case RUBY_PLATFORM
        when /mswin|mingw|windows/ then # we are on windows
          external_config_defaults.merge!(external_config["defaults_win"]) if external_config["defaults_win"]
        when /linux/ then# we are on linux
          external_config_defaults.merge!(external_config["defaults_linux"]) if external_config["defaults_linux"]
        end
      rescue Errno::ENOENT, JSON::ParserError
        external_config = nil
      end

      @installation_dir           = external_config ? external_config_defaults["installation_dir"]             : ""
      @super_user_name            = external_config ? external_config_defaults["super_user_name"]              : "Administrator"
      
      @web_service_port           = external_config ? external_config_defaults["web_service_port"]             : "8443"
      @web_application_port       = external_config ? external_config_defaults["web_application_port"]         : "443"
      @config_service_port        = external_config ? external_config_defaults["config_service_port"]          : "7443"
      @admin_user_password        = external_config ? external_config_defaults["admin_user_password"]          : ""
      @trust_store_password       = external_config ? external_config_defaults["trust_store_password"]         : ""
      @key_store_password         = external_config ? external_config_defaults["key_store_password"]           : ""

      # set all components to true for default
      SETUP_COMPONENTS.each do |component|
        self.instance_variable_set("@"+component, "ON")
      end

      @installation_type          = external_config ? external_config_defaults["installation_type"]            : "complete"
      @installed_cc_host          = external_config ? external_config_defaults["installed_cc_host"]            : ""
      @installed_cc_port          = external_config ? external_config_defaults["installed_cc_port"]            : "8443"

      @database_type              = external_config ? external_config_defaults["database_type"]                : "MSSQL"
      @db_ssl_connection          = external_config ? external_config_defaults["db_ssl_connection"]            : "false"
      @db_hostname                = external_config ? external_config_defaults["db_hostname"]                  : ""
      @db_port                    = external_config ? external_config_defaults["db_port"]                      : "1433"
      @db_name                    = external_config ? external_config_defaults["db_name"]                      : ""
      @db_username                = external_config ? external_config_defaults["db_username"]                  : ""
      @db_password                = external_config ? external_config_defaults["db_password"]                  : ""
      @db_validate_server         = external_config ? external_config_defaults["db_validate_server"]           : "false"
      @db_ssl_certificate         = external_config ? external_config_defaults["db_ssl_certificate"]           : ""
      @db_server_dn               = external_config ? external_config_defaults["db_server_dn"]                 : ""
      @db_validate_server_dn      = external_config ? external_config_defaults["db_validate_server_dn"]        : "false"
        
      @data_transportation_mode   = external_config ? external_config_defaults["data_transportation_mode"]     : "PLAIN"
      @data_transportation_shared_key         = external_config ? external_config_defaults["data_transportation_shared_key"]              : ""
      @data_transportation_plain_text_import  = external_config ? external_config_defaults["data_transportation_plain_text_import"]       : "false"
      @data_transportation_plain_text_export  = external_config ? external_config_defaults["data_transportation_plain_text_export"]       : "false"

      @mail_server_url            = external_config ? external_config_defaults["mail_server_url"]              : ""
      @mail_server_port           = external_config ? external_config_defaults["mail_server_port"]             : "25"
      @mail_server_username       = external_config ? external_config_defaults["mail_server_username"]         : ""
      @mail_server_password       = external_config ? external_config_defaults["mail_server_password"]         : ""
      @mail_server_from           = external_config ? external_config_defaults["mail_server_from"]             : ""
      @mail_server_to             = external_config ? external_config_defaults["mail_server_to"]               : ""

      # Temporary directory for copy and prepare installation artefacts
      @temp_dir                   = external_config ? external_config_defaults["temp_dir"]          : Dir.tmpdir()

      @installation_mode          = 'install' # install, upgrade, remove
      @console_install_mode       = 'OPN' # OPL, OPN, SAAS
      @temp_dir                   = Dir.tmpdir

      @skip_smtp_check            = false

      # initialize license file location if it's existed under start directory
      if ( File.exists? File.join(START_DIR, LICENSE_FILE_NAME))
        @license_file_location = File.join(START_DIR, LICENSE_FILE_NAME)
      else
        @license_file_location = ""
      end

    end

    def to_json(*fields_to_nil)
      hash = {}

      self.instance_variables.each { |var|
        hash[var.to_s.delete("@")] = self.instance_variable_get(var)
      }

      # we don't need to specify super_user_name
      hash.delete("super_user_name")

      # delete unnecessary fields for remove or upgrade
      if self.installation_mode == 'remove' || self.installation_mode == 'upgrade'
        %w[installation_dir admin_user_password license_file_location
          trust_store_password key_store_password
          installation_type console_install_mode
          dms_component dac_component dps_component
          dem_component admin_component
          reporter_component dabs_component dkms_component cc_console_component
          installed_cc_host installed_cc_port
          skip_smtp_check
          web_service_port web_application_port
          config_service_port config_service_port
          database_type db_connection_url db_username db_password
          mail_server_url mail_server_port mail_server_username
          mail_server_password mail_server_from mail_server_to].each do |field|
          hash.delete(field)
        end
      end

      # mask fields specified
      fields_to_nil.each do |field|
        hash[field] = nil if hash.has_key?(field)
      end

      return JSON.pretty_generate(hash)
    end

    def save_config_to_temp_dir
      temp_config_path = File.join(Dir::tmpdir, "cc_properties.json")
      File.open(temp_config_path, 'w') do |file|
        file.write(self.to_json)
      end
      return temp_config_path
    end

    def validate_fields *fields

      # validate certain fields
      # Params
      # +fields+:: The instance variable names, strings, such as "server_ip"
      validators = {
        'installation_dir'                      => [:validate_non_empty, :linux_installation_dir, :validate_dir],
        'license_file_location'                 => [:validate_non_empty, :validate_file_exist],
        'admin_user_password'                   => [:validate_non_empty, :validate_user_password],
        'trust_store_password'                  => [:validate_non_empty, :validate_store_password],
        'key_store_password'                    => [:validate_non_empty, :validate_store_password],
        'installed_cc_host'                     => [:validate_non_empty, :validate_hostname],
        'installed_cc_port'                     => [:validate_non_empty, :validate_port],
        'db_hostname'                           => [:validate_non_empty],
        'db_port'                               => [:validate_non_empty, :validate_port],
        'db_name'                               => [:validate_non_empty],
        'db_username'                           => [:validate_non_empty],
        'db_password'                           => [:validate_non_empty],
        'db_ssl_certificate'                    => [:validate_non_empty],
        'db_server_dn'                          => [:validate_non_empty],
        'web_service_port'                      => [:validate_non_empty, :validate_port],
        'web_application_port'                  => [:validate_non_empty, :validate_port],
        'config_service_port'                   => [:validate_non_empty, :validate_port],
        'data_transportation_mode'              => [:validate_non_empty, :validate_transportation_mode],
        'data_transportation_shared_key'        => [:validate_non_empty],
        'data_transportation_plain_text_import' => [:validate_plain_text_import_flag],
        'data_transportation_plain_text_export' => [:validate_plain_text_export_flag],
        'mail_server_url'                       => [:validate_non_empty],
        'mail_server_port'                      => [:validate_non_empty, :validate_port],
        'mail_server_username'                  => [:validate_non_empty],
        'mail_server_password'                  => [:validate_non_empty],
        'mail_server_from'                      => [:validate_non_empty],
        'mail_server_to'                        => [:validate_non_empty]
      }
      error_field = nil
      error_msg = ""

      fields.each do |field|

        validators[field].each do |validator|
          valid, err_msg = Validator.method(validator).call(
              self.instance_variable_get(("@"+field).to_sym) )
          if not valid then
            error_field = field
            error_msg = ReadableNames["ErrorMsgTemplate"] % 
                [ReadableNames["inputs"][field], err_msg]
            break
          end
        end
        
        break if (error_field != nil)

      end

      if error_field != nil then 
        return [false, error_field, error_msg]
      else
        return [true, nil, nil]
      end

    end
    
  end
  
  def self.start_service
    # start the installed service
    case RUBY_PLATFORM
      when /mswin|mingw|windows/ # we are on windows
        `sc start #{CC_SERVICE_NAME}`
      else # we are on linux
        `service #{CC_SERVICE_NAME} start`
    end
  end

end

Dir[File.expand_path(File.dirname(__FILE__)) + '/libraries/*.rb'].each {|file|
  require file
}
