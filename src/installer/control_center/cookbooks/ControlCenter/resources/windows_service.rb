#
# Cookbook Name:: ControlCenter
# Resource:: windows_service
#
# Copyright 2015, Nextlabs Inc.
# Author:: Duan Shiqiang
#
# All rights reserved - Do Not Redistribute
#
property :service_name, String, name_property: true
property :description, String, default: ""
property :display_name, String
property :install_dir, String
property :jvm_max_perm, String, default: "512M"
property :jvmms, String, default: "512"
property :jvmmx, String, default: "2048"
property :version_number, String
property :procrun_path, String, required: true
property :built_date, String, default: ''
property :registry_key_name, String, required: true
property :dms_location, String
property :depends_on, String, default: ''
property :hostname, String
property :web_application_port, String
property :exising_server_version, String
property :console_install_mode, String
property :ssl_server_dn_match, String, default: ''

require 'chef/mixin/shell_out'
include Chef::Mixin::ShellOut

action :create do

  registry_key "#{registry_key_name}" do
    values [
               {:name => 'DMSLocation', :type => :string, :data => dms_location},
               {:name => 'INSTALLDIR', :type => :string, :data => install_dir},
               {:name => 'Version', :type => :string, :data => version_number},
               {:name => 'Date', :type => :string, :data => built_date}
           ]
    recursive true
    action :create
  end

  ruby_block 'create_control_center_windows_service' do
    block do
      cmd = %Q["#{procrun_path}" //IS//#{service_name}
        --Description "#{description}"
        --DisplayName "#{display_name}"
        --Install "#{procrun_path}"
        --Classpath "#{::File.join(install_dir, 'server/tomcat/bin/bootstrap.jar')};#{::File.join(install_dir, 'server/tomcat/bin/tomcat-juli.jar')};#{::File.join(install_dir, 'server/tomcat/shared/lib/nxl-filehandler.jar')}"
        --Jvm "#{::File.join(install_dir, 'java/jre/bin/server/jvm.dll')}"
        ++JvmOptions "-Dcatalina.base=#{::File.join(install_dir, '/server/tomcat')}"
        ++JvmOptions "-Dcatalina.home=#{::File.join(install_dir, 'server/tomcat')}"
        ++JvmOptions "-Djava.endorsed.dirs=#{::File.join(install_dir, 'server/tomcat/common/endorsed')}"
        ++JvmOptions "-Djava.io.tmpdir=#{::File.join(install_dir, 'server/tomcat/temp')}"
        ++JvmOptions "-Dlog4j.configurationFile=#{::File.join(install_dir, 'server/configuration/log4j2.xml')}"
        ++JvmOptions "-Dlogging.config=file:#{::File.join(install_dir, 'server/configuration/log4j2.xml')}"
        ++JvmOptions -Dorg.springframework.boot.logging.LoggingSystem=none
        ++JvmOptions -Dorg.apache.commons.logging.Log=org.apache.commons.logging.impl.Jdk14Logger
        ++JvmOptions "-Dserver.config.path=#{::File.join(install_dir, 'server/configuration')}"
        ++JvmOptions "-Dcc.home=#{install_dir}"
        ++JvmOptions "-Dspring.cloud.bootstrap.location=#{::File.join(install_dir, 'server/configuration/bootstrap.properties')}"
        ++JvmOptions "-Dserver.hostname=#{hostname}"
        ++JvmOptions "-Dserver.name=https://#{[hostname, web_application_port].compact().join(':')}"
        ++JvmOptions "-Djdk.tls.rejectClientInitiatedRenegotiation=true"
        ++JvmOptions -XX:MaxPermSize=#{jvm_max_perm}
        ++JvmOptions -Xverify:none
        ++JvmOptions -Dsun.lang.ClassLoader.allowArraySyntax=true
        ++JvmOptions -Xmx#{jvmmx}m
        ++JvmOptions -Xms#{jvmms}m
        #{console_install_mode.to_s.eql?('') ? '' : '++JvmOptions' + ' "' + '-Dconsole.install.mode=' + console_install_mode.to_s() + '"'}
        #{ssl_server_dn_match.to_s.eql?('true') ? '++JvmOptions' + ' "' + '-Doracle.net.ssl_server_dn_match=true' + '"' : ''}
        --JvmMx #{jvmmx}
        --JvmMs #{jvmms}
        --LogPath "#{::File.join(install_dir, 'server/logs/')}"
        --ServiceUser LocalSystem
        --Startup auto
        --StartMode jvm
        --StartClass org.apache.catalina.startup.Bootstrap
        ++StartParams -config;../configuration/server.xml;start
        --StopMode jvm
        --StopClass org.apache.catalina.startup.Bootstrap
        ++StopParams -config;../configuration/server.xml;stop
        ++DependsOn "#{depends_on}"].gsub("\n", ' ')

      create_service = shell_out(cmd)
      if create_service.error?
        Chef::Log.error( "[windows_service]: Unable to create new entry at Windows Services #{service_name}" )
        raise 'Unable to create new entry at Windows Services'
      else
        Chef::Log.info( "[windows_service]: Windows Services entry added #{service_name}" )
      end
    end
  end
end

action :delete do

  registry_key "#{registry_key_name}" do
    recursive true
    action :delete_key
  end

  # the brute force way to delete the service, but will leave some registry entries undeleted (so not recommended)
  # cmd = %Q[sc delete "#{service_name}" ]
  # delete_service = shell_out(cmd)

  ruby_block 'delete_control_center_windows_service' do
    block do
      cmd = %Q["#{procrun_path}" //DS//#{service_name}]
      delete_service = shell_out(cmd)

      if delete_service.error?
        Chef::Log.error( "[windows_service]: Unable to delete entry at Windows Services #{service_name}" )
        raise 'Unable to delete entry at Windows Services'
      else
        Chef::Log.info( "[windows_service]: Deleted windows service: #{service_name}" )
      end
    end
  end


end

action :upgrade do
  # need to upgrade server version
  registry_key "#{registry_key_name}" do
    values [
               {:name => 'Version', :type => :string, :data => version_number},
               {:name => 'Date', :type => :string, :data => built_date}
           ]
    recursive true
    action :create
  end

  # only for 7.7
  # we need to add some parameters to the windows service
  # we also need to add depends_on if specified
  ruby_block 'configure_windows_services_for_upgrade' do
    block do
      cmd = %Q["#{procrun_path}" //US//#{service_name}
        ++JvmOptions "-Dserver.config.path=#{::File.join(install_dir, 'server/configuration')}"
        ++JvmOptions "-Dserver.name=https://#{[hostname, web_application_port].compact().join(':')}"
        #{console_install_mode.to_s.eql?('') ? '' : '++JvmOptions' + ' "' + '-Dconsole.install.mode=' + console_install_mode.to_s() + '"'}
        ++JvmOptions "-Dnextlabs.evaluation.uses.resource.type=false"
        ++JvmOptions "-Dcc.home=#{install_dir}"
        ++JvmOptions "-Dspring.cloud.bootstrap.location=#{::File.join(install_dir, 'server/configuration/bootstrap.properties')}"
        ++JvmOptions "-Dserver.hostname=#{hostname}"
        ++JvmOptions "-Djdk.tls.rejectClientInitiatedRenegotiation=true"
      ].gsub("\n", ' ')
      update_service = shell_out(cmd)

      if update_service.error?
        Chef::Log.error( "[windows_service]: Unable to update windows service #{service_name}" )
      else
        Chef::Log.info( "[windows_service]: Updated windows services: #{service_name}" )
      end

      if depends_on.to_s != ''
        update_dependency = shell_out(%Q[sc config #{service_name} depend= Tcpip/Afd/#{depends_on.to_s.strip}])
        if update_dependency.error?
          Chef::Log.error( "[windows_service]: Unable to update windows service dependency of #{service_name} on #{depends_on}" )
        else
          Chef::Log.info( "[windows_service]: Updated windows services dependency: #{service_name} on #{depends_on}" )
        end
      end
    end
    only_if { exising_server_version.to_f <= 7.7 }
  end

  # only for versions lower than 8.1.2
  # we need modify Classpath settings (required by log collection feature)
  ruby_block 'modify_windows_service_classpath_to_include_log_file_handler_for_upgrade' do
    block do
      cmd = %Q["#{procrun_path}" //US//#{service_name}
        --Classpath "#{::File.join(install_dir, 'server/tomcat/bin/bootstrap.jar')};#{::File.join(install_dir, 'server/tomcat/bin/tomcat-juli.jar')};#{::File.join(install_dir, 'server/tomcat/shared/lib/nxl-filehandler.jar')}"
      ].gsub("\n", ' ')
      update_service = shell_out(cmd)

      if update_service.error?
        Chef::Log.error( "[windows_service]: Unable to update windows service with new Classpath #{service_name}" )
      else
        Chef::Log.info( "[windows_service]: Updated windows services with new Classpath: #{service_name}" )
      end
    end
    only_if { Server::Config.server_version_newer?( exising_server_version, '8.1.2') }
  end
  
  # If the version is earlier than 8.7.2 then we need to change a couple of the JVM options
  # pre 8.6 had -XX-UseSplitVerifier, we need -Xverify:none
  # pre 8.7.2 didn't set the apache commons default Logger
  # Is there a way to change just that flag?
  ruby_block 'modify_windows_service_no_verify' do
    block do
      cmd = %Q["#{procrun_path}" //US//#{service_name}
        --JvmOptions "-Dcatalina.base=#{::File.join(install_dir, '/server/tomcat')}"
        ++JvmOptions "-Dcatalina.home=#{::File.join(install_dir, 'server/tomcat')}"
        ++JvmOptions "-Djava.endorsed.dirs=#{::File.join(install_dir, 'server/tomcat/common/endorsed')}"
        ++JvmOptions "-Djava.io.tmpdir=#{::File.join(install_dir, 'server/tomcat/temp')}"
        ++JvmOptions "-Dorg.apache.commons.logging.Log=org.apache.commons.logging.impl.Jdk14Logger"
        ++JvmOptions "-Dserver.config.path=#{::File.join(install_dir, 'server/configuration')}"
        ++JvmOptions "-Dserver.name=https://#{[hostname, web_application_port].compact().join(':')}"
        ++JvmOptions -XX:MaxPermSize=#{jvm_max_perm}
        ++JvmOptions -Xverify:none
        ++JvmOptions -Dsun.lang.ClassLoader.allowArraySyntax=true
        ++JvmOptions -Xmx#{jvmmx}m
        ++JvmOptions -Xms#{jvmms}m
        #{console_install_mode.to_s.eql?('') ? '' : '++JvmOptions' + ' "' + '-Dconsole.install.mode=' + console_install_mode.to_s() + '"'}
      ].gsub("\n", ' ')

      update_service = shell_out(cmd)

      if update_service.error?
        Chef::Log.error( "[windows_service]: Unable to update windows service with -Xverify:none flag" )
        raise 'Unable to create new entry at Windows Services'
      else
        Chef::Log.info( "[windows_service]: Updated windows service with -Xverify:none flag" )
      end
    end
    only_if { Server::Config.server_version_newer?( exising_server_version, '8.7.2') }
  end

  # Add parameters required for 9.0
  ruby_block 'configure_windows_services_for_9_0' do
    block do
      cmd = %Q["#{procrun_path}" //US//#{service_name}
        ++JvmOptions "-Dcc.home=#{install_dir}"
        ++JvmOptions "-Dlog4j.configurationFile=#{::File.join(install_dir, 'server/configuration/log4j2.xml')}"
        ++JvmOptions "-Dlogging.config=file:#{::File.join(install_dir, 'server/configuration/log4j2.xml')}"
        ++JvmOptions "-Dspring.cloud.bootstrap.location=#{::File.join(install_dir, 'server/configuration/bootstrap.properties')}"
        ++JvmOptions "-Dserver.hostname=#{hostname}"
        ++JvmOptions "-Dorg.springframework.boot.logging.LoggingSystem=none"
        ++JvmOptions "-Djdk.tls.rejectClientInitiatedRenegotiation=true"
      ].gsub("\n", ' ')
      update_service = shell_out(cmd)

      if update_service.error?
        Chef::Log.error( "[windows_service]: Unable to update windows service for 9.0 #{service_name}" )
      else
        Chef::Log.info( "[windows_service]: Updated windows services for 9.0: #{service_name}" )
      end
    end
    only_if { Server::Config.server_version_newer?( exising_server_version, '9.0') }
  end

end

action :upgrade_msi do
  # MSI installer installs control center with service name EnterpriseDLPServer
  # so we need basically remove the service and create it again
  ruby_block 'delete_msi_created_windows_service' do
    block do
      delete_msi_service = shell_out(%Q["#{procrun_path}" //DS//EnterpriseDLPServer])
      if delete_msi_service.error?
        Chef::Log.info('Failed to remove windows service EnterpriseDLPServer, try using sc command')
        delete_msi_service_sc = shell_out(%Q[sc delete EnterpriseDLPServer])
        if delete_msi_service_sc.error?
          Chef::Log.warn('Failed to remove windows service EnterpriseDLPServer, you may remove it manually')
        end
      end
    end
  end

  ruby_block 'delete_entry_at_windows_programs_and_features' do
    block do
      require 'win32/registry'
      # refer to: https://msdn.microsoft.com/en-us/library/windows/desktop/aa384129(v=vs.85).aspx
      KEY_WOW64_64KEY = 0x0100
      reg_type = ::Win32::Registry::KEY_ALL_ACCESS | KEY_WOW64_64KEY
      control_center_key = nil
      ::Win32::Registry::HKEY_LOCAL_MACHINE.open('SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall', reg_type) do |reg|
        reg.each_key do |key|
          begin
            display_name = reg.open(key).read_s('DisplayName')
            reg.delete_key(key, true) if display_name == 'Control Center Server'
          rescue Exception => ex
            next
          end
        end
      end
    end
  end

  # then we create the service
  ruby_block 'create_windows_service_for_upgrade' do
    block do
      cmd = %Q["#{procrun_path}" //IS//#{service_name}
        --Description "#{description}"
        --DisplayName "#{display_name}"
        --Install "#{procrun_path}"
        --Classpath "#{::File.join(install_dir, 'server/tomcat/bin/bootstrap.jar')};#{::File.join(install_dir, 'server/tomcat/bin/tomcat-juli.jar')};#{::File.join(install_dir, 'server/tomcat/shared/lib/nxl-filehandler.jar')}"
        --Jvm "#{::File.join(install_dir, 'java/jre/bin/server/jvm.dll')}"
        ++JvmOptions "-Dcatalina.base=#{::File.join(install_dir, '/server/tomcat')}"
        ++JvmOptions "-Dcatalina.home=#{::File.join(install_dir, 'server/tomcat')}"
        ++JvmOptions "-Djava.endorsed.dirs=#{::File.join(install_dir, 'server/tomcat/common/endorsed')}"
        ++JvmOptions "-Djava.io.tmpdir=#{::File.join(install_dir, 'server/tomcat/temp')}"
        ++JvmOptions "-Dlog4j.configurationFile=#{::File.join(install_dir, 'server/configuration/log4j2.xml')}"
        ++JvmOptions "-Dlogging.config=file:#{::File.join(install_dir, 'server/configuration/log4j2.xml')}"
        ++JvmOptions -Dorg.springframework.boot.logging.LoggingSystem=none
        ++JvmOptions -Dorg.apache.commons.logging.Log=org.apache.commons.logging.impl.Jdk14Logger
        ++JvmOptions "-Dserver.config.path=#{::File.join(install_dir, 'server/configuration')}"
        ++JvmOptions "-Dserver.name=https://#{[hostname, web_application_port].compact().join(':')}"
        ++JvmOptions -XX:MaxPermSize=#{jvm_max_perm}
        ++JvmOptions -Xverify:none
        ++JvmOptions -Dsun.lang.ClassLoader.allowArraySyntax=true
        ++JvmOptions -Xmx#{jvmmx}m
        ++JvmOptions -Xms#{jvmms}m
        --JvmMx #{jvmmx}
        --JvmMs #{jvmms}
        #{console_install_mode.to_s.eql?('') ? '' : '++JvmOptions' + ' "' + '-Dconsole.install.mode=' + console_install_mode.to_s() + '"'}
        --LogPath "#{::File.join(install_dir, 'server/logs/')}"
        --Startup auto
        --StartMode jvm
        --StartClass org.apache.catalina.startup.Bootstrap
        ++StartParams -config;../configuration/server.xml;start
        --StopMode jvm
        --StopClass org.apache.catalina.startup.Bootstrap
        ++StopParams -config;../configuration/server.xml;stop
        ++DependsOn "#{depends_on}"].gsub("\n", ' ')

      create_service = shell_out(cmd)

      if create_service.error?
        Chef::Log.error( "[windows_service]: Unable to create new entry at Windows Services #{service_name}" )
        raise 'Unable to create new entry at Windows Services'
      else
        Chef::Log.info( "[windows_service]: Windows Services entry added #{service_name}" )
      end
    end
  end

  # then upgrade server version
  registry_key "#{registry_key_name}" do
    values [
               {:name => 'Version', :type => :string, :data => version_number},
               {:name => 'Date', :type => :string, :data => built_date}
           ]
    recursive true
    action :create
  end

end
