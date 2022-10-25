#
# Cookbook Name:: ControlCenter
# Resource:: linux_elasticsearch_service
#
# Copyright 2016, Nextlabs Inc.
# Author:: Duan Shiqiang
#
# All rights reserved - Do Not Redistribute
#
property :es_home, String, required: true
property :java_home, String
property :service_name, String, required: true
property :es_user, String
property :es_group, String

require 'chef/mixin/shell_out'
include Chef::Mixin::ShellOut

action :create do
  template "/etc/systemd/system/#{service_name}.service" do

    source 'elasticsearch_service.erb'
    variables ({
        :es_home        => es_home,
        :service_name   => service_name,
        :es_user        => es_user,
        :es_group       => es_group,
        :java_home      => java_home
    })
    owner 'root'
    group 'root'
    mode '0755'
  end

  # change es_home's ownership, since elasticsearch will create some folder under it when it starts
  execute 'change_es_home_permission' do
    command %Q[chown -R #{es_user}:#{es_group} "#{es_home}"]
    action :run
  end

  # enable service
  execute 'enable_elasticsearch_service' do
    command %Q[/usr/bin/systemctl enable #{service_name}.service]
    action :run
  end
end

action :delete do
  # disable service
  execute 'enable_elasticsearch_service' do
    command %Q[/usr/bin/systemctl disable #{service_name}.service]
    action :run
  end
  
  # then remove the service daemon script, conf file (env file)
  ["/etc/systemd/system/#{service_name}.service"].each do |x|
    file x do
      action :delete
    end
  end
end
