#
# Cookbook Name:: PolicyController
# Recipe:: preCheck
#     This will do the pre checks for installer
#
# Copyright 2015, Nextlabs Inc.
# Author:: Amila Silva
#
# All rights reserved - Do Not Redistribute
#

require 'socket'
require 'timeout'


puts "::::::::::::::::::::::::::::  Pre Check :::::::::::::::::::::::::::::::::::::"

$preCheckSuccess = false;

  def port_open?(ip, port, seconds=1)
    Timeout::timeout(seconds) do
        begin
          TCPSocket.new(ip, port).close
          puts "[Precheck]: Server is running, Please shutdown server before start"
          true
        rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
          puts "[Precheck]: Server is not running"
          false
        end
      end
   rescue Timeout::Error
    puts "[Precheck]: Server is not running"
    false
  end

  def diskSpaceAvailable?(installationDir)
	begin
	    driveRoot = nil
	    maxSize = 0;
	    filtered_nodes = node['filesystem'].select do |key, value|
            if !value['mount'].nil? and !value['mount'].empty?
                if installationDir.start_with? value['mount'] and value['mount'].size > maxSize
                    driveRoot = value
                    maxSize = value['mount'].size
                end
            end
        end

		availableDiskSpace = (driveRoot['kb_available']).to_f/ 1024.0
		availableDiskSpace = availableDiskSpace.round(2)
		if (node['required_disk_space_mb'].to_f < availableDiskSpace)
		   puts "[Precheck]: available Disk Space #{availableDiskSpace} MB"
		   true
		else
		   puts "[Precheck]: No sufficient Disk Space #{availableDiskSpace} MB, Required :  #{node['required_disk_space_mb']} MB"
		   false
		end
	rescue Exception => ex
		puts "Didn't get filesystem info correctly, assuming disk space enough"
		true
	end
  end

  def getPlatform()
    case node["platform_family"]
    when "windows"
      return "WINDOWS"
    else
      return "LINUX"
    end
  end

  def checkInstalationDirExists(serverType, installationDir)

    if serverType == 'TOMCAT'
      if !ENV['CATALINA_HOME'].nil?
          return dirExists?(installationDir)
      else
        puts "[Precheck]:'CATALINA_HOME' not defined. Please set CATALINA_HOME before proceed"
        return false
      end
    else
      return dirExists?(installationDir)
    end
 end

  def dirExists?(installationDir)
    if (installationDir.nil?)
      puts "[Precheck]: Specified installation directory does not exists. #{installationDir}"
      return false
    end

    if File.directory?  installationDir
      puts "[Precheck]: Specified installation directory does exists."
      return true
    else
      puts "[Precheck]: Specified installation directory does not exists. #{installationDir}"
      return false
    end
  end

  def checkSuperUserHasAccess()
    case getPlatform()
      when 'WINDOWS'
        if( node['root_group'].to_s == "Administrators".to_s )
           puts "[Precheck]: Current user does have permission to perform this action"
           true
        else
          puts "[Precheck]: Current user does not have permission to perform this action"
          false
        end
      else
        if( node['root_group'].to_s == "root".to_s)
           puts "[Precheck]: Current user does have permission to perform this action"
           true
        else
          puts "[Precheck]: Current user does not have permission to perform this action"
          false
        end
    end
  end

  def isValidCCHost(ccHost, ccPort)
    if (ccHost.nil? || ccHost.empty?)
      puts "[Precheck]: Specified ICENET server host is not valid"
      return false
    elsif (ccPort.nil? || ccPort.empty?)
      puts "[Precheck]: Specified ICENET server port is not valid"
      return false
    else
      puts "[Precheck]: Valid ICENET server host and port"
      return true
    end
  end

  installDrive = node['drive_root_dir']
  installationDir = node['installation_dir']
  serverIp = node['server_ip']
  serverPort = node['server_port']
  serverType = node['server_type']
  ccHost = node['cc_host']
  ccPort = node['cc_port']

  $preCheckSuccess = diskSpaceAvailable?(installationDir) && checkInstalationDirExists(serverType, installationDir) && !port_open?(serverIp, serverPort) && checkSuperUserHasAccess() && isValidCCHost(ccHost, ccPort)

puts "::::::::::::::::::::::::::::  Pre Check - End :::::::::::::::::::::::::::::::"
