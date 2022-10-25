#
# Cookbook Name:: PolicyController
# Recipe:: install_jboss_linux
#     This handle the linux JBoss installer
#
# Copyright 2015, Nextlabs Inc.
# Author:: Amila Silva
#
# All rights reserved - Do Not Redistribute
#

require 'fileutils'

puts "[Install]: Linux Installation will start....."

$tempLocaton = node['temp_dir'] + '/jpc/jbosspc'

puts "[Install]: Start coping files to #{$tempLocaton}"
srcDir = '${START_DIR}/dist/jbosspc'
destDir = $tempLocaton

bash 'copyJPCFilesToTemp' do
   code <<-EOH
     mkdir -p #{destDir}
     cp -rf  #{srcDir}/* #{destDir}
   EOH
end
puts "[Install]: Files copied to #{$tempLocaton} successfully"

puts "[Install]: Start coping files from #{$tempLocaton}"
srcDir = $tempLocaton + "/deployments/dpc.war"

if (node['jboss_installation_type'] == 'standalone')
  destDir = node['installation_dir'] + "/standalone/deployments"
else
  destDir = node['installation_dir'] + "/domain/deployments"
end


bash 'copyWarFiles' do
   code <<-EOH
     cp -rf  #{srcDir} #{destDir}
   EOH
   action :nothing
end

# Copy files from temp directory to install dir
ruby_block "copyJPCFiles" do
  block do
  end
  notifies :run, 'bash[copyWarFiles]', :immediately
end


puts "[Install]: dpc.war filed copied successfully"

srcDir = $tempLocaton
destDir = node['dpc_path']

bash 'copyDPCFiles' do
  code <<-EOH
    mkdir -p  \"#{destDir}\"
    cp -rf  #{srcDir}/dpc/* \"#{destDir}\"
  EOH
end
puts "[Install]: DPC Files copied successfully"


# replace Placeholders using this recipe
include_recipe 'PolicyController::replacePlaceholders'

# Commprofile file copy
ruby_block "commprofile-xml" do
  block do
    if ::File.exists?($temp_commprofile_location)
      puts "[Install]: Commprofile Placeholders have been replaced successfully"

      commprofileFileLocation = node['dpc_path'] + '/config/commprofile.xml'

      FileUtils.cp $temp_commprofile_location,  commprofileFileLocation
      puts "[Install]: Commprofile file copied to 'dpc/config' folder"

    else
      puts "[Install]: Commprofile Placeholders failed"
    end
  end
end

# dpc.properties file copy
ruby_block "dpc-properties" do
  block do
    if ::File.exists?($temp_dpcProps_location)
      puts "[Install]: dpc.properties Placeholders have been replaced successfully"

      dpcFileLocation = node['dpc_path'] + '/dpc.properties'

      FileUtils.cp $temp_dpcProps_location,  dpcFileLocation
      puts "[Install]: dpc.properties file copied to 'dpc' folder"

    else
      puts "[Install]: dpc.properties Placeholders failed"
    end
  end
end

# JavaSDKService properties file copy
ruby_block "JavaSDKService-properties" do
  block do
    if ::File.exists?($temp_javaSDKProps_location)
      puts "[Install]: JavaSDKService.properties Placeholders have been replaced successfully"

      fileLocation = node['dpc_path'] + '/jservice/config/JavaSDKService.properties'

      FileUtils.cp $temp_javaSDKProps_location,  fileLocation
      $installationSuccess = true
      puts "[Install]: JavaSDKService.properties file copied to 'dpc/jservice/config' folder"
    else
      puts "[Install]: JavaSDKService.properties Placeholders failed"
    end
  end
end


