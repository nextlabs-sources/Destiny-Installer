#
# Cookbook Name:: ControlCenter
# Recipe:: copy_artifacts
#
# Copy Artifacts from Dist Folder
#
# Copyright 2016, Nextlabs Inc.
# Author:: Duan Shiqiang
#
# All rights reserved - Do Not Redistribute
#
Chef::Resource::RubyBlock.send(:include, Utility::RoboFileUtils)

log ProgressLog::COPYFILE_STARTED

# Copy Files to installer location
ruby_block 'copy_files_to_install_dir' do
  block do
    require 'fileutils'
    robo_rm_rf(node['installation_dir'])

    FileUtils.mkdir_p(node['installation_dir'])

    Chef::Log.info( "[CopyArtifacts]: Start copying files to #{node['installation_dir']}" )

    robo_cp_r(node['dist_server_dir'], node['installation_dir'])

    Chef::Log.info( "[CopyArtifacts] Finished Copying files into installation directory: #{node['installation_dir']}" )

  end
end

# Remove unnecessary files from installation location
ruby_block 'remove_unnecessary_files' do
  block do
    require 'fileutils'
    FileUtils.rm_f(::File.join(node['installation_dir'], 'server/configuration/server-template.xml'))

    Chef::Log.info( "[CopyArtifacts] Finished removing unnecessary files form installation directory: #{node['installation_dir']}" )
  end
end

# copy version text file
ruby_block 'copy_version_file' do

  block do
    require 'fileutils'
    FileUtils.cp_r(
        ::File.expand_path("../#{node['version_file_name']}", node['dist_folder']),
        ::File.join(node['installation_dir'], node['version_file_name'])
    )
  end

  ignore_failure true

end

log ProgressLog::COPYFILE_DONE
