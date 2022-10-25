#! /usr/bin/env ruby
# encoding: utf-8
#
# Java Policy Controller Installer GUI Utility
#
#@author::     Duan Shiqiang
#@copyright::  Nextlabs Inc.
#
require "json"
require "resolv"

Dir[File.expand_path(File.dirname(__FILE__)) + '/libraries/*.rb'].each {|file|
  require file
}

module Utility

	ReadableNames = JSON.parse(File.read(
			File.join(File.dirname(__FILE__), "message_properties.json"), :encoding => "utf-8"))

	# use three level up folder as START_DIR
	# the START_DIR should contain the cookbook folder
  START_DIR = File.dirname(File.dirname(File.expand_path(File.dirname(__FILE__))))
  LOG_LOCATION = ENV['UI_LOG_LOCATION'] || File.join(START_DIR, 'installer.log')
  # CHEF_JSON_PROPERTIES_FILE_LOCATION is the location where after installation, the cc_properties.json file
  # been copied to for later reference.
  CHEF_JSON_PROPERTIES_FILE_LOCATION = \
      ( ENV['PROPERTIES_FILE_LOCATION'] || File.join(START_DIR, "jpc_properties_ui.json") ).gsub("\\", "/")

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
			error_msg =  valid ? "" :
					( ( @@validator_errors_msgs and @@validator_errors_msgs["dir"] ) or "the direcotry is not exist or valid" )
			return valid, error_msg
		end

		def self.validate_non_empty input
			valid = ((input != nil) and (input != ""))
			error_msg =  valid ? "" :
					( ( @@validator_errors_msgs and @@validator_errors_msgs["non_empty"] ) or "should not be empty" )
			return valid, error_msg
		end

	end

	class Item
		Server_types 	= ["TOMCAT", "JBOSS"]
    # Agent type are using PROTAL by default, user don't need to choose.
		Agent_types 	= ["FILE_SERVER", "PORTAL"]

		attr_reader :server_ip, :server_port, :server_type, :agent_type,
					:policy_controller_host, :policy_controller_port, :cc_host, :cc_port, :drive_root_dir, :installation_dir, :dpc_path, :temp_dir,
					:jboss_installation_type, :valut_password
					
		attr_writer :server_ip, :server_port, :server_type, :agent_type,
					:policy_controller_host, :policy_controller_port, :cc_host, :cc_port, :drive_root_dir, :installation_dir, :dpc_path, :temp_dir,
					:jboss_installation_type, :valut_password
		
		def initialize()

			config_file_path = File.join(File.dirname(__FILE__), "config.json")
			if File.exists? config_file_path then
				external_config = JSON.parse(File.read(config_file_path))
				# when searching for a config, search defaults and platform dependent defauls
				external_config_defaults = external_config["defaults"]
				case RUBY_PLATFORM
				when /mingw/ then # we are on windows
					external_config_defaults = external_config_defaults.merge(external_config["defaults_win"])
				when /linux/ then# we are on linux
					external_config_defaults = external_config_defaults.merge(external_config["defaults_linux"])
				end
			else
				external_config = nil
			end

			# Current server ip 
			@server_ip									= external_config ? external_config_defaults["server_ip"] 		: "localhost"
			# Current server port
			@server_port								= external_config ? external_config_defaults["server_port"] 	: "8443"
			# Server_type: "JBOSS" - jboss-eap-6, "TOMCAT" - Apache Tomcat
			@server_type 								= external_config ? external_config_defaults["server_type"] 	: "JBOSS"
			# Agent type, values : PORTAL, FILE_SERVER
			@agent_type									= "PORTAL"
			# Policy Controller server host
			@policy_controller_host 		= external_config ? external_config_defaults["policy_controller_host"] : ""
			# Policy Controller server port 
			@policy_controller_port 		= external_config ? external_config_defaults["policy_controller_port"] : "8443"
			@cc_host										= external_config ? external_config_defaults["cc_host"]				: ""
			@cc_port										= external_config ? external_config_defaults["cc_port"] 			: "8443"
			# drive_name
			@drive_root_dir		 					= ""
			# server_root_dir
			@installation_dir 					= external_config ? external_config_defaults["installation_dir"] : ""
			# DPC Folder Path
			@dpc_path										= ""
			# Temporary directory for copy and prepare installation artefacts
			@temp_dir 									= external_config ? external_config_defaults["temp_dir"]			: (
																		RUBY_PLATFORM =~ /mingw/ ? "C:/temp" : "/tmp")

			# JBOSS required configurations
			# Jboss server mode. "standalone", "domain"
			@jboss_installation_type 		= "standalone"

			@required_disk_space_mb 		= external_config ? external_config["required_disk_space_mb"]		: 250
		end

		def to_json
			hash = {}
			self.instance_variables.each { |var|
				hash[var.to_s.delete("@")] = self.instance_variable_get(var)
			}

			# the dpc path for Jboss
			if @server_type == "JBOSS" then
				hash['dpc_path'] = File.join(@dpc_path, "dpc")
			end
			
			return JSON.pretty_generate(hash)
		end

		def save_config_to_temp_dir
			temp_config_path = File.join(Dir::tmpdir, "jpc_properties.json")
			File.open(temp_config_path, 'w') do |file|
				file.write(self.to_json)
			end
			return temp_config_path
		end

		def validate_fields *fields

			# validate certain fields
			# Params
			# +fields+:: The instance variable names, strings, such "server_ip"
			validators = {
				"server_ip" 							=> [:validate_non_empty, :validate_hostname],
				"server_port" 						=> [:validate_non_empty, :validate_port],
				"cc_port" 								=> [:validate_non_empty, :validate_port],
				"policy_controller_port" 	=> [:validate_non_empty, :validate_port],
				"cc_host" 								=> [:validate_non_empty, :validate_hostname],
				"installation_dir" 				=> [:validate_non_empty, :validate_dir],
				"dpc_path" 								=> [:validate_non_empty, :validate_dir],
				"temp_dir" 								=> [:validate_dir]
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
					break if error_field
				end

			end

			if error_field != nil then 
				return [false, error_field, error_msg]
			else
				return [true, nil, nil]
			end

		end

	end
	
	class Envs
		# Stores the environment variables for calling external script
		attr_writer :CATALINA_HOME
		attr_reader :CATALINA_HOME

		def initialize()
			@CATALINA_HOME = ""
		end

		def set var
			# Set the environment variables so that external script will have them set
			# Params
			# +var+:: The instance variable symbol, such as :@CATALINA_HOME
			if self.instance_variable_defined? var then
				ENV[var.to_s.delete('@')] = self.instance_variable_get(var)
			end
		end

	end

	def self.get_drive_names(installation_dir)
		# returns the root drive of the installation_dir
		# for example, on windows, if installation_dir is C:/Nextlabs, will return C:
		# on linux, will return like /dev/sda1
		# +installation_dir+:: should use / as path separator always

		case RUBY_PLATFORM
		when /mingw/ then # we are on windows
			return installation_dir.split(File::SEPARATOR)[0]
		when /linux/ then # we are on linux
			return `df #{installation_dir} | awk '{print $1}' | tail -n1`.strip
		else 
			puts "Sorry, your platform [#{RUBY_PLATFORM}] is not supported..."
		end
	end

end
