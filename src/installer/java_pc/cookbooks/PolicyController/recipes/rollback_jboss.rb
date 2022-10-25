#
# Cookbook Name:: PolicyController
# Recipe:: rollback_jboss
#     This handle the rollback precedures on jboss installer failures
#
# Copyright 2015, Nextlabs Inc.
# Author:: Amila Silva
#
# All rights reserved - Do Not Redistribute
#
require 'fileutils'

puts "[Install]: JBoss rollback started on failure ....."


directory 'removeNextLabsDir' do
  path      node['dpc_path']
  provider  Chef::Provider::Directory
  recursive true
  action :nothing
end


ruby_block "rollback_jboss_files" do
  block do
    if (node['jboss_installation_type'] == "domain")
      jbossXml = node['installation_dir'] + "/domain/configuration/domain.xml"
    else
      jbossXml = node['installation_dir'] + "/standalone/configuration/standalone.xml"
    end

    bk_file_name = jbossXml + "_bk"
    file_name = jbossXml
    
    if ::File.exist?(bk_file_name)
    	FileUtils.cp(bk_file_name, file_name)
    end

    $installationSuccess = false
  end
  notifies :delete, 'directory[removeNextLabsDir]', :immediately
end
