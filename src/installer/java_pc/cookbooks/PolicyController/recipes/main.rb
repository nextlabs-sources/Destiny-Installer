#
# Cookbook Name:: PolicyController
# Recipe:: main
#
# Copyright 2015, Nextlabs Inc.
# Author:: Amila Silva
#
# All rights reserved - Do Not Redistribute
#

require 'socket'
require 'timeout'

include_recipe 'PolicyController::preCheck'

if $preCheckSuccess
  include_recipe 'PolicyController::install'
else
  puts 'Unable to Proceed with current installation'
end
