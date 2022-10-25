# encoding: utf-8
#
#@author::     Duan Shiqiang
#@copyright::  Nextlabs Inc.
#
require_relative './bootstrap'
require_relative './utility'
include Utility

INSTALL_WIZARD_ARRAY_COMPLETE_OPN = %w[
  /
  /agreement
  /install_dir
  /setup_type
  /license
  /administrator_passwd
  /certs
  /key_store
  /service_port
  /db
  /data_transportation
  /mail_server
  /ready_to_install
  /install
  /finish
]

INSTALL_WIZARD_ARRAY_ICENET = %w[
  /
  /agreement
  /install_dir
  /setup_type
  /server_location
  /service_port
  /ready_to_install
  /install
  /finish
]

INSTALL_WIZARD_ARRAY_MANAGEMENT_SERVER_OPN = INSTALL_WIZARD_ARRAY_COMPLETE_OPN

REMOVE_WIZARD_ARRAY = %w[
  /
  /agreement
  /installation_mode
  /ready_to_install
  /install
  /finish
]

UPGRADE_PRE87_WIZARD_ARRAY = %w[
  /
  /agreement
  /installation_mode
  /data_transportation
  /ready_to_install
  /install
  /finish
]

UPGRADE_POST87_WIZARD_ARRAY = %w[
  /
  /agreement
  /installation_mode
  /ready_to_install
  /install
  /finish
]

# let's check existing server details
if Server::Config.has_any_server_installed?($node)
  existing_server_version = Server::Config.get_current_server_version($node)

  if Server::Config.server_version_newer?($node['version_number'], existing_server_version)
    # we can't handle the installation
    raise "Existing server version: #{existing_server_version} is not supported by this installer to perform upgrade or uninstall"
  else
    $node['wizard_array_type'] = 'REMOVE_OR_UPGRADE'
    $node['console_install_mode'] = Server::Config.get_installed_console_mode($node)
  end

else
  $node['wizard_array_type'] = 'INSTALL'
end

class Installation < Shoes
  
  def __default_wizard(current_location, direction, wizard_array)

    current_idx = wizard_array.find_index(current_location)
    case direction
    when :next
      return wizard_array.fetch(current_idx+1)
    when :back
      return wizard_array.fetch(current_idx-1)
    else
      return current_location
    end

  end

  # this method determines whether the installation is only for icenet and keymanagement
  def __is_icenet_install_type?
    $item.installation_type == 'custom' &&
        $item.dabs_component == 'ON' &&
        $item.dac_component == 'OFF' &&
        $item.dps_component == 'OFF' &&
        $item.dem_component == 'OFF' &&
        $item.admin_component == 'OFF' &&
        $item.reporter_component == 'OFF'
  end

  def __is_management_server_install_type?
    $item.installation_type == 'custom' &&
        $item.dac_component == 'ON' &&
        $item.dps_component == 'ON' &&
        $item.dem_component == 'ON' &&
        $item.admin_component == 'ON' &&
        $item.reporter_component == 'ON'
  end

  def wizard(direction)

    current_location = location()

    if $node['wizard_array_type'] == 'REMOVE_OR_UPGRADE'
      if $item.installation_mode == 'upgrade'
        if Server::Config.get_current_server_version($node).to_f() < 8.7 
          wizard_array = UPGRADE_PRE87_WIZARD_ARRAY
        else
          wizard_array = UPGRADE_POST87_WIZARD_ARRAY
        end
      else
        wizard_array = REMOVE_WIZARD_ARRAY
      end
    else
      # then we are fresh install
      if $item.installation_type == 'complete'
        wizard_array = INSTALL_WIZARD_ARRAY_COMPLETE_OPN
      elsif __is_icenet_install_type?
        wizard_array = INSTALL_WIZARD_ARRAY_ICENET
      elsif __is_management_server_install_type?
        wizard_array = INSTALL_WIZARD_ARRAY_MANAGEMENT_SERVER_OPN
      else
        msg = 'Not supported installation type.'
        alert_ontop_parent(app.win, msg, :title => app.instance_variable_get('@title'))
        return current_location
      end
    end

    __default_wizard(current_location, direction, wizard_array)
  end

end
