
default['required_disk_space_mb'] = 2048
default['super_user_name'] = 'Administrator'
default['install_windows_service'] = true
default['install_as_master'] = true
default['installation_mode'] = 'install'
# Legacy Mode (Deprecated from 8.7 onwards): OPL (when choosing legacy mode, you should change installation_type to "custom" and off the "cc_console_component")
# Console Mode (Web-based Policy Studio): OPN
# SAAS Mode: SAAS
default['console_install_mode'] = 'OPN'
default['installation_type'] = 'complete'
# Management Server
default['dms_component'] = 'ON'
# Intelligence Server
default['dac_component'] = 'ON'
# Policy Management Server
default['dps_component'] = 'ON'
# Enrollment Manager
default['dem_component'] = 'ON'
# Administrator
default['admin_component'] = 'ON'
# Reporter
default['reporter_component'] = 'ON'
# ICENet Server
default['dabs_component'] = 'ON'
# Key Management Server
default['dkms_component'] = 'ON'
# Control Center Console
default['cc_console_component'] = 'OFF'

default['web_shutdown_port'] = '8005'
default['dist_folder_name'] = 'dist'
default['dist_server_folder_name'] = 'Policy_Server'
default['dist_support_folder_name'] = 'support'
default['install_server_folder_name'] = 'PolicyServer'
default['elasticsearch_service_name'] = 'ControlCenterES'
default['elasticsearch_cluster_name'] = 'cc-data-cluster'
default['elasticsearch_port'] = '9300'


# this is the folder name created under temp_dir for storing temporary files during installation
default['temp_basename'] = 'cc_install'
# this is the folder name created under temp_dir for storing server backup
default['temp_backup_folder_name'] = 'server_bkup'
# this is the folder name created under the installer_dir for storing installer log
default['temp_log_dir'] = 'install_log'

default['winx']['service_name'] = 'CompliantEnterpriseServer'
default['winx']['display_name'] = 'Control Center Policy Server'
default['winx']['description'] = 'Control Center Policy Server'
# this is the folder name created under 'localappdata' folder for storing uninstallation scripts
default['appdata_folder_name'] = 'PolicyServer'
default['winx']['elasticsearch_display_name'] = 'Control Center Data Index Engine'

default['server']['jvmms'] = '1024'
default['server']['jvmmx'] = '2048'
default['server']['jvm_max_perm'] = '512M'

# Control Center Registry Key name (under HKEY_LOCAL_MACHINE)
default['REGISTY_KEY_NAME'] = %q[SOFTWARE\Wow6432Node\NextLabs,Inc.\ControlCenter]

# Control Center config store registry key name (under HKEY_LOCAL_MACHINE)
default['REGISTRY_CONFIG_STORE_KEY_NAME'] = %q[SOFTWARE\Wow6432Node\NextLabs\Compliant Enterprise\Control Center\Remembered Properties]

default['linux']['config_store_file_name'] = 'RememberedProperties'
default['linux']['service_name'] = 'CompliantEnterpriseServer'
default['linux']['description'] = 'Control Center Policy Server'
default['linux']['pid_file'] = 'CompliantEnterpriseServer-daemon.pid'
default['linux']['user'] = 'nextlabs'
default['linux']['group'] = 'nextlabs'
default['linux']['home'] = '/usr/share/nextlabs'

default['skip_smtp_check'] = false

# the components war map hash is used to identify existing server's installed components
# it doesn't contain all the war files, it only contain necessary fields to differentiate between
# complete installation, icenet installation and management server installation
# it's used for upgrade scenario
default['components_war_map']['dms'] = 'dms.war' # Management Server
default['components_war_map']['dabs'] = 'dabs.war' # ICENet Server
default['components_war_map']['dkms'] = 'dkms.war' # Key management Server
default['components_war_map']['cc_console'] = 'control-center-console.war' # Control Center Console
default['components_war_map']['config_service'] = 'config-service.war' # Config Service

# version_number and built_date will be set by bootstrap recipe
# will be override by the value in version file (file name is specified by attribute 'version_file_name') under START_DIR
default['version_number'] = ''
# the built_date will be override by the value in version file too
default['built_date'] = ''

default['version_file_name'] = 'version.txt'

# default smtp ssl setting
default['mail_server_ssl'] = false

