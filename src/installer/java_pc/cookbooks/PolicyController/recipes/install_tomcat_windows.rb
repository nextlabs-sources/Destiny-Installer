#
# Cookbook Name:: PolicyController
# Recipe:: install_tomcat_windows
#     This handle the windows tomcat installer
#
# Copyright 2015, Nextlabs Inc.
# Author:: Amila Silva
#
# All rights reserved - Do Not Redistribute
#

require 'fileutils'

puts "[Install]: Windows Installation will start....."

$tempLocaton = node['temp_dir'] + '/jpc/tomcat'

puts "[Install]: Start coping files to #{$tempLocaton}"
srcDir = '%START_DIR%/dist/tomcat'
destDir = $tempLocaton

batch 'copyJPCFilesToTemp' do
  code <<-EOH
    mkdir #{destDir}
    xcopy "#{srcDir}" "#{destDir}" /e /y /i /v
  EOH
end
puts "[Install]: Files copied to #{$tempLocaton} successfully"

# Copy files from temp directory to install dir
puts "[Install]: Start coping files from #{$tempLocaton}"
srcDir =  $tempLocaton
destDir = node['installation_dir']

batch 'copyJPCFiles' do
  code <<-EOH
    mkdir #{destDir}
    xcopy "#{srcDir}" "#{destDir}" /e /y /i /v
  EOH
end
puts "[Install]: Files copied successfully"

# replace Placeholders using this recipe
include_recipe 'PolicyController::replacePlaceholders'

# Commprofile file copy
ruby_block "commprofile-xml" do
  block do
    if ::File.exists?($temp_commprofile_location)
      puts "[Install]: Commprofile Placeholders have been replaced successfully"

      commprofileFileLocation = node['installation_dir'] + '/dpc/config/commprofile.xml'

      FileUtils.cp $temp_commprofile_location,  commprofileFileLocation
      puts "[Install]: Commprofile file copied to 'dpc/config' folder"

    else
      puts "[Install]: Commprofile Placeholders failed"
    end
  end
end

# JavaSDKService properties file copy
ruby_block "JavaSDKService-properties" do
  block do
    if ::File.exists?($temp_javaSDKProps_location)
      puts "[Install]: JavaSDKService.properties Placeholders have been replaced successfully"

      fileLocation = node['installation_dir'] + '/dpc/jservice/config/JavaSDKService.properties'

      FileUtils.cp $temp_javaSDKProps_location,  fileLocation
      puts "[Install]: JavaSDKService.properties file copied to 'dpc/jservice/config' folder"
    else
      puts "[Install]: JavaSDKService.properties Placeholders failed"
    end
  end
end

ruby_block "catalina-props" do
  block do
    new_file_name = ENV['CATALINA_HOME'] + "/conf/catalina.properties_new"
    old_file_name = ENV['CATALINA_HOME'] + "/conf/catalina.properties_bk"
    file_name = ENV['CATALINA_HOME'] + "/conf/catalina.properties"

    readFile = File.open(file_name, "r")
    newFile = File.open(new_file_name, 'w')

    readFile.each_line { |line|
      new_line = line.strip
      if (new_line.start_with?('common.loader') && !(new_line.include? '${catalina.home}/nextlabs/server_lib/*.jar'))
        # if the common.loader is empty value, no need to add commma after inserting the entry
        if /^common.loader\s*=\s*./.match(new_line)
          new_line = new_line.sub(/common.loader\s*=\s*/, 'common.loader="${catalina.home}/nextlabs/server_lib/*.jar",')
        else
          new_line = new_line.sub(/common.loader\s*=\s*/, 'common.loader="${catalina.home}/nextlabs/server_lib/*.jar"')
        end
      end
      if (new_line.start_with?('shared.loader') && !(new_line.include? '${catalina.home}/nextlabs/shared_lib/*.jar'))
        if /^shared.loader\s*=\s*./.match(new_line)
          new_line = new_line.sub(/shared.loader\s*=\s*/, 'shared.loader="${catalina.home}/nextlabs/shared_lib/*.jar",')
        else
          new_line = new_line.sub(/shared.loader\s*=\s*/, 'shared.loader="${catalina.home}/nextlabs/shared_lib/*.jar"')
        end
      end
      if (new_line.start_with?('tomcat.util.scan.StandardJarScanFilter.jarsToSkip=') && !(new_line.include? 'common-*.jar,server-*.jar,crypt.jar'))
        if /^tomcat.util.scan.StandardJarScanFilter.jarsToSkip\s*=\s*./.match(new_line)
          new_line = new_line.sub(/tomcat.util.scan.StandardJarScanFilter.jarsToSkip\s*=\s*/,
              'tomcat.util.scan.StandardJarScanFilter.jarsToSkip=common-*.jar,server-*.jar,crypt.jar,')
        else
          new_line = new_line.sub(/tomcat.util.scan.StandardJarScanFilter.jarsToSkip\s*=\s*/,
              'tomcat.util.scan.StandardJarScanFilter.jarsToSkip=common-*.jar,server-*.jar,crypt.jar')
        end
      end
      newFile.puts new_line
    }
    readFile.close
    newFile.close

    File.rename(file_name, old_file_name)
    File.rename(new_file_name, file_name)

    puts "[Install]: catalina properties file modified"
  end
end

ruby_block "server-xml-modifications" do
  block do
    old_file_name = ENV['CATALINA_HOME'] + "/conf/server.xml_bk"
    file_name = ENV['CATALINA_HOME'] + "/conf/server.xml"
    FileUtils.cp(file_name, old_file_name)

    file = File.new(file_name)
    doc = REXML::Document.new(file)

    if (doc.elements["//Server/Service[@name='CE-Core']"] == nil)
      snippet = File.new($temp_serverxml_location)
      jpcNode = REXML::Document.new(snippet)
      doc.root.insert_after( '//Service', jpcNode.root )
      doc.write(File.open(ENV['CATALINA_HOME'] + "/conf/server.xml", 'w'), 4)
    end

    file.close
    $installationSuccess = true
    puts "[Install]: server.xml file modified"
  end
end

# copy Tomcat server version properties file, this is a security fix for vulnerable server version in use
ruby_block 'create server info folder' do
  block do
    folder_path = File.join(ENV['CATALINA_HOME'], 'lib', 'org', 'apache', 'catalina', 'util')
    FileUtils.mkdir_p(folder_path)
  end
end

template "#{::File.join(ENV['CATALINA_HOME'], 'lib', 'org', 'apache', 'catalina', 'util', 'ServerInfo.properties')}" do
  source 'ServerInfo.properties'
  action :create
end
