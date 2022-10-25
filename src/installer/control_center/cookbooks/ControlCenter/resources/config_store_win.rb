#
# Cookbook Name:: ControlCenter
# Resource:: config_store_win
#
# Copyright 2016, Nextlabs Inc.
# Author:: Duan Shiqiang
#
# All rights reserved - Do Not Redistribute
#
property :registry_key_name, String, required: true
property :encrypted_key_store_password, String
property :encrypted_trust_store_password, String

action :create do
  registry_key "#{registry_key_name}" do
    values [
      {:name => 'ENCRYPTED_KEY_STORE_PASSWORD', :type => :string, :data => encrypted_key_store_password},
      {:name => 'ENCRYPTED_TRUST_STORE_PASSWORD', :type => :string, :data => encrypted_trust_store_password}
    ]
    recursive true
    action :create
  end
end

action :delete do
  registry_key "#{registry_key_name}" do
    recursive true
    action :delete_key
  end
end
