#
# Cookbook Name:: ControlCenter
# Recipe:: add_remove_support
#
# Copyright 2016, Nextlabs Inc.
# Author:: Duan Shiqiang
#
# All rights reserved - Do Not Redistribute
#
require 'fileutils'
Chef::Resource::RubyBlock.send(:include, Utility::RoboFileUtils)

log ProgressLog::ADD_UNINSTALL_SCRIPTS_STARTED

ruby_block 'copy_chef_things' do
  block do
    require 'fileutils'
    uninstaller_directory = ::File.join(node['local_app_data'], node['appdata_folder_name'])

    robo_rm_rf(uninstaller_directory) if ::File.directory?(uninstaller_directory)
    FileUtils.mkdir_p(uninstaller_directory)

    %w[bin cookbooks engine].each do |dir|
      dest_dir = ::File.join(uninstaller_directory, dir)
      FileUtils.mkdir_p(dest_dir)
      robo_cp_r(::File.join(ENV['START_DIR'].gsub("\\", '/'), dir), dest_dir)
    end

    version_file = ::File.join(ENV['START_DIR'].gsub("\\", '/'), node['version_file_name'])
    FileUtils.cp(version_file, ::File.join(uninstaller_directory, node['version_file_name']))
  end
end

cookbook_file 'copy_uninstall_cc_properties' do
  source 'cc_properties_uninstall.json'
  path ::File.join(node['local_app_data'], node['appdata_folder_name'], 'cc_properties.json')
end


if platform?('windows')

  template "#{::File.join(node['installation_dir'], 'uninstall.bat')}" do
    source 'uninstall.bat.erb'
    variables ({
      :uninstaller_dir => ::File.join(node['local_app_data'], node['appdata_folder_name'])
    })
    action :create
  end
  
  cookbook_file 'copy_uninstall_readme' do
    source 'uninstall_readme.md'
    path ::File.join(node['installation_dir'], 'uninstall_readme.md')
  end

else

  template "#{::File.join(node['installation_dir'], 'uninstall.sh')}" do
    source 'uninstall.sh.erb'
    variables ({
      :uninstaller_dir => ::File.join(node['local_app_data'], node['appdata_folder_name'])
    })
    owner #{node['linux']['user']}
    group #{node['linux']['user']}
    mode '0755'
  end

  cookbook_file 'copy_uninstall_readme' do
    source 'uninstall_readme.md'
    path ::File.join(node['installation_dir'], 'uninstall_readme.md')
    owner #{node['linux']['user']}
    group #{node['linux']['user']}
  end
  
end

log ProgressLog::ADD_UNINSTALL_SCRIPTS_DONE
