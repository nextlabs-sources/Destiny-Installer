#
# Cookbook Name:: ControlCenter
# Recipe:: Install Recipe
#
# Copyright 2015, Nextlabs Inc.
# Author:: Amila Silva & Duan Shiqiang
#
# All rights reserved - Do Not Redistribute
#
require 'fileutils'
require 'uri'
require 'securerandom'
require "timeout"
require "mixlib/shellout"

log 'install start' do
  message '[Install] Start installation'
end

# first create linux user and group
unless platform?('windows')

  group 'nextlabs_group' do
    action        :create
    group_name    node['linux']['group']
    not_if "getent group #{node['linux']['group']}"
  end

  user 'nextlabs_user' do
    action        :create
    comment       'Nextlabs User'
    home          node['linux']['home']
    manage_home   false
    system        true
    gid           node['linux']['group']
    username      node['linux']['user']
    shell         '/bin/false'
    not_if "getent passwd #{node['linux']['user']}"
  end

  # Work around bug in systemd 119
  execute 'restart_systemctl' do
    command %Q[/usr/bin/systemctl daemon-reexec]
    action :run
  end
end


include_recipe 'ControlCenter::copy_artifacts'


#    token_values[ConfigTokens::KM_KEY_STORE_PASSWORD_TOKEN] = Server::Config.encrypt_password(node, node['key_store_password'].to_s.strip)

# server.xml file token modifications
ruby_block 'server_xml_file_modification' do

  block do

    token_values = Hash.new

    token_values[ConfigTokens::BLUEJUNGLE_HOME_TOKEN] = node['installation_dir'].to_s.strip
    token_values[ConfigTokens::HOSTNAME_TOKEN] = (node['fqdn'] || node['hostname']).downcase()
    token_values[ConfigTokens::MACHINE_NAME_TOKEN] = node['hostname'].downcase
    token_values[ConfigTokens::SHUTDOWN_PORT_TOKEN] = node['web_shutdown_port'].to_s.strip
    token_values[ConfigTokens::INTERNAL_PORT_TOKEN] = node['web_service_port'].to_s.strip
    token_values[ConfigTokens::EXTERNAL_PORT_TOKEN] = node['web_application_port'].to_s.strip
    token_values[ConfigTokens::CONFIG_SERVICE_PORT_TOKEN] = node['config_service_port'].to_s.strip
    token_values[ConfigTokens::GENERATED_TRUST_STORE_TOKEN] = Server::Config.encrypt_password(node, node['trust_store_password'].to_s.strip)
    token_values[ConfigTokens::GENERATED_KEY_STORE_TOKEN] = Server::Config.encrypt_password(node, node['key_store_password'].to_s.strip)

    token_values[ConfigTokens::DMS_HOST_TOKEN] = Server::Config.get_DMS_host(node)
    token_values[ConfigTokens::DMS_PORT_TOKEN] = Server::Config.get_DMS_port(node)
    token_values[ConfigTokens::DAC_HOST_TOKEN] = Server::Config.get_DAC_host(node)
    token_values[ConfigTokens::DAC_PORT_TOKEN] = Server::Config.get_DAC_port(node)

    if node['dms_component'].to_s.strip === 'OFF'
      token_values[ConfigTokens::DMS_BEGIN_TOKEN] = ConfigTokens::DMS_BEGIN_COMMENT_TOKEN
      token_values[ConfigTokens::DMS_END_TOKEN] = ConfigTokens::DMS_END_COMMENT_TOKEN
    else
      nil
    end

    if node['dac_component'].to_s.strip === 'OFF'
      token_values[ConfigTokens::DAC_BEGIN_TOKEN] = ConfigTokens::DAC_BEGIN_COMMENT_TOKEN
      token_values[ConfigTokens::DAC_END_TOKEN] = ConfigTokens::DAC_END_COMMENT_TOKEN
    else
      nil
    end 

    if node['dem_component'].to_s.strip === 'OFF'
      token_values[ConfigTokens::DEM_BEGIN_TOKEN] = ConfigTokens::DEM_BEGIN_COMMENT_TOKEN
      token_values[ConfigTokens::DEM_END_TOKEN] = ConfigTokens::DEM_END_COMMENT_TOKEN
    else
      nil
    end  

    if node['dabs_component'].to_s.strip === 'OFF'
      token_values[ConfigTokens::DABS_BEGIN_TOKEN] = ConfigTokens::DABS_BEGIN_COMMENT_TOKEN
      token_values[ConfigTokens::DABS_END_TOKEN] = ConfigTokens::DABS_END_COMMENT_TOKEN
    else
      nil
    end   

    if node['dkms_component'].to_s.strip === 'OFF'
      token_values[ConfigTokens::DKMS_BEGIN_TOKEN] = ConfigTokens::DKMS_BEGIN_COMMENT_TOKEN
      token_values[ConfigTokens::DKMS_END_TOKEN] = ConfigTokens::DKMS_END_COMMENT_TOKEN
    else
      nil
    end   

    if node['admin_component'].to_s.strip === 'OFF'
      token_values[ConfigTokens::ADMIN_BEGIN_TOKEN] = ConfigTokens::ADMIN_BEGIN_COMMENT_TOKEN
      token_values[ConfigTokens::ADMIN_END_TOKEN] = ConfigTokens::ADMIN_END_COMMENT_TOKEN
    else
      nil
    end   

    if node['reporter_component'].to_s.strip === 'OFF'
      token_values[ConfigTokens::REPORTER_BEGIN_TOKEN] = ConfigTokens::REPORTER_BEGIN_COMMENT_TOKEN
      token_values[ConfigTokens::REPORTER_END_TOKEN] = ConfigTokens::REPORTER_END_COMMENT_TOKEN
    else
      nil
    end

    # dps need to be disabled if: it's set to OFF, or console is enabled (non-OPL mode)
    if node['dps_component'].to_s.strip.eql?('OFF')
      token_values[ConfigTokens::DPS_BEGIN_TOKEN] = ConfigTokens::DPS_BEGIN_COMMENT_TOKEN
      token_values[ConfigTokens::DPS_END_TOKEN] = ConfigTokens::DPS_END_COMMENT_TOKEN
    else
      nil
    end  

    # console need to be disabled if: it's set to OFF, or OPL mode
    if node['cc_console_component'].to_s.strip.eql?('OFF') || node['console_install_mode'].to_s.strip.eql?('OPL')
      token_values[ConfigTokens::CONSOLE_BEGIN_TOKEN] = ConfigTokens::CONSOLE_BEGIN_COMMENT_TOKEN
      token_values[ConfigTokens::CONSOLE_END_TOKEN] = ConfigTokens::CONSOLE_END_COMMENT_TOKEN
    else
      nil
    end

    # config service need to be disabled if: it's set to OFF
    if node['dms_component'].to_s.strip === 'OFF'
      token_values[ConfigTokens::CONFIG_SERVICE_BEGIN_TOKEN] = ConfigTokens::CONFIG_SERVICE_BEGIN_COMMENT_TOKEN
      token_values[ConfigTokens::CONFIG_SERVICE_END_TOKEN] = ConfigTokens::CONFIG_SERVICE_END_COMMENT_TOKEN
    else
      nil
    end

    # if dms is on, then CAS should be on also
    if node['dms_component'].to_s.strip === 'OFF'
      token_values[ConfigTokens::CAS_BEGIN_TOKEN] = ConfigTokens::CAS_BEGIN_COMMENT_TOKEN
      token_values[ConfigTokens::CAS_END_TOKEN] = ConfigTokens::CAS_END_COMMENT_TOKEN
    else
      nil
    end

    #if administrator, reporter and console all OFF, we can disable help also
    # if node['admin_component'].to_s.strip.eql?('OFF') && node['reporter_component'].to_s.strip.eql?('OFF') && \
    #     node['cc_console_component'].to_s.strip.eql?('OFF')
    #   token_values[ConfigTokens::HELP_BEGIN_TOKEN] = ConfigTokens::HELP_BEGIN_COMMENT_TOKEN
    #   token_values[ConfigTokens::HELP_END_TOKEN] = ConfigTokens::HELP_END_COMMENT_TOKEN
    # end

    server_template_xml_file = ::File.join(node['dist_server_dir'], 'server/configuration/server-template.xml')
    server_xml_file = ::File.join(node['installation_dir'], 'server/configuration/server.xml')
    
    Server::Config.replace_in_file(server_template_xml_file, server_xml_file, token_values)

    Chef::Log.info( '[Install] Finished modifying server.xml' )
  end

end

# copy license file
ControlCenter_deploy_license "#{node['license_file_location']}" do
  deploy_path   ::File.join(node['installation_dir'], 'server/license')
  # only management server type installation require license file
  only_if { node['dms_component'].to_s.strip.eql?('ON') }
end

# copy database ssl certificate, need to re-import during next upgrade
ruby_block 'copy ssl certificate' do
  block do
    cert_path = ::File.join(node['installation_dir'], 'server/certificates')
    FileUtils.cp(node['db_ssl_certificate'], cert_path)
  end
  
  # only when SSL certificate is provided
  only_if {node['db_ssl_certificate'] != nil && node['db_ssl_certificate'] != ""}
end

# create server certificates
ruby_block 'create_server_certificates' do

  block do
    keystore_path = ::File.join(node['installation_dir'], 'server/certificates')
    key_store_password = node['key_store_password']
    trust_store_password = node['trust_store_password']

    Server::Certs.create_all_certificates(node, keystore_path, key_store_password, trust_store_password)
    Chef::Log.info( '[Install] Finished creating server certificates' )
  end

  # only management server type installation needs to generate new certificate
  only_if { node['dms_component'].to_s.strip.eql?('ON') }

end

# dbinit configuration file token modifications
ControlCenter_db_init_tool 'token_modification' do
  admin_user_password   node['admin_user_password']
  db_init_dir           ::File.join(node['installation_dir'], 'tools/dbInit')
  action                :prepare
  only_if { Server::Config.init_db?(node) }
end

# database schema creation and initialization
log ProgressLog::INSTALL_DATABASE_MANIPULATE_STARTED do
  only_if { Server::Config.init_db?(node) }
end

ControlCenter_db_init 'install' do
  logging_path  node['log_dir']
  only_if { Server::Config.init_db?(node) }
end

log ProgressLog::INSTALL_DATABASE_MANIPULATE_DONE do
  only_if { Server::Config.init_db?(node) }
end

# clear db init cfg file with sensitive data
ControlCenter_db_init_tool 'clear_sensitive_cfg_data' do
  db_init_dir           ::File.join(node['installation_dir'], 'tools/dbInit')
  action                :clean
  only_if { Server::Config.init_db?(node) }
end

if platform?('windows')

  # create shortcuts
  # Administrator shortcut for windows
  template 'administrator.url' do
    path ::File.join(node['installation_dir'] , 'administrator.url')
    source 'administrator.url.erb'
    variables(
      :server_url => Server::Config.get_DMS_host(node) + ':' +  node['web_application_port'],
      :install_path => node['installation_dir']
    )
    action :create
  end

  # Reporter shortcut for windows
  template 'reporter.url' do
    path ::File.join(node['installation_dir'] , 'reporter.url')
    source 'reporter.url.erb'
    variables(
      :server_url =>  Server::Config.get_DMS_host(node) + ':' +  node['web_application_port'],
      :install_path => node['installation_dir']
    )
    action :create
  end

  # Console shortcut for windows
  template 'console.url' do
    path ::File.join(node['installation_dir'], 'console.url')
    source 'console.url.erb'
    variables(
        :server_url =>  Server::Config.get_DMS_host(node) + ':' +  node['web_application_port'],
        :install_path => node['installation_dir']
    )
    action :create
  end

  ruby_block 'create_windows_start_menu_options' do
    block do
      require 'fileutils'
      startMenuDirLocation = Server::Config.win_start_shortcut_path()

      if ::File.directory? startMenuDirLocation
        FileUtils.rm_rf(startMenuDirLocation)
      end

      FileUtils.mkdir_p(startMenuDirLocation)
      FileUtils.cp(::File.join(node['installation_dir'] , 'administrator.url'), ::File.join(startMenuDirLocation, 'Administrator.url'))
      FileUtils.cp(::File.join(node['installation_dir'] , 'reporter.url'), ::File.join(startMenuDirLocation, 'Reporter.url'))
      # only copy the url shortcut to windows start menu if it's console component is ON and in non-OPL mode
      if node['cc_console_component'].to_s.strip.eql?('ON') && !node['console_install_mode'].to_s.strip.eql?('OPL')
        FileUtils.cp(::File.join(node['installation_dir'] , 'console.url'), ::File.join(startMenuDirLocation, 'Console.url'))
      end
     end
  end

end

# openaz-pep.properties file
template "#{::File.join(node['installation_dir'], 'server', 'configuration', 'openaz-pep.properties')}" do
  source 'openaz-pep.properties.erb'
  action :create
  only_if { node['cc_console_component'].to_s.strip.eql?('ON') || node['dms_component'].to_s.strip().eql?('ON') }
end

# log4j2 configuration file
template "#{::File.join(node['installation_dir'], 'server', 'configuration', 'log4j2.xml')}" do
  source 'log4j2.xml.erb'
  action :create
end

# application.properties file
template "#{::File.join(node['installation_dir'], 'server', 'configuration', 'application.properties')}" do
  source 'application.properties.erb'
  variables ({
      :db_ssl_enabled         => (node['db_ssl_connection'] == 'true') ? 'true' : 'false',
      :db_ssl_certificate     => (node['db_ssl_certificate'] != nil && node['db_ssl_certificate'] != '') ? File.join(node['installation_dir'], 'server/certificates', File.basename(node['db_ssl_certificate'])) : '',
      :db_connection_string   => Utility::DB.db_connection_url(node['database_type'].to_s.strip, node['db_connection_url'].to_s.strip),
      :db_username            => node['db_username'].to_s.strip(),
      :db_encrypted_password  => Server::Config.encrypt_password(node, node['db_password'].to_s.strip),
      :db_driver              => Utility::DB.get_db_driver(node['database_type'].to_s.strip),
      :db_dialect             => Utility::DB.get_cas_db_dialect(node['database_type'].to_s.strip),
      :version_number         => node['version_number'],
      :build_number           => node['build_number']
  })
  action :create
  only_if { node['dms_component'].to_s.strip.eql?('ON') }
end

# bootstrap.properties file
template "#{::File.join(node['installation_dir'], 'server', 'configuration', 'bootstrap.properties')}" do
  source 'bootstrap.properties.erb'
  variables ({
      :host                  => (node['fqdn'] || node['hostname']).downcase(),
      :config_service_port   => (node['config_service_port']),
      :config_service_encrypted_password  => Server::Config.encrypt_password(node, SecureRandom.base64)
  })
  action :create
end

# copy Tomcat server version properties file, this is a security fix for vulnerable server version in use
ruby_block 'create server info folder' do
  block do
    folder_path = File.join(node['installation_dir'], 'server', 'tomcat', 'lib', 'org', 'apache', 'catalina', 'util')
    FileUtils.mkdir_p(folder_path)
  end
end

template "#{::File.join(node['installation_dir'], 'server', 'tomcat', 'lib', 'org', 'apache', 'catalina', 'util', 'ServerInfo.properties')}" do
  source 'ServerInfo.properties'
  action :create
end

ruby_block 'update_configurations' do
  block do
    cryptJarFile = File.join(node['dist_server_dir'], 'tools', 'crypt', 'crypt.jar')
    support_classpath = Dir[node['dist_support_folder'] + '/*.jar'].join(node['classpath_separator']) + node['classpath_separator'] + cryptJarFile
    mail_password = (node['mail_server_password'] == nil || node['mail_server_password'] == '') ? '' : Server::Config.encrypt_password(node, node['mail_server_password'].to_s.strip)
    data_transportation_key = (node['data_transportation_shared_key'] == nil || node['data_transportation_shared_key'] == '') ? '' : Server::Config.encrypt_password(node, node['data_transportation_shared_key'].to_s.strip)
    truststore_file = File.join(node['installation_dir'], 'server/certificates/web-truststore.jks')
      
    Chef::Log.info('[Install] Update configurations started')
    command = %Q[
      "#{node['instance_jre_x_path']}"
      -cp "#{support_classpath}"
      -Ddb.driver="#{Utility::DB.get_db_driver(node['database_type'].to_s.strip)}"
      -Ddb.url="#{Utility::DB.db_connection_url(node['database_type'].to_s.strip, node['db_connection_url'].to_s.strip).gsub('"', '\"')}"
      -Ddb.username="#{node['db_username'].to_s.strip()}"
      -Ddb.password="#{Server::Config.encrypt_password(node, node['db_password'].to_s.strip)}"
      -Djavax.net.ssl.trustStore="#{truststore_file}"
      -Djavax.net.ssl.trustStorePassword="#{node['trust_store_password'].to_s.strip()}"
      -Dconfig.dir="#{::File.join(node['installation_dir'], 'server/configuration')}"
      -Dapp_application.application.version="#{node['version_number']}-#{node['build_number']}"
      -Dapp_application.server.name="https://#{[(node['fqdn'] || node['hostname']).downcase(), node['web_application_port']].compact().join(':')}"
      -Dapp_application.web.service.server.name="https://#{[(node['fqdn'] || node['hostname']).downcase(), node['web_service_port']].compact().join(':')}"
      -Dapp_application.config.activeMQConnectionFactory.brokerURL="failover:(tcp://#{(node['fqdn'] || node['hostname']).downcase()}:61616)"
      -Dapp_config-service.activemq.broker.connector.bindAddress="tcp://#{(node['fqdn'] || node['hostname']).downcase()}:61616"
      -Dapp_application.spring.mail.host="#{node['mail_server_url'].to_s.strip}"
      -Dapp_application.spring.mail.port="#{node['mail_server_port'].to_s.strip}"
      -Dapp_application.spring.mail.username="#{node['mail_server_username'].to_s.strip}"
      -Dapp_application.spring.mail.password="#{mail_password}"
      -Dapp_application.spring.mail.properties.mail.smtp.from="#{node['mail_server_from'].to_s.strip}"
      -Dapp_application.cc.mail.default.to="#{node['mail_server_to'].to_s.strip}"
      -Dapp_application.key.store.password="#{Server::Config.encrypt_password(node, node['key_store_password'].to_s.strip)}"
      -Dapp_application.trust.store.password="#{Server::Config.encrypt_password(node, node['trust_store_password'].to_s.strip)}"
      -Dapp_console.data.transportation.allow.plain.text.export="#{node['data_transportation_plain_text_export']}"
      -Dapp_console.data.transportation.allow.plain.text.import="#{node['data_transportation_plain_text_import']}"
      -Dapp_console.data.transportation.keystore.file="#{::File.join(node['installation_dir'], 'server/certificates/digital-signature-keystore.jks')}"
      -Dapp_console.data.transportation.mode="#{node['data_transportation_mode']}"
      -Dapp_console.data.transportation.shared.key="#{data_transportation_key}"
      com.nextlabs.installer.controlcenter.confighelper.ConfigHelper
    ].gsub("\n", ' ').squeeze(' ')
    Chef::Log.debug('[Install] CONFIG UPDATE ' + command)
    #puts "#{command}"
    IO.popen(command, :err=>[:child, :out]) { |io|
      io.each do |line|
          Chef::Log.info(line)
      end
    }
    Chef::Log.info('[Install] Update configurations completed')
  end
  only_if { node['dms_component'].to_s.strip.eql?('ON') }
end

# Do this after we've built the PolicyServer directory structure and
# added all extra files
include_recipe 'ControlCenter::fix_file_permission'

# Create elasticsearch service, etc
if platform?('windows')

  log 'create_windows_es_service' do
    message '[Install] Installed windows elasticsearch service'
    action  :nothing
  end

  ControlCenter_win_elasticsearch_service 'create_windows_es_service' do
    es_home       node['es_home']
    java_home     ::File.join(node['installation_dir'], 'java', 'jre')
    service_name  node['elasticsearch_service_name']
    display_name  node['winx']['elasticsearch_display_name']
    action        :create
    only_if       { Server::Config.elasticsearch_component?(node) }
    notifies      :write, 'log[create_windows_es_service]', :immediately
  end

else

  log 'create_linux_es_service' do
    message '[Install] Installed linux elasticsearch service'
    action  :nothing
  end

  ControlCenter_linux_elasticsearch_service 'create_linux_es_service' do
    es_home       node['es_home']
    java_home     ::File.join(node['installation_dir'], 'java', 'jre')
    service_name  node['elasticsearch_service_name']
    es_user       node['linux']['user']
    es_group      node['linux']['group']
    action        :create
    only_if       { Server::Config.elasticsearch_component?(node) }
    notifies      :write, 'log[create_linux_es_service]', :immediately
  end

end

# create service and store properties
log ProgressLog::INSTALL_SERVICE_CREATE_STARTED

if platform?('windows')

  ControlCenter_windows_service 'create_windows_service' do

    service_name      node['winx']['service_name']
    description       node['winx']['description']
    display_name      node['winx']['display_name']
    install_dir       node['installation_dir']
    jvm_max_perm      node['server']['jvm_max_perm']
    jvmms             node['server']['jvmms']
    jvmmx             node['server']['jvmmx']
    version_number    node['version_number']
    procrun_path      ::File.join(node['installation_dir'], 'server/tomcat/bin/PolicyServer.exe')
    built_date        node['built_date']
    registry_key_name "HKEY_LOCAL_MACHINE\\#{node['REGISTY_KEY_NAME']}"
    dms_location      Server::Config.get_DMS_host(node) + ':' + Server::Config.get_DMS_port(node)
    hostname          (node['fqdn'] || node['hostname']).downcase()
    web_application_port          node['web_application_port']
    console_install_mode          node['console_install_mode']
    ssl_server_dn_match (node['database_type'].to_s.eql?('ORACLE') && (node['db_server_dn'] != '' || node['db_validate_server_dn'] == 'true')) ? 'true' : '' 
    # the attributes on node shouldn't change after chef compile stage, using lazy is just to be safe
    depends_on        lazy { Server::Config.elasticsearch_component?(node) ? node['elasticsearch_service_name'] : '' }
    action            :create

  end

  ControlCenter_config_store_win 'create_windwos_config_store' do
    registry_key_name               "HKEY_LOCAL_MACHINE\\#{node['REGISTRY_CONFIG_STORE_KEY_NAME']}"
    encrypted_key_store_password    Server::Config.encrypt_password(node, node['key_store_password'])
    encrypted_trust_store_password  Server::Config.encrypt_password(node, node['trust_store_password'])
    action                          :create
  end

  log 'created windows service' do
    message '[Install] Created windows service'
  end

else

  ControlCenter_linux_service 'create_linux_service' do

    service_name    node['linux']['service_name']
    description     node['linux']['description']
    config_path     Server::Config.linux_server_config_path(node)
    install_dir     node['installation_dir']
    version_number  node['version_number']
    server_user     node['linux']['user']
    pid_file        "#{::File.join(node['installation_dir'], node['linux']['pid_file'])}"
    jvm_memory_opts "-Xmx#{node['server']['jvmmx']}m -Xms#{node['server']['jvmms']}m -XX:MaxPermSize=#{node['server']['jvm_max_perm']}"
    java_opts       "-Dserver.config.path=#{::File.join(node['installation_dir'], 'server/configuration')}" + ' ' +
                    "-Dcc.home=#{node['installation_dir']} -Dserver.hostname=#{(node['fqdn'] || node['hostname']).downcase()}" + ' ' +
                    "-Dserver.name=https://#{[(node['fqdn'] || node['hostname']).downcase(), node['web_application_port']].compact().join(':')}" + ' ' +
                    "#{node['console_install_mode'].to_s.eql?('') ? '' : '-Dconsole.install.mode=' + node['console_install_mode'].to_s()}" + ' ' +
                    "#{(node['database_type'].to_s.eql?('ORACLE') && (node['db_server_dn'] != '' || node['db_validate_server_dn'] == 'true')) ? '-Doracle.net.ssl_server_dn_match=true' : ''}" + ' ' +
                    "-Dlog4j.configurationFile=#{::File.join(node['installation_dir'], 'server/configuration/log4j2.xml')}" + ' ' +
                    "-Dlogging.config=file:#{::File.join(node['installation_dir'], 'server/configuration/log4j2.xml')}" + ' ' +
                    "-Dorg.springframework.boot.logging.LoggingSystem=none" + ' ' +
                    "-Dspring.cloud.bootstrap.location=#{::File.join(node['installation_dir'], 'server/configuration/bootstrap.properties')}" + ' ' +
                    "-Djdk.tls.rejectClientInitiatedRenegotiation=true"
    # the attributes on node shouldn't change after chef compile stage, using lazy is just to be safe
    depends_on      lazy { Server::Config.elasticsearch_component?(node) ? node['elasticsearch_service_name'] : '' }
    action          :create

  end

  ControlCenter_config_store_linux 'create_linux_config_store' do
    encrypted_key_store_password    Server::Config.encrypt_password(node, node['key_store_password'])
    encrypted_trust_store_password  Server::Config.encrypt_password(node, node['trust_store_password'])
    config_store_path               Server::Config.linux_server_config_store_path(node)
    action                          :create
  end

  log ProgressLog::INSTALL_SERVICE_CREATE_DONE

end

