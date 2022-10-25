#
# Cookbook Name:: ControlCenter
# Resource:: db_init
#
# Copyright 2016, Nextlabs Inc.
# Author:: Duan Shiqiang
#
# All rights reserved - Do Not Redistribute
#
property :logging_path, String, required: true
property :mode, String, name_property: true

require 'fileutils'

action :invoke do

  # first create db init logging config file
  template 'dbinit_logging.properties' do
    path ::File.join(logging_path, 'dbinit_logging.properties')
    source 'dbinit_logging_properties.erb'
    variables(
        :installer_log_path => logging_path
    )
    action :create
  end

  # then invoke the db init
  ruby_block 'database_initialization' do

    block do

      action = case mode
                 when 'install'
                   'install'
                 when 'upgrade'
                   'upgrade'
                 when 'remove'
                   'dropcreateschema'
                 else
                   'install'
               end
      Chef::Log.info( "Start database manipulation: #{action}" )

      Utility::DB.handle_db_Init(node, action, tries=3)

      Chef::Log.info( "Finished database manipulation: #{action}" )

    end

  end

end

