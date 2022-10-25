#
# Cookbook Name:: ControlCenter
# Resource:: win_elasticsearch_service
#
# Copyright 2016, Nextlabs Inc.
# Author:: Duan Shiqiang
#
# All rights reserved - Do Not Redistribute
#
property :es_home, String, required: true
property :java_home, String, required: true
property :service_name, String, required: true
property :display_name, String, default: 'Control Center ElasticSearch'

require 'chef/mixin/shell_out'
include Chef::Mixin::ShellOut

action :create do
  # create the elasticsearch service
  ruby_block 'create_elasticsearch_service' do
    block do
      cmd = %Q[
        "#{::File.join(es_home, 'bin', 'elasticsearch-service')}"
        install
        "#{service_name}"
      ].gsub("\n", ' ')

      create_service = shell_out(cmd, :environment => {
          'JAVA_HOME' => java_home,
          'ES_START_TYPE' => 'auto',
          'SERVICE_DISPLAY_NAME' => display_name
      })

      if create_service.error?
        Chef::Log.error("[win_elasticsearch_service]: Unable to create elasticsearch service: #{service_name}")
        raise 'Unable to create elasticsearch Windows Services'
      else
        Chef::Log.info("[win_elasticsearch_service]: Created elasticsearch service: #{service_name}")
      end
    end
  end

end

action :stop do
  service "#{service_name}" do
    action :stop
  end
end

action :delete do

  # remove the elasticsearch service
  ruby_block 'remove_elasticsearch_service' do
    block do
      cmd = %Q[
        "#{::File.join(es_home, 'bin', 'elasticsearch-service')}"
        remove
        "#{service_name}"
      ].gsub("\n", ' ')

      delete_service = shell_out(cmd, :environment => {'JAVA_HOME' => java_home})
  
      if delete_service.error?
        Chef::Log.error("[win_elasticsearch_service]: Unable to remove elasticsearch service: #{service_name}")
        raise 'Unable to remove elasticsearch Windows Service'
      else
        Chef::Log.info("[win_elasticsearch_service]: Removed elasticsearch service: #{service_name}")
      end
    end
  end

end