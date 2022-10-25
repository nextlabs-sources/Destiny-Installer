#
# Cookbook Name:: ControlCenter
# Resource:: config_store_linux
#
# Copyright 2016, Nextlabs Inc.
# Author:: Duan Shiqiang
#
# All rights reserved - Do Not Redistribute
#
property :config_store_path, String, required: true
property :encrypted_key_store_password, String
property :encrypted_trust_store_password, String

action :create do
  template 'config_store_file' do
    source      'config_store_linux.erb'
    path        config_store_path
    variables({
        :encrypted_key_store_password => encrypted_key_store_password,
        :encrypted_trust_store_password => encrypted_trust_store_password
    })
    action      :create
  end
end

action :delete do
  file 'delete_config_store_file' do
    path        config_store_path
    action      :delete
  end
end