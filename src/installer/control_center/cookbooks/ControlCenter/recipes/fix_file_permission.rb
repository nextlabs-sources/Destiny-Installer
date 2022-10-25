#
# Cookbook Name:: ControlCenter
# Recipe:: fix_file_permission
#
# Copyright 2015, Nextlabs Inc.
# Author:: Duan Shiqiang
#
# All rights reserved - Do Not Redistribute
#
# Set correct file permissions

if platform?('windows')
  # todo
else
  execute 'chown-policy-server' do
    command %Q[chown -R
       #{node['linux']['user']}:#{node['linux']['group']}
      "#{node['installation_dir']}"
    ].gsub("\n", ' ')
    user 'root'
    action :run
  end

  # Grant Execution permission
  execute 'grant_server_scripts_execution' do
    command %Q[chmod -R 755
      "#{node['installation_dir'] + '/java/bin'}"/*
      "#{node['installation_dir'] + '/java/jre/bin'}"/*
      "#{node['installation_dir'] + '/server/tomcat/bin'}"/*
      "#{node['installation_dir']}"/*
      #{::File.exist?(node['es_home']) ? ("\"#{node['es_home'] + '/bin'}\"" + '/*') : ''}
    ].gsub("\n", ' ')
    user 'root'
    action :run
  end

  # Let PolicyServer bind to reserved ports (e.g. 443)
  execute 'add_capabilities_to_policyserver' do
    command %Q[/sbin/setcap CAP_NET_BIND_SERVICE=+eip "#{::File.join(node['installation_dir'], 'java/jre/bin/java')}"]
    user 'root'
    action :run
  end
  
  if node['platform_family'] == 'suse'
    # Setting capabilities breaks shared library searching, so we have to
    # fix that up
    file "/etc/ld.so.conf.d/java-libjli.conf" do
      content "#{::File.join(node['installation_dir'], 'java/lib/ppc64le/jli')}"
      owner 'root'
      group 'root'
      mode '0644'
    end
  else
    # Setting capabilities breaks shared library searching, so we have to
    # fix that up
    file "/etc/ld.so.conf.d/java-libjli.conf" do
      content "#{::File.join(node['installation_dir'], 'java/lib/amd64/jli')}"
      owner 'root'
      group 'root'
      mode '0644'
    end
  end


  execute 'ldconfig' do
    command %Q[ldconfig -v]
    user 'root'
    action :run
  end
end
