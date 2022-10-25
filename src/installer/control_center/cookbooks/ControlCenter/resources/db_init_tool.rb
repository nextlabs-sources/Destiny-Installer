#
# Cookbook Name:: ControlCenter
# Resource:: db_init_tool
#
# Copyright 2016, Nextlabs Inc.
# Author:: Duan Shiqiang
#
# All rights reserved - Do Not Redistribute
#
# Prepare the db init tool under tools folder of installation directory to do db_init tasks
property :db_init_dir, String, required: true
property :admin_user_password, String

action :prepare do
  # dbinit configuration file token modifications
  ruby_block 'db_init_config_file_modification' do

    block do

      dictionary_token_values = Hash.new
      dictionary_templateFile = ::File.join(db_init_dir, 'dictionary/dictionary_template.cfg')
      dictionary_file = ::File.join(db_init_dir, 'dictionary/dictionary.cfg')

      pf_token_values = Hash.new
      pf_token_values[ConfigTokens::BLUEJUNGLE_HOME_TOKEN] = ::File.join(db_init_dir, 'pf')
      pf_templateFile = ::File.join(db_init_dir, 'pf/pf_template.cfg')
      pf_file = ::File.join(db_init_dir, 'pf/pf.cfg')

      mgmt_token_values = Hash.new
      # for upgrade, the admin_user_password will be set to empty string, but doesn't matter
      mgmt_token_values[ConfigTokens::ADMIN_PASSWORD_TOKEN] = admin_user_password.to_s.strip
      mgmt_templateFile = ::File.join(db_init_dir, 'mgmt/mgmt_template.cfg')
      mgmt_file = ::File.join(db_init_dir, 'mgmt/mgmt.cfg')

      Server::Config.replace_in_file(dictionary_templateFile, dictionary_file, dictionary_token_values)
      Server::Config.replace_in_file(pf_templateFile, pf_file, pf_token_values)
      Server::Config.replace_in_file(mgmt_templateFile, mgmt_file, mgmt_token_values)

      Chef::Log.info( 'Finished modifying db_init_config_file' )

    end

  end
end

action :clean do
  # clear cfg files with sensitive data (such as super user password)

  file "#{::File.join(db_init_dir, 'mgmt/mgmt.cfg')}" do
    action    :delete
  end

end