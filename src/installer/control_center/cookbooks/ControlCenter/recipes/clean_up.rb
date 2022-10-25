#
# Cookbook Name:: ControlCenter
# Recipe:: Clean Up
#           - Clean up the resources 
#
# Copyright 2015, Nextlabs Inc.
# Author:: Amila Silva
#
# All rights reserved - Do Not Redistribute
#
require 'fileutils'
Chef::Resource::RubyBlock.send(:include, Utility::RoboFileUtils)

log ProgressLog::REMOVE_NONEED_FILES_STARTED

# Remove elasticsearch folder if not needed
directory "#{node['es_home']}" do
  recursive true
  action    :delete
  not_if    { Server::Config.elasticsearch_component?(node) }
end

# clean up
ruby_block 'clean_up' do

  block do
    require 'fileutils'
    if ::File.directory?(node['backup_dir'])
      robo_rm_rf(node['backup_dir'])
    end

    Chef::Log.info('[CleanUp]: Policy Server temporary resources cleaned successfully')
  end

end

# Remove unwanted files for distributed installer
ruby_block 'clean_up_unwanted_for_customized installation' do

  block do
    require 'fileutils'
    datasync_tool = ::File.join(node['installation_dir'], 'tools/datasync')
    seed_data_tool = ::File.join(node['installation_dir'], 'tools/Seed_Data')
    dbInit_tool = ::File.join(node['installation_dir'], 'tools/dbInit')
    enrollment_tool = ::File.join(node['installation_dir'], 'tools/enrollment')
    genappldif_tool = ::File.join(node['installation_dir'], 'tools/genappldif')
    importexport_tool = ::File.join(node['installation_dir'], 'tools/importexport')
    locationimporter_tool = ::File.join(node['installation_dir'], 'tools/locationimporter')
    keymanagement_tool = ::File.join(node['installation_dir'], 'tools/keymanagement')
    genappldif_bat_tool = ::File.join(node['installation_dir'], 'tools/genappldif.bat')
    importLocations_bat_tool = ::File.join(node['installation_dir'], 'tools/importLocations.bat')

    license_folder = ::File.join(node['installation_dir'], 'server/license')
    scripts_folder = ::File.join(node['installation_dir'], 'server/scripts')

    dms = ::File.join(node['installation_dir'], 'server/apps/dms.war')
    dac = ::File.join(node['installation_dir'], 'server/apps/dac.war')
    dem = ::File.join(node['installation_dir'], 'server/apps/dem.war')
    dps = ::File.join(node['installation_dir'], 'server/apps/dps.war')
    dabs = ::File.join(node['installation_dir'], 'server/apps/dabs.war')
    dkms = ::File.join(node['installation_dir'], 'server/apps/dkms.war')
    inquiryCenter = ::File.join(node['installation_dir'], 'server/apps/inquiryCenter.war')
    mgmtConsole = ::File.join(node['installation_dir'], 'server/apps/mgmtConsole.war')
    cc_console = ::File.join(node['installation_dir'], 'server/apps/control-center-console.war')
    cas = ::File.join(node['installation_dir'], 'server/apps/cas.war')
    config_service = ::File.join(node['installation_dir'], 'server/apps/config-service.war')

    configuration_xml = ::File.join(node['installation_dir'], 'server/configuration/configuration.xml')
    configurationDigester_xml = ::File.join(node['installation_dir'], 'server/configuration/configuration.digester.rules.xml')
    configurationxsd_xml = ::File.join(node['installation_dir'], 'server/configuration/Configuration.xsd')
    dashboardxml_xml = ::File.join(node['installation_dir'], 'server/configuration/dashboard.xml')

    if node['dms_component'].to_s.strip.eql?('OFF')
      [dms, datasync_tool, seed_data_tool, dbInit_tool, genappldif_tool, importexport_tool,
        locationimporter_tool, genappldif_bat_tool, importLocations_bat_tool,
        license_folder, scripts_folder, cas, configuration_xml, configurationDigester_xml,
        dashboardxml_xml, dps, cc_console, config_service].each { |x| FileUtils.rm_rf(x) }
    end
    if node['dac_component'].to_s.strip.eql?('OFF') then FileUtils.rm_rf(dac) end
    if node['dem_component'].to_s.strip.eql?('OFF')
      [dem, enrollment_tool].each { |x| FileUtils.rm_rf(x) }
    end
    if node['admin_component'].to_s.strip.eql?('OFF') then FileUtils.rm_rf(mgmtConsole) end
    if node['reporter_component'].to_s.strip.eql?('OFF') then FileUtils.rm_rf(inquiryCenter) end
    if node['dabs_component'].to_s.strip.eql?('OFF') then FileUtils.rm_rf(dabs) end
    if node['dkms_component'].to_s.strip.eql?('OFF')
      [dkms, keymanagement_tool].each { |x| FileUtils.rm_rf(x) }
    end
    Chef::Log.info('[CopyArtifacts] Removing unwanted files and directories from customized installation')
  end

  only_if { ( node['installation_mode'].to_s.strip.eql?('install') ||
      node['installation_mode'].to_s.strip.eql?('upgrade') ) &&
      node['installation_type'].to_s.strip.eql?('custom') }

end

log ProgressLog::REMOVE_NONEED_FILES_DONE
