#! /usr/bin/env ruby
# encoding: utf-8
#
# Policy Server Installer GUI
#
#@author::     Duan Shiqiang
#@copyright::  Nextlabs Inc.
#
require 'green_shoes'
require 'gtk2'

require_relative './bootstrap'
require_relative './utility'
include Utility
require_relative './wizard'

Dir[File.expand_path(File.dirname(__FILE__)) + '/pages/*.rb'].each {|file|
  require file
}

Shoes.app :title => ReadableNames["title"] , :width => 950, :height => 700 do
  win.set_size_request(950, 700)
  win.set_resizable(false)
  win.set_window_position(Gtk::Window::POS_CENTER_ALWAYS)
  visit('/')
  # $node['wizard_array_type'] = 'REMOVE_OR_UPGRADE'
  # for development, override the method
  # module Server
  #   module Config
  #     def self.get_current_server_version(node)
  #       return $node['version_number']
  #     end
  #
  #     def self.get_current_installation_dir(node)
  #       return 'C:/Program Files/Nextlabs/PolicyServer'
  #     end
  #   end
  # end
end
