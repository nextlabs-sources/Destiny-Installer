#
# Cookbook Name:: PolicyController
# Recipe:: rollback_tomcat
#     This handle the rollback precedures on tomcat installer failures
#
# Copyright 2015, Nextlabs Inc.
# Author:: Amila Silva
#
# All rights reserved - Do Not Redistribute
#
require 'fileutils'

puts "[Install]: Tomcat rollback started on failure ....."

directory 'removeNextLabsDir' do
  path      node['dpc_path']
  provider  Chef::Provider::Directory
  recursive true
  action :nothing
end

ruby_block "rollback_tomcat_files" do
  block do

    bk_file_name = ENV['CATALINA_HOME'] + "/conf/server.xml_bk"
    file_name = ENV['CATALINA_HOME'] + "/conf/server.xml"
    FileUtils.cp(bk_file_name, file_name)

    bk_file_name = ENV['CATALINA_HOME'] + "/conf/catalina.properties_bk"
    file_name = ENV['CATALINA_HOME'] + "/conf/catalina.properties"
    FileUtils.cp(bk_file_name, file_name)

    $installationSuccess = false
  end
  notifies :delete, 'directory[removeNextLabsDir]', :immediately
end
