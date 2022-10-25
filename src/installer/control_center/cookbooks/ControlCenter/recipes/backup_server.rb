#
# Cookbook Name:: ControlCenter
# Recipe:: Backup Policy Server if it has any server installed
#
# Copyright 2015, Nextlabs Inc.
# Author:: Amila Silva & Duan Shiqiang
#
# All rights reserved - Do Not Redistribute
#
require 'fileutils'

Chef::Resource::RubyBlock.send(:include, Utility::RoboFileUtils)

log ProgressLog::UPGRADE_BACKUP_SERVER_FILES_STARTED

ruby_block 'copy_files_for_backup' do

  block do
    require 'fileutils'
    server_location = Server::Config.get_current_installation_dir(node)
    if ::File.directory?(node['backup_dir'])
      robo_rm_rf(node['backup_dir'])
    end
    FileUtils.mkdir_p(node['backup_dir'])
    robo_cp_r(server_location, node['backup_dir'])
  end

end

log ProgressLog::UPGRADE_BACKUP_SERVER_FILES_DONE
