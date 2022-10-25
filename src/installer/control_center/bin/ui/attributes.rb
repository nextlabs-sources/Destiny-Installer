#! /usr/bin/env ruby
# encoding: utf-8
#
# since we are using chef under the hood to do installation
# we can use a similar attribute file containing only what we need 
# for the UI to make things consistent
# 

$node = Hash.new()

$node['winx'] = Hash.new()
$node['winx']['service_name'] = 'CompliantEnterpriseServer'

$node['linux'] = Hash.new()
$node['linux']['service_name'] = 'CompliantEnterpriseServer'
$node['linux']['pid_file'] = '/var/run/CompliantEnterpriseServer-daemon.pid'
$node['version_file_name'] = 'version.txt'

# Set version_number, build_number and built_date attribute
# the values are coming from the version file under START_DIR
version_file = ::File.join(ENV['START_DIR'].gsub("\\", '/'), $node['version_file_name'])
raise("version file missing: #{version_file}") unless ::File.exist?(version_file)

::File.foreach(version_file) { |x|
  if version_match = x.match(/Policy Server version\s*:\s*(\d+(\.\d+)+)/i)
    # full version number should be like 8.0.0.999
    $node['version_number'] = version_match.captures[0].strip()
 	puts "Current installer artifact version: " + $node['version_number']
  end
}