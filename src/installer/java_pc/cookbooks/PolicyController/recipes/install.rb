#
# Cookbook Name:: PolicyController
# Recipe:: install
#     This handle the installer
#
# Copyright 2015, Nextlabs Inc.
# Author:: Amila Silva
#
# All rights reserved - Do Not Redistribute
#


puts "::::::::::::::::::::::::::::  Install - Start :::::::::::::::::::::::::::::::"

$installationSuccess = false

def installOnPlatform(serverType)
  case node["platform_family"]
  when "windows"
    puts "[Install]: Windows Installation started"
	platform = 'windows'
    if serverType == 'TOMCAT'
      begin
        include_recipe 'PolicyController::install_tomcat_windows'
	  rescue
    	puts "[Install]: Installation process failed"
    	include_recipe 'PolicyController::rollback_tomcat'
	  end
    else
      begin
		include_recipe 'PolicyController::install_jboss_windows'
	  rescue
    	puts "[Install]: Installation process failed"
    	include_recipe 'PolicyController::rollback_jboss'
	  end
    end
  else
    puts "[Install]: Linux Installation started"
    if serverType == 'TOMCAT'
      begin
        include_recipe 'PolicyController::install_tomcat_linux'
   	  rescue
    	puts "[Install]: Installation process failed"
    	include_recipe 'PolicyController::rollback_tomcat'
	  end
    else
      begin
		include_recipe 'PolicyController::install_jboss_linux'
	  rescue
    	puts "[Install]: Installation process failed"
    	include_recipe 'PolicyController::rollback_jboss'
	  end
    end
  end
end

installOnPlatform( node["server_type"] )

ruby_block "copy-version-file" do
  block do
    require 'fileutils'
    FileUtils.cp(
        ::File.join(ENV['START_DIR'].gsub("\\", '/'), 'version.txt'),
        ::File.join(node['dpc_path'])
    )
  end
  ignore_failure true
end

ruby_block "handle-rollback-on-failure" do
  block do
	if !$installationSuccess
	   if node["server_type"]  == 'TOMCAT'
		     run_context.include_recipe 'PolicyController::rollback_tomcat'
	   else
		     run_context.include_recipe 'PolicyController::rollback_jboss'
	   end
	end
  end
end

ruby_block "clean-up-backupfiles" do
  block do
	   if node["server_type"]  == 'TOMCAT'
		     run_context.include_recipe 'PolicyController::cleanup_backups_tomcat'
	   else
		     run_context.include_recipe 'PolicyController::cleanup_backups_jboss'
	   end
  end
end

directory 'removeTempDir' do
    path      node['temp_dir'] + '/jpc/'
    provider  Chef::Provider::Directory
    recursive true
	action :nothing
end

ruby_block "clean-up" do
   block do

   end
   notifies :run, 'ruby_block[clean-up-backupfiles]', :immediately
   notifies :delete, 'directory[removeTempDir]', :immediately
   puts "Temp Directory cleaned successfully"
 end

 ruby_block "end-of-install" do
   block do
     if $installationSuccess
       message = "Installation completed"
     else
       message = "Installation rollback with error"
     end
    puts "[Install]: #{message}"
    puts "::::::::::::::::::::::::::::  Install - End :::::::::::::::::::::::::::::::::"
   end
 end
