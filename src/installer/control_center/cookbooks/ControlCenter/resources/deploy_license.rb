#
# Cookbook Name:: ControlCenter
# Resource:: deploy_license
#
# Copyright 2016, Nextlabs Inc.
# Author:: Duan Shiqiang
#
# All rights reserved - Do Not Redistribute
#
property :license_path, String, name_property: true
property :deploy_path, String, required: true

default_action :create

require 'fileutils'

action :create do

  ruby_block 'copy_files_license_file' do

    block do
      FileUtils.cp(license_path, ::File.join(deploy_path, 'license.dat'))
      Chef::Log.info( 'Finished copying license file' )
    end

  end
end