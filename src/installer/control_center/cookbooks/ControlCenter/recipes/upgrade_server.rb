#
# Cookbook Name:: ControlCenter
# Recipe:: upgrade_server
#
# Copyright 2016, Nextlabs Inc.
# Author:: Amila Silva & Duan Shiqiang
#
# All rights reserved - Do Not Redistribute
#
Chef::Resource::RubyBlock.send(:include, Utility::RoboFileUtils)

log 'upgrade start' do
  message '[Progress] Start upgrade'
end

# First make sure the linux user and group are there
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

# stop elasticsearch service
if platform?('windows') && Server::Config.get_current_server_version(node).to_f() > 7.7 \
  && node['dms_component'].to_s.strip.eql?('ON')
  ControlCenter_win_elasticsearch_service 'stop_windows_es_service' do
    service_name    node['elasticsearch_service_name']
    action          :stop
    ignore_failure  true
  end
end

# then backup existing server files
include_recipe 'ControlCenter::backup_server'

# then copy artifacts
include_recipe 'ControlCenter::copy_artifacts'

log ProgressLog::UPGRADE_RESTORE_OLD_SERVER_FILES_CONFIGS_STARTED

# restore custom apps
ruby_block 'custom_apps_restore' do

  block do
    custom_apps_backup_path = ::File.join(node['backup_dir'], 'server/custom_apps')
    custom_apps_path = ::File.join(node['installation_dir'], 'server/custom_apps')
    if ::File.directory?(custom_apps_backup_path)
      robo_cp_r(custom_apps_backup_path, custom_apps_path)
      Chef::Log.info( '[Upgrade] Finished restoring custom_apps folder' )
    end
  end

end

# restore aliased_shares
ruby_block 'aliased_shares_restore' do

  block do
    aliased_shares_backup_path = ::File.join(node['backup_dir'], 'server/aliased_shares')
    aliased_shares_path = ::File.join(node['installation_dir'], 'server/aliased_shares')
    if ::File.directory?(aliased_shares_backup_path)
      robo_cp_r(aliased_shares_backup_path, aliased_shares_path)
      Chef::Log.info( '[Upgrade] Finished restoring custom_apps folder' )
    end
  end

end

# restore user modifiable configuration files
# Configurations.xml, icenet installation won't have this file, so we need to delete new one also
ruby_block 'configurations_xml_restore' do

  block do
    require 'fileutils'
    Chef::Log.info('[Upgrade] Restoring Configuration.xml' )
    configuration_xml_backup_path = ::File.join(node['backup_dir'], 'server/configuration/configuration.xml')
    configuration_xml_path = ::File.join(node['installation_dir'], 'server/configuration/configuration.xml')

    if ::File.exist?(configuration_xml_backup_path)
      FileUtils.cp(configuration_xml_backup_path, configuration_xml_path)
      Chef::Log.info('[Upgrade] Finished restoring Configuration.xml' )
    else
      Chef::Log.info('[Upgrade] No configuration.xml found in previous server. So not storing new one.')
      FileUtils.rm_rf(configuration_xml_path)
    end
  end

end

# server.xml
ruby_block 'server_xml_restore' do

  block do
    require 'fileutils'
    server_xml_backup_path = ::File.join(node['backup_dir'], 'server/configuration/server.xml')
    server_xml_path = ::File.join(node['installation_dir'], 'server/configuration/server.xml')

    FileUtils.cp(server_xml_backup_path, server_xml_path)
    Chef::Log.info( '[Upgrade] Finished restoring server.xml' )
  end

end

# application.properties
ruby_block 'application_properties_restore' do

  block do
    require 'fileutils'
    application_properties_backup_path = ::File.join(node['backup_dir'], 'server/configuration/application.properties')
    application_properties_path = ::File.join(node['installation_dir'], 'server/configuration/application.properties')

    if ::File.exist?(application_properties_backup_path)
      FileUtils.cp(application_properties_backup_path, application_properties_path)
      Chef::Log.info('[Upgrade] Finished restoring application.properties' )
    end
  end

end

# bootstrap.properties
ruby_block 'bootstrap_properties_restore' do

  block do
    require 'fileutils'
    bootstrap_properties_backup_path = ::File.join(node['backup_dir'], 'server/configuration/bootstrap.properties')
    bootstrap_properties_path = ::File.join(node['installation_dir'], 'server/configuration/bootstrap.properties')

    if ::File.exist?(bootstrap_properties_backup_path)
      FileUtils.cp(bootstrap_properties_backup_path, bootstrap_properties_path)
      Chef::Log.info('[Upgrade] Finished restoring bootstrap.properties' )
    end
  end

end

# restore certificates, but only for newer systems. Systems prior to 8.5 will keep a
# couple of certs around for legacy purposes, but for the most part they will get new
# certs
ruby_block 'restore_server_certificates' do

  block do
    require 'fileutils'
    Chef::Log.info( '[Upgrade] Restoring server certificates' )
    certs_path = ::File.join(node['installation_dir'], 'server/certificates')

    FileUtils.rm_rf(certs_path, secure: true)
    FileUtils.mkdir_p(certs_path)

    robo_cp_r(::File.join(node['backup_dir'], 'server/certificates'), certs_path)

    Chef::Log.info( '[Upgrade] Finished restoring server certificates' )
  end
  only_if { Server::Config.get_current_server_version(node).to_f >= 8.5 &&
            node['dms_component'].to_s.strip.eql?('ON') }
end

# restore enrollment backup if exist
ruby_block 'restore enrollment tool' do
  block do
    enrollment_backup_path = ::File.join(node['backup_dir'], 'tools/enrollment')
    enrollment_path = ::File.join(node['installation_dir'], 'tools/enrollment')
    if ::File.directory?(enrollment_backup_path)
      robo_cp_r(enrollment_backup_path, enrollment_path)
    end

    # But make sure we use the new .jar files
    Dir.glob(::File.join(node['dist_server_dir'], 'tools/enrollment/*.jar')) { |enrollment_jar_dist|
      enrollment_jar_install = ::File.join(node['installation_dir'], 'tools/enrollment', ::File.basename(enrollment_jar_dist))
      FileUtils.cp_r(enrollment_jar_dist, enrollment_jar_install)
    }
    FileUtils.cp(::File.join(node['dist_server_dir'], 'tools/enrollment/enrollmgr.bat'), ::File.join(node['installation_dir'], 'tools/enrollment/enrollmgr.bat'))
    FileUtils.cp(::File.join(node['dist_server_dir'], 'tools/enrollment/enrollmgr.sh'), ::File.join(node['installation_dir'], 'tools/enrollment/enrollmgr.sh'))
    FileUtils.cp(::File.join(node['dist_server_dir'], 'tools/enrollment/propertymgr.bat'), ::File.join(node['installation_dir'], 'tools/enrollment/propertymgr.bat'))
    FileUtils.cp(::File.join(node['dist_server_dir'], 'tools/enrollment/propertymgr.sh'), ::File.join(node['installation_dir'], 'tools/enrollment/propertymgr.sh'))
  end
end

# but if we were upgrading from a 8.5 system, we want the new enrollment keystore
# with the nicer certs

ruby_block 'upgrade to 8.5 enrollment certs' do
  block do
    require 'fileutils'
    enrollment_keystore_dist = ::File.join(node['dist_server_dir'], 'tools/enrollment/security/enrollment-keystore.jks')
    enrollment_keystore_install = ::File.join(node['installation_dir'], 'tools/enrollment/security/enrollment-keystore.jks')
    
    FileUtils.cp(enrollment_keystore_dist, enrollment_keystore_install)
  end
  only_if { Server::Config.get_current_server_version(node).to_f < 8.5 } 
end

ruby_block 'add delete-inactive-groupmembers to def' do
  block do
    require 'fileutils'
    def_files_path = ::File.join(node['installation_dir'], 'tools/enrollment/')
    def_files = [ "ad.sample.default.def", "domainGroup.sample.default.def", "ldif.sample.default.def" ]

    replacement_string = "\n# optional, default is false\n"\
                         "# inactive group members (whether users or other groups) will be removed\n"\
                         "# from the enrollment rather than merely being marked as inactive\n"\
                         "delete.inactive.group.members       false\n"

    def_files.each do |file|
      def_file_full_path = def_files_path + file

      Chef::Log.info("Looking for file #{def_file_full_path}");
      if ::File.exist?(def_file_full_path) 
        Chef::Log.info("Adding delete.inactive.group.members to #{def_file_full_path}");
        fe = Chef::Util::FileEdit.new(def_file_full_path)

        if not fe.insert_line_after_match("^enroll.groups.*$", replacement_string)
          fe.insert_line_after_match("^enroll.applications.*$", replacement_string)
        end
        fe.write_file()
      end
    end
  end
  only_if { Server::Config.get_current_server_version(node).to_f < 8.7 }
end

# restore other properties files if exist
ruby_block 'restore cc-console-app.properties' do

  block do
    require 'fileutils'
    ['cc-console-app.properties', 'cas.properties'].each { |f|
      properties_backup_path = ::File.join(node['backup_dir'], 'server/configuration', f)
      properties_path = ::File.join(node['installation_dir'], 'server/configuration', f)
      if ::File.exist?(properties_backup_path)
        FileUtils.cp(properties_backup_path, properties_path)
      end
    }
  end

end

# create openaz-pep.properties file for upgrade from below 8.1.2
# openaz-pep.properties file
template "#{::File.join(node['installation_dir'], 'server', 'configuration', 'openaz-pep.properties')}" do
  source 'openaz-pep.properties.erb'
  action :create
  only_if { node['cc_console_component'].to_s.strip.eql?('ON') || node['dms_component'].to_s.strip().eql?('ON') }
end

# restore license file
ControlCenter_deploy_license 'restore_server_license' do
  license_path  ::File.join(node['backup_dir'], 'server/license/license.dat')
  deploy_path   ::File.join(node['installation_dir'], 'server/license')
  only_if { node['dms_component'].to_s.strip.eql?('ON') }
end

log ProgressLog::UPGRADE_RESTORE_OLD_SERVER_FILES_CONFIGS_DONE

# **for upgrade from 7.7 and below**
# if the server installs dms (management server), then add cc-sonsole and cas to its server.xml
ruby_block 'add_cc_console_and_cas_to_server.xml' do
  block do
    server_xml_path = ::File.join(node['installation_dir'], 'server/configuration/server.xml')

    line_to_append = line_to_append = <<-LINES_TO_APPEND.gsub(/^ {2}/, "\t")
      <!--[CC_CONSOLE_BEGIN]
          <Context path="/console" reloadable="false" docBase="${catalina.home}/../apps/control-center-console.war" workDir="${catalina.home}/work/console">
          </Context>
        [CC_CONSOLE_END]-->

        <!--[CAS_BEGIN]-->
          <Context path="/cas" reloadable="false" docBase="${catalina.home}/../apps/cas.war" workDir="${catalina.home}/work/cas">
          </Context>
        <!--[CAS_END]-->
    LINES_TO_APPEND

    fe = Chef::Util::FileEdit.new(server_xml_path)
    fe.insert_line_after_match(/REPORTER_COMPONENT_END\]-->/, line_to_append)
    fe.write_file()
  end

  only_if { Server::Config.get_current_server_version(node).to_f <= 7.7 &&
      node['dms_component'].to_s.strip.eql?('ON') }
end

# if upgrade is from below 9.0 version, then add config-service to server.xml
ruby_block 'add_config_service_to_server.xml' do
  block do
    server_xml_path = ::File.join(node['installation_dir'], 'server/configuration/server.xml')
    doc = REXML::Document.new(::File.read(server_xml_path))
    storePassword = ''
    REXML::XPath.each( doc, "//Server/Service[@name=\"CE-Apps\"]/Connector") { |connector|
      storePassword = connector.attribute("keystorePass").value()
    }
    content_to_append = content_to_append = <<-LINES_TO_APPEND.gsub(/^ {4}/, "\t")

    <!--[CONFIG_SERVICE_COMPONENT_BEGIN]-->
    <Service name="CE-Config">
        <Connector  port="7443"
                    enableLookups="false"
                    sslImplementationName="org.apache.tomcat.util.net.jsse.JSSEImplementation"
                    protocol="com.bluejungle.destiny.server.security.secureConnector.SecurePasswordHttp11NioProtocol"
                    scheme="https"
                    secure="true"
                    SSLEnabled="true"
                    sslProtocol="TLS"
                    sslEnabledProtocols="TLSv1.1,TLSv1.2,SSLv2Hello"
                    acceptCount="100"
                    connectionTimeout="60000"
                    keystoreFile="${catalina.home}/../certificates/web-keystore.jks"
                    keystorePass="[GENERATED_KEY]"
                    keystoreType="JKS"
                    truststoreType="JKS"
                    truststoreFile="${catalina.home}/../certificates/web-truststore.jks"
                    truststorePass="[GENERATED_KEY]"
                    clientAuth="false">
        </Connector>
        <Engine name="CE-Config" defaultHost="localhost" debug="1">
            <Host name="localhost"
                  debug="0"
                  autoDeploy="false"
                  unpackWARs = "true"
                  xmlValidation="false"
                  xmlNamespaceAware="false"
                  appBase="${catalina.base}/apps/config">
                <Context path="/config-service" reloadable="false" docBase="${catalina.home}/../apps/config-service.war" workDir="${catalina.home}/work/config-service">
                </Context>
            </Host>
        </Engine>
    </Service>
    <!--[CONFIG_SERVICE_COMPONENT_END]-->
    LINES_TO_APPEND
    content_to_append = content_to_append.gsub('[GENERATED_KEY]', storePassword)
    fe = Chef::Util::FileEdit.new(server_xml_path)
    fe.insert_line_after_match(/<\/GlobalNamingResources>/, content_to_append)
    fe.write_file()
  end

  only_if { Server::Config.get_current_server_version(node).to_f < 9.0 &&
      node['dms_component'].to_s.strip.eql?('ON') }
end

# Add tomcat8.5 changes to server.xml
ruby_block 'add_tomcat_8_5_changes_to_server.xml' do
  block do
    server_xml_path = ::File.join(node['installation_dir'], 'server/configuration/server.xml')

    fe = Chef::Util::FileEdit.new(server_xml_path)
	search_line = "protocol=\"com.bluejungle.destiny.server.security.secureConnector.SecureHttp11Protocol\""
    replace_line = "sslImplementationName=\"org.apache.tomcat.util.net.jsse.JSSEImplementation\"\n                protocol=\"com.bluejungle.destiny.server.security.secureConnector.SecureHttp11NioProtocol\""

    fe.search_file_replace(search_line, replace_line)
	search_line = "protocol=\"com.bluejungle.destiny.server.security.secureConnector.SecurePasswordHttp11Protocol\""
    replace_line = "sslImplementationName=\"org.apache.tomcat.util.net.jsse.JSSEImplementation\"\n                           protocol=\"com.bluejungle.destiny.server.security.secureConnector.SecurePasswordHttp11NioProtocol\""
    fe.search_file_replace(search_line, replace_line)
    fe.write_file()
  end
  only_if { Server::Config.get_current_server_version(node).to_f < 8.6 &&
            node['dms_component'].to_s.strip.eql?('ON') }
end

# Update server.xml
# 1) Always remove TLSv1 SSL protocol from server.xml, if any is found
#    if customer decided to use TLSv1, customer should append TLSv1 to the end of the protocol list
# 2) Set unpackWARs to true, this is essential for Axis2 to work
# 3) Replace CE-Core's appBase to avoid double loading of applications
ruby_block 'update_server.xml' do
  block do
    server_xml_path = ::File.join(node['installation_dir'], 'server/configuration/server.xml')
    fe = Chef::Util::FileEdit.new(server_xml_path)
    fe.search_file_replace(/TLSv1,TLSv1.1,TLSv1.2,SSLv2Hello/, "TLSv1.1,TLSv1.2,SSLv2Hello")
    fe.search_file_replace(/unpackWARs = "false"/, "unpackWARs=\"true\"")
    fe.search_file_replace(/\$\{catalina.base\}\/webapps/, "${catalina.base}/apps/core")
    fe.write_file()
  end
end

# ** for upgrades from below 8.5
# We completely rev'd the certs for 8.5, replacing everything with stronger encryption. The
# old dcc, agent, and temp_agent entries are kept around under different names for backwards
# compatibility
ruby_block 'handle pre 8.5 legacy certs' do
  block do
    require 'fileutils'
    backup_keystore_path = ::File.join(node['backup_dir'], 'server/certificates')
    keystore_path = ::File.join(node['installation_dir'], 'server/certificates')
    
    key_store_password = Server::Config.decrypt_password(node, node['encrypted_key_store_password'])
    trust_store_password = Server::Config.decrypt_password(node, node['encrypted_trust_store_password'])

    # First, build the new certs/keystores
    #
    Server::Certs.create_all_certificates(node, keystore_path, key_store_password, trust_store_password)

    # That last step generates backwards compatibility certs, but we'd
    # rather use the ones from the previous installation (already
    # registered agents need them, among other things)
    #
    # When importing into a truststore we use the .cer file, which
    # contains just the public key If we want public/private we have
    # to copy store to store

    # Old dcc keypair
    FileUtils.mv(::File.join(backup_keystore_path, 'dcc.cer'), ::File.join(keystore_path, 'legacy-dcc.cer'))
    Server::Certs.delete_entry(node, 'DCC', keystore_path, 'legacy-agent-truststore.jks', trust_store_password)
    Server::Certs.import_cert_into_truststore(node, 'DCC', keystore_path, 'legacy-dcc.cer', 'legacy-agent-truststore.jks', key_store_password)
    
    Server::Certs.delete_entry(node, 'Legacy_DCC', keystore_path, 'dcc-keystore.jks', key_store_password)
    Server::Certs.import_from_keystore(node, 'DCC', backup_keystore_path, 'dcc-keystore.jks', key_store_password, 'Legacy_DCC', keystore_path, 'dcc-keystore.jks', key_store_password)

    # Old agent keypair
    FileUtils.mv(::File.join(backup_keystore_path, 'agent.cer'), ::File.join(keystore_path, 'legacy-agent.cer'))

    # Prior to 9.0, there were no separate key/trust passwords, so we should use the key_store_password for legacy truststores
    Server::Certs.delete_entry(node, 'Agent', keystore_path, 'legacy-agent-truststore.jks', key_store_password)
    Server::Certs.import_cert_into_truststore(node, 'Agent', keystore_path, 'legacy-agent.cer', 'legacy-agent-truststore.jks', key_store_password)
    
    Server::Certs.delete_entry(node, 'Legacy_Agent', keystore_path, 'dcc-truststore.jks', trust_store_password)
    Server::Certs.import_cert_into_truststore(node, 'Legacy_Agent', keystore_path, 'legacy-agent.cer', 'dcc-truststore.jks', trust_store_password)
    
    Server::Certs.delete_entry(node, 'Agent', keystore_path, 'legacy-agent-keystore.jks', key_store_password)
    Server::Certs.import_from_keystore(node, 'Agent', backup_keystore_path, 'agent-keystore.jks', key_store_password, 'Agent', keystore_path, 'legacy-agent-keystore.jks', key_store_password)

    # Old temp agent keypair (probably not changed, but it's barely possible a customer did it)
    FileUtils.mv(::File.join(backup_keystore_path, 'temp_agent.cer'), ::File.join(keystore_path, 'orig_temp_agent.cer'))
    Server::Certs.delete_entry(node, 'Orig_Temp_Agent', keystore_path, 'dcc-truststore.jks', trust_store_password)
    Server::Certs.import_cert_into_truststore(node, 'Orig_Temp_Agent', keystore_path, 'orig_temp_agent.cer', 'dcc-truststore.jks', trust_store_password)
    
    # Remove DCC certificate from web-truststore.jks, it will be added back in later code
    Server::Certs.delete_entry(node, 'DCC', keystore_path, 'web-truststore.jks', trust_store_password)
    
    Chef::Log.debug("Retained previous certs where possible")
  end
  only_if { Server::Config.get_current_server_version(node).to_f < 8.5 &&
            node['dms_component'].to_s.strip.eql?('ON') }
end

ruby_block 'handle pre 9.0 legacy certs' do
  block do
    require 'fileutils'
    keystore_path = ::File.join(node['installation_dir'], 'server/certificates')
    key_store_password = Server::Config.decrypt_password(node, node['encrypted_key_store_password'])
    
    # Prior to 9.0, there were no separate key/trust passwords, so we should use the key_store_password for legacy truststores
    #
    # Under these circumstances, the legacy-agent-truststore-kp.jks will be exactly the same as the agent-truststore.jks. Should
    # we just copy that file isntead of doing this?
    Server::Certs.import_cert_into_truststore(node, 'DCC', keystore_path, 'dcc.cer', 'legacy-agent-truststore-kp.jks', key_store_password)
    Server::Certs.import_cert_into_truststore(node, 'Agent', keystore_path, 'agent.cer', 'legacy-agent-truststore-kp.jks', key_store_password)
    
  end
  only_if { Server::Config.get_current_server_version(node).to_f < 9.0 &&
            Server::Config.get_current_server_version(node).to_f >= 8.5 &&
            node['dms_component'].to_s.strip.eql?('ON') }
end

# Import DCC certificate into web-truststore.jks if upgrade from version below 9.1
ruby_block 'import DCC cert to truststore' do
  block do
    require 'fileutils'
    keystore_path = ::File.join(node['installation_dir'], 'server/certificates')
    trust_store_password = Server::Config.decrypt_password(node, node['encrypted_trust_store_password'])
    
    # Prior to 9.1, we are not using web-truststore.jks as default truststore
    Server::Certs.import_cert_into_truststore(node, 'DCC', keystore_path, 'dcc.cer', 'web-truststore.jks', trust_store_password)
    
  end
  only_if { Server::Config.get_current_server_version(node).to_f < 9.1 &&
            node['dms_component'].to_s.strip.eql?('ON') }
end

# for upgrades from below 8.7
# we have added digital signature feature
# always create keystore and truststore no matter user opt for digital signature or not
# this will ease switching between different import/export format manually
#
# However, from versions before 8.5 we create the digital certs and others
# (see handle legacy certs), so we only need to create the digital certs if
# we are between 8.5 and 8.7
ruby_block 'handle digital signature certs' do
  block do
    require 'fileutils'
    keystore_path = ::File.join(node['installation_dir'], 'server/certificates')
    key_store_password = Server::Config.decrypt_password(node, node['encrypted_key_store_password'])
    trust_store_password = Server::Config.decrypt_password(node, node['encrypted_trust_store_password'])

    Server::Certs.create_digital_signature_certificate(node, keystore_path, key_store_password, trust_store_password)
  end
  only_if { Server::Config.get_current_server_version(node).to_f < 8.7 &&
            Server::Config.get_current_server_version(node).to_f >= 8.5 &&
            node['dms_component'].to_s.strip.eql?('ON') }
end

# Going along with 'handle legacy certs', we now have two keys in the dcc-keystore and we have
# to tell the system which one to use. The line  keyAlias="dcc"  should go somewhere in the Connector
# that's part of the CE-Core Service
ruby_block 'add dcc keyalias' do
  block do
    server_xml_path = ::File.join(node['installation_dir'], 'server/configuration/server.xml')

    line_to_append = "keyAlias=\"dcc\""

    fe = Chef::Util::FileEdit.new(server_xml_path)
    fe.insert_line_after_match(/keystoreFile.*dcc-keystore.jks/, line_to_append)
    fe.write_file()
  end
  only_if { Server::Config.get_current_server_version(node).to_f < 8.5 &&
            node['dms_component'].to_s.strip.eql?('ON') }
end

# For login security enhancement, enforce password history upon changing password
ruby_block 'login security enhancement' do
  block do
    require 'fileutils'
    server_xml_path = ::File.join(node['installation_dir'], 'server/configuration/server.xml')
    
    if ::File.exist? server_xml_path
      fe = Chef::Util::FileEdit.new(server_xml_path)
        # Administrator component
        admin_line_to_append = admin_line_to_append = <<-ADMIN_LINE_TO_APPEND.gsub(/ {2}/, "\t")
            <Parameter name="EnforcePasswordHistory" value="5"/>
        ADMIN_LINE_TO_APPEND
        fe.insert_line_after_match(/work\/administrator\">/, admin_line_to_append)
        
        # Reporter component
        report_line_to_append = report_line_to_append = <<-REPORT_LINE_TO_APPEND.gsub(/ {2}/, "\t")
            <Parameter name="EnforcePasswordHistory" value="5"/>
        REPORT_LINE_TO_APPEND
      fe.insert_line_after_match(/work\/reporter\">/, report_line_to_append)
      
      fe.write_file()
    end
  end
  only_if {Server::Config.get_current_server_version(node).to_f < 8.6}
end

# From CC 9.1 onwards Java cacerts no longer in use.
# User needs to import their custom certificates into web-truststore.jks
ruby_block 'import database ssl cert' do
  block do
    keystore_path = ::File.join(node['installation_dir'], 'server/certificates')
    trust_store_password = Server::Config.decrypt_password(node, node['encrypted_trust_store_password'])
    Server::Certs.import_db_ssl_certificate(node, keystore_path, trust_store_password)
  end
  only_if { Server::Config.get_current_server_version(node).to_f == 9.0}
end


# database schema creation and initialization
log ProgressLog::UPGRADE_DATABASE_MANIPULATE_STARTED do
  only_if { Server::Config.init_db?(node) }
end

# dbinit configuration file token modifications
ControlCenter_db_init_tool 'token_modification' do
  admin_user_password   node['admin_user_password']
  db_init_dir           ::File.join(node['installation_dir'], 'tools/dbInit')
  only_if { Server::Config.init_db?(node) }
end

ControlCenter_db_init 'upgrade' do
  logging_path          node['log_dir']
  only_if { Server::Config.init_db?(node) }
end

log ProgressLog::UPGRADE_DATABASE_MANIPULATE_DONE do
  only_if { Server::Config.init_db?(node) }
end

# clear db init cfg file with sensitive data
ControlCenter_db_init_tool 'clear_sensitive_cfg_data' do
  db_init_dir           ::File.join(node['installation_dir'], 'tools/dbInit')
  action                :clean
  only_if { Server::Config.init_db?(node) }
end

# shortcuts, etc no need to change, if exist in backup , just copy back
ruby_block 'restore_shortcuts_if_existing' do
  block do
    require 'fileutils'
    %w[administrator.url reporter.url].each {|f|
      if ::File.exist?(::File.join(node['backup_dir'], f))
        FileUtils.cp_r(
            ::File.join(node['backup_dir'], f),
            ::File.join(node['installation_dir'],f)
        )
      end
    }
  end
end

# For upgrade from 7.7, add console's shortcut for windows
ruby_block "add_console's windows shortcut" do
  block do
    require 'fileutils'
    administrator_url_file_path = ::File.join(node['installation_dir'], 'administrator.url')
    console_url_file_path = ::File.join(node['installation_dir'], 'console.url')
    if ::File.exist?(administrator_url_file_path)
      # copy the file content for console.url
      console_url_file = ::File.open(console_url_file_path, 'w')
      File.open(administrator_url_file_path).each do |line|
        console_url_file.puts(line.gsub('administrator', 'console'))
      end
      console_url_file.close()
      # Then copy the shortcut to default location
      startMenuDirLocation = Server::Config.win_start_shortcut_path()
      FileUtils.mkdir_p(startMenuDirLocation)
      FileUtils.cp(console_url_file_path, ::File.join(startMenuDirLocation, 'Console.url'))
    end
  end
  only_if { node['cc_console_component'].eql?('ON') &&
      Server::Config.get_current_server_version(node).to_f() <= 7.7 }
end

ruby_block "remove ddac from server.xml" do
  block do
    require 'fileutils'
    Chef::Log.info( '[Upgrade] Removing ddac from server.xml' )
    server_xml_path = ::File.join(node['installation_dir'], 'server/configuration/server.xml')

    fe = Chef::Util::FileEdit.new(server_xml_path)

    fe.search_file_replace_line(/<!--\[DDAC_COMPONENT_BEGIN\]-->/, "<!--\[DDAC_COMPONENT_BEGIN\]")
    fe.search_file_replace_line(/<!--\[DDAC_COMPONENT_END\]-->/, "\[DDAC_COMPONENT_END\]-->")
    fe.write_file()
  end
  only_if { Server::Config.get_current_server_version(node).to_f() < 9.0 }
end

ruby_block "remove help from server.xml" do
  block do
    require 'fileutils'
    Chef::Log.info( '[Upgrade] Removing help from server.xml' )
    server_xml_path = ::File.join(node['installation_dir'], 'server/configuration/server.xml')

    fe = Chef::Util::FileEdit.new(server_xml_path)

    fe.search_file_replace_line(/<!--\[HELP_BEGIN\]-->/, "<!--\[HELP_BEGIN\]")
    fe.search_file_replace_line(/<!--\[HELP_END\]-->/, "\[HELP_END\]-->")
    fe.write_file()
  end
  only_if { Server::Config.get_current_server_version(node).to_f() < 9.0 }
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
      :db_encrypted_password  => node['db_encrypted_password'].to_s.strip(),
      :db_driver              => Utility::DB.get_db_driver(node['database_type'].to_s.strip),
      :db_dialect             => Utility::DB.get_cas_db_dialect(node['database_type'].to_s.strip)
  })
  action :create
  only_if { node['dms_component'].to_s.strip.eql?('ON') &&
            Server::Config.get_current_server_version(node).to_f() < 9.0}
end

# bootstrap.properties file
template "#{::File.join(node['installation_dir'], 'server', 'configuration', 'bootstrap.properties')}" do
  source 'bootstrap.properties.erb'
  variables ({
      :host                                 => (node['fqdn'] || node['hostname']).downcase(),
      :config_service_port                  => (node['config_service_port'] == nil || node['config_service_port'].to_s.strip == '') ? '7443' : node['config_service_port'],
      :config_service_encrypted_password    => Server::Config.encrypt_password(node, SecureRandom.base64)
  })
  action :create
  only_if { Server::Config.server_version_newer?(Server::Config.get_current_server_version(node), '9.0') }
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
    java_executable = case RUBY_PLATFORM
                        when /mswin|mingw|windows/
                          'java.exe'
                        when /linux/
                          'java'
                        end
    jre_x_path = File.join(node['dist_server_dir'], 'java', 'jre', 'bin', java_executable)
    classpath_separator = case RUBY_PLATFORM
                            when /mswin|mingw|windows/
                              ';'
                            when /linux/
                              ':'
                            end
    cryptJarFile = File.join(node['dist_server_dir'], 'tools', 'crypt', 'crypt.jar')
    support_dir = File.join(node['dist_folder'], 'support')
    classpath = Dir[support_dir + '/*.jar'].join(classpath_separator) + classpath_separator + cryptJarFile
    truststore_file = File.join(node['installation_dir'], 'server/certificates/web-truststore.jks')

    Chef::Log.info('[Upgrade] Update configurations started')
    command = "\"#{jre_x_path}\" "
    command += "-cp \"#{classpath}\" "
    command += "-Ddb.driver=\"#{Utility::DB.get_db_driver(node['database_type'].to_s.strip)}\" "
    command += "-Ddb.url=\"#{Utility::DB.db_connection_url(node['database_type'].to_s.strip, node['db_connection_url'].to_s.strip)}\" "
    command += "-Ddb.username=\"#{node['db_username'].to_s.strip()}\" "
    command += "-Ddb.password=\"#{node['db_encrypted_password'].to_s.strip()}\" "
    command += "-Djavax.net.ssl.trustStore=\"#{truststore_file}\" "
    command += "-Djavax.net.ssl.trustStorePassword=\"#{node['trust_store_password'].to_s.strip()}\" "
    command += "-Dconfig.dir=\"#{::File.join(node['installation_dir'], 'server/configuration')}\" "
    command += "-Dapp_application.application.version=\"#{node['version_number']}-#{node['build_number']}\" "
    if(Server::Config.get_current_server_version(node).to_f() < 9.0)
      command += "-Dapp_application.server.name=\"https://#{[(node['fqdn'] || node['hostname']).downcase(), node['web_application_port']].compact().join(':')}\" "
      command += "-Dapp_application.web.service.server.name=\"https://#{[(node['fqdn'] || node['hostname']).downcase(), node['web_service_port']].compact().join(':')}\" "
      command += "-Dapp_application.config.activeMQConnectionFactory.brokerURL=\"failover:(tcp://#{(node['fqdn'] || node['hostname']).downcase()}:61616)\" "
      command += "-Dapp_config-service.activemq.broker.connector.bindAddress=\"tcp://#{(node['fqdn'] || node['hostname']).downcase()}:61616\" "
    end
    if(Server::Config.server_version_newer?(Server::Config.get_current_server_version(node), '8.7'))
      data_transportation_key = (node['data_transportation_shared_key'] == nil || node['data_transportation_shared_key'] == '') ? '' : Server::Config.encrypt_password(node, node['data_transportation_shared_key'].to_s.strip)
      command += "-Dapp_console.data.transportation.allow.plain.text.export=\"#{node['data_transportation_plain_text_export']}\" "
      command += "-Dapp_console.data.transportation.allow.plain.text.import=\"#{node['data_transportation_plain_text_import']}\" "
      command += "-Dapp_console.data.transportation.keystore.file=\"#{::File.join(node['installation_dir'], 'server/certificates/digital-signature-keystore.jks')}\" "
      command += "-Dapp_console.data.transportation.mode=\"#{node['data_transportation_mode']}\" "
      command += "-Dapp_console.data.transportation.shared.key=\"#{data_transportation_key}\" "
    end
    command += "com.nextlabs.installer.controlcenter.confighelper.ConfigHelper"
    Chef::Log.debug('[Install] CONFIG UPDATE ' + command)
    #puts "#{command}"
    IO.popen(command, :err=>[:child, :out]) { |io|
      io.each do |line|
          Chef::Log.info(line)
      end
    }
    Chef::Log.info('[Upgrade] Update configurations completed')
  end
  only_if { node['dms_component'].to_s.strip.eql?('ON') }
end

include_recipe 'ControlCenter::fix_file_permission'

# Create elasticsearch service, cc 7.7 doesn't have cc-console, so upgrade means freshly create it
if Server::Config.elasticsearch_component?(node) &&
    Server::Config.get_current_server_version(node).to_f() < 9.0

  log ProgressLog::UPGRADE_CREATE_NEW_SERVICE_STARTED

  if platform?('windows')
    if Server::Config.elasticsearch_component?(node) && Server::Config.get_current_server_version(node).to_f() > 7.7
      ControlCenter_win_elasticsearch_service 'remove_windows_es_service' do
        es_home       node['es_home']
        java_home     ::File.join(node['installation_dir'], 'java', 'jre')
        service_name  node['elasticsearch_service_name']
        action        :delete
        ignore_failure true
        only_if       { ::File.directory?(es_home) }
      end
    end

    ControlCenter_win_elasticsearch_service 'create_windows_es_service' do
      es_home       node['es_home']
      java_home     ::File.join(node['installation_dir'], 'java', 'jre')
      service_name  node['elasticsearch_service_name']
      display_name  node['winx']['elasticsearch_display_name']
      action        :create
    end
  end

  log ProgressLog::UPGRADE_CREATE_NEW_SERVICE_DONE

end

log ProgressLog::UPGRADE_MODIFY_EXISTING_SERVICE_STARTED

# upgrade service
if platform?('windows')
  if Server::Config.is_existing_server_msi?
    ControlCenter_windows_service 'upgrade_windows_service' do
      service_name      node['winx']['service_name']
      description       node['winx']['description']
      display_name      node['winx']['display_name']
      install_dir       node['installation_dir']
      jvm_max_perm      node['server']['jvm_max_perm']
      jvmms             node['server']['jvmms']
      jvmmx             node['server']['jvmmx']
      version_number    node['version_number']
      procrun_path      ::File.join(node['installation_dir'], 'server/tomcat/bin/PolicyServer.exe')
      registry_key_name "HKEY_LOCAL_MACHINE\\#{node['REGISTY_KEY_NAME']}"
      built_date        node['built_date']
      hostname          (node['fqdn'] || node['hostname']).downcase()
      web_application_port          node['web_application_port']
      console_install_mode          node['console_install_mode']
      depends_on        lazy { Server::Config.elasticsearch_component?(node) ? node['elasticsearch_service_name'] : '' }
      action            :upgrade_msi
    end
  else
    ControlCenter_windows_service 'upgrade_windows_service' do
      service_name      node['winx']['service_name']
      install_dir       node['installation_dir']
      procrun_path      ::File.join(node['installation_dir'], 'server/tomcat/bin/PolicyServer.exe')
      registry_key_name "HKEY_LOCAL_MACHINE\\#{node['REGISTY_KEY_NAME']}"
      built_date        node['built_date']
      version_number    node['version_number']
      depends_on        lazy { Server::Config.elasticsearch_component?(node) ? node['elasticsearch_service_name'] : '' }
      hostname          (node['fqdn'] || node['hostname']).downcase()
      web_application_port node['web_application_port']
      console_install_mode node['console_install_mode']
      exising_server_version Server::Config.get_current_server_version(node)
      if Server::Config.get_current_server_version(node).to_f <= 7.7
        console_install_mode 'OPL'
      end
      action            :upgrade
    end
  end

else
  # Create systemd services
  if Server::Config.get_current_server_version(node).to_f < 9.0
    ControlCenter_linux_elasticsearch_service 'create_linux_es_service' do
      es_home       node['es_home']
      java_home     ::File.join(node['installation_dir'], 'java', 'jre')
      service_name  node['elasticsearch_service_name']
      es_user       node['linux']['user']
      es_group      node['linux']['group']
      action        :create
    end
  end
  
  ## We need to upgrade 8.7 systemd file to add a new logging flag. to_f() won't let
  ## us distinguish between 8.7 and 8.7.2
  if Server::Config.server_version_newer?(Server::Config.get_current_server_version(node), '9.1')
    ControlCenter_linux_service 'create_linux_service' do
      service_name    node['linux']['service_name']
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
                      "-Dnextlabs.evaluation.uses.resource.type=false" + ' ' +
                      "-Dlog4j.configurationFile=#{::File.join(node['installation_dir'], 'server/configuration/log4j2.xml')}" + ' ' +
                      "-Dlogging.config=file:#{::File.join(node['installation_dir'], 'server/configuration/log4j2.xml')}" + ' ' +
                      "-Dorg.springframework.boot.logging.LoggingSystem=none"  + ' ' +
                      "-Dspring.cloud.bootstrap.location=#{::File.join(node['installation_dir'], 'server/configuration/bootstrap.properties')}" + ' ' +
                      "-Djdk.tls.rejectClientInitiatedRenegotiation=true "
      # the attributes on node shouldn't change after chef compile stage, using lazy is just to be safe
      exising_server_version Server::Config.get_current_server_version(node)
      depends_on      lazy { Server::Config.elasticsearch_component?(node) ? node['elasticsearch_service_name'] : '' }
      action          :create
    end
  end

  ## Prior to 8.7 we didn't use systemd at all, so we upgrade everything
  if Server::Config.get_current_server_version(node).to_f < 8.7
    ControlCenter_linux_elasticsearch_service 'create_linux_es_service' do
      es_home       node['es_home']
      java_home     ::File.join(node['installation_dir'], 'java', 'jre')
      service_name  node['elasticsearch_service_name']
      es_user       node['linux']['user']
      es_group      node['linux']['group']
      action        :create
    end

    # remove daemon.sh
    ::FileUtils.rm_rf(::File.expand_path('../daemon.sh', Server::Config.linux_server_config_path(node)))
    
    # remove old System V init files
    ::FileUtils.rm_rf("/etc/init.d/#{node['linux']['service_name']}")
    ::FileUtils.rm_rf("/etc/init.d/#{node['elasticsearch_service_name']}")

    # remove old config files
    ::FileUtils.rm_rf(Server::Config.linux_server_config_path(node))
    ::FileUtils.rm_rf(::File.expand_path('../elasticsearch.conf', Server::Config.linux_server_config_path(node)))
  end
end

log ProgressLog::UPGRADE_MODIFY_EXISTING_SERVICE_DONE
