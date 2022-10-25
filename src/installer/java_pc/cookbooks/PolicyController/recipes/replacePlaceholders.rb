

$temp_serverxml_location = node['temp_dir'] + '/jpc/server.xml'
$temp_commprofile_location = node['temp_dir'] + '/jpc/commprofile.xml'
$temp_javaSDKProps_location = node['temp_dir'] + '/jpc/JavaSDKService.properties'
$temp_jwtSecretProps_location = node['temp_dir'] + '/jpc/JwtSecretClient.properties'
$temp_dpcProps_location = node['temp_dir'] + '/jpc/dpc.properties'
$temp_connector_location = node['temp_dir'] + '/jpc/connector.txt'

$temp_tomcat_loggerFile_location = node['temp_dir'] + '/jpc/tomcat_logging.txt'
$temp_jboss_file_handler_location = node['temp_dir'] + '/jpc/jboss_file_handler_logging.txt'
$temp_jboss_nextlabs_log_location = node['temp_dir'] + '/jpc/jboss_nextlabs_logging.txt'
$temp_jboss_bluejungle_location = node['temp_dir'] + '/jpc/jboss_bluejungle_logging.txt'
$temp_jboss_agent_location = node['temp_dir'] + '/jpc/jboss_agent_logging.txt'

# Server XML Placeholders
template "server.xml" do
  path "#{$temp_serverxml_location}"
  source 'server.erb'
  variables(
    :pc_host => node['policy_controller_host'],
    :pc_port => node['policy_controller_port'],
    :cc_host => node['cc_host'],
    :cc_port => node['cc_port'],
    :agent_type => node['agent_type'],
    :enable_jwt_filter => node['enable_jwt_filter'].to_s.eql?('true') ? true : false
  )
  action :create
end

# Logger Placeholders
template "tomcat_logging" do
  path "#{$temp_tomcat_loggerFile_location}"
  source 'tomcat_logging.erb'
end

template "jboss_file_handler" do
  path "#{$temp_jboss_file_handler_location}"
  source 'jboss_file_handler_logging.erb'
end

template "jboss_nextlabs_logging" do
  path "#{$temp_jboss_nextlabs_log_location}"
  source 'jboss_nextlabs_log_categ.erb'
end

template "jboss_bluejungle_log_categ" do
  path "#{$temp_jboss_bluejungle_location}"
  source 'jboss_bluejungle_log_categ.erb'
end

template "jboss_agent_log_categ" do
  path "#{$temp_jboss_agent_location}"
  source 'jboss_agent_log_categ.erb'
end


# Commprofile Placeholders
template "commprofile.xml" do
  path "#{$temp_commprofile_location}"
  source "commprofile.xml.erb"
  variables(
    :cc_host => node['cc_host'],
    :cc_port => node['cc_port']
  )
  action :create
end

# JavaSDKService Placeholders
template "JavaSDKService.properties" do
  path "#{$temp_javaSDKProps_location}"
  source "JavaSDKService.properties.erb"
  variables(
    :dpc_path => node['dpc_path']
  )
  action :create
end

#  dpc.properties Placeholders
template "dpc.properties" do
  path "#{$temp_dpcProps_location}"
  source "dpc.properties.erb"
  variables(
    :pc_host => node['policy_controller_host'],
    :pc_port => node['policy_controller_port'],
    :installation_dir => node['installation_dir'],
    :agent_type => node['agent_type'],
    :dpc_path => node['dpc_path'],
    :enable_jwt_filter => node['enable_jwt_filter'].to_s.eql?('true') ? true : false
  )
  action :create
end
