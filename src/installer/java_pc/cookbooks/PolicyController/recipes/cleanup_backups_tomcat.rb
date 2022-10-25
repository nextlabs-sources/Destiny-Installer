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

puts "[Install]: Clean-up backup files - Tomcat"

ruby_block "rollback_tomcat_files" do
  block do

    bk_file_name = ENV['CATALINA_HOME'] + "/conf/server.xml_bk"
    FileUtils.rm(bk_file_name)

    bk_file_name = ENV['CATALINA_HOME'] + "/conf/catalina.properties_bk"
    FileUtils.rm(bk_file_name)

    puts "[Install]: Backup file deleted successfully"
    $installationSuccess = false
  end
end
