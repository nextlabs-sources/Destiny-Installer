#
# Cookbook Name:: ControlCenter
# Resource:: linux_service
#
# Copyright 2015, Nextlabs Inc.
# Author:: Duan Shiqiang
#
# All rights reserved - Do Not Redistribute
#
property :service_name, String, name_property: true
property :config_path, String, required: true
property :description, String, default: ''
property :install_dir, String, required: true
property :version_number, String, required: true
property :server_user, String, required: true
property :pid_file, String, required: true
property :jvm_memory_opts, String, default: ''
property :java_opts, String, default: ''
property :depends_on, String, default: ''
property :exising_server_version, String

require 'fileutils'

action :create do
  # first create the folder for config_path
  directory "#{::File.dirname(config_path)}" do
    owner 'root'
    group 'root'
    mode '0755'
    action :create
  end

  # Systemd service file
  template "/etc/systemd/system/#{service_name}.service" do
    source 'control_center_service.erb'
    variables ({
                 :config_path      => config_path,
                 :install_home     => install_dir,
                 :depends_on       => depends_on,
                 :server_user      => node['linux']['user'],
                 :server_group     => node['linux']['group'],
                 :pid_file         => pid_file,
                 :jvm_memory_opts  => jvm_memory_opts,
                 :java_opts        => java_opts
               })
    
    owner 'root'
    group 'root'
    mode '0755'
  end
  
  # enable service
  execute 'enable_elasticsearch_service' do
    command %Q[/usr/bin/systemctl enable #{service_name}.service]
    action :run
  end

  # server.conf file. This is now just used for uninstall
  # can the information here be put in the .service file instead?
  template "#{config_path}" do
    source 'control_center.conf.erb'
    variables ({
      :install_home     => install_dir,
      :version_number   => version_number,
    })
    owner node['linux']['user']
    group node['linux']['group']
    mode '0644'
  end

  # Rotate the catalina.log file so that it doesn't get too big
  template "/etc/logrotate.d/tomcat" do
    source 'catalina_log_rotate.erb'
    variables ({
      :install_home => install_dir
    })
    owner 'root'
    group 'root'
    mode '0644'
    only_if do ::File.directory?('/etc/logrotate.d') end
  end

  # SELinux must believe that it's a valid log file or else logrotate
  # will be denied permission to touch the file. This only needs to be
  # done if SELinux exists, so we won't bother putting it in pre-check

  # Setting the tag on the directory automatically sets the same tag
  # on all files created in the directory.
  execute 'set_selinux_permissions' do
    command %Q[/sbin/semanage fcontext -a -t var_log_t #{install_dir}/server/tomcat/logs]
    action :run
    only_if do ::File.exist?('/sbin/semanage') end
  end

  # Persist the changes made by semanage
  execute 'selinux_restorecon' do
    command %Q[/sbin/restorecon #{install_dir}/server/tomcat/logs]
    action :run
    only_if do ::File.exist?('/sbin/restorecon') end
  end
  
  cookbook_file "#{install_dir}/server/tomcat/bin/setenv.sh" do
    source 'tomcat_setenv.sh'
    owner node['linux']['user']
    group node['linux']['group']
    mode '0755'
  end
end


action :delete do
  # disable service
  execute 'disable_control_center_service' do
    command %Q[/usr/bin/systemctl disable #{service_name}.service]
    action :run
  end
  
  # remove init file, config files
  ["/etc/systemd/system/#{service_name}.service"].each{|x|
    file x do
      action :delete
    end
  }

  ::FileUtils.rm_rf(::File.expand_path("#{config_path}/.."))
end

action :upgrade do
  # remove jsvc if existing
  ::FileUtils.rm_rf(::File.join(install_dir, 'server/tomcat/bin/jsvc'))

  # remove daemon.sh if existing
  ::FileUtils.rm_rf(::File.expand_path('../daemon.sh', config_path))
  
  # remove old System V init file
  ::FileUtils.rm_rf('/etc/init.d/#{service_name}')

  cookbook_file "#{install_dir}/server/tomcat/bin/setenv.sh" do
    source 'tomcat_setenv.sh'
    owner node['linux']['user']
    group node['linux']['user']
    mode '0755'
  end
end
