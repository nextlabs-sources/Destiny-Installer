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

puts "[Install]: Clean-up backup files - JBoss"

ruby_block "rollback_jboss_files" do
  block do
    if (node['jboss_installation_type'] == "domain")
      jbossXml = node['installation_dir'] + "/domain/configuration/domain.xml"
    else
      jbossXml = node['installation_dir'] + "/standalone/configuration/standalone.xml"
    end

    bk_file_name = jbossXml + "_bk"
    if ::File.exist?(bk_file_name)
    	FileUtils.rm(bk_file_name)
    end

    puts "[Install]: Backup file deleted successfully"
  end
end
