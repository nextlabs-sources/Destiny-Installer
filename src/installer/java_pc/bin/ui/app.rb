#! /usr/bin/env ruby
# encoding: utf-8
#
# Policy Controller Installer GUI
#
#@author::     Duan Shiqiang
#@copyright::  Nextlabs Inc.
#
require "green_shoes"
require "gtk2"

require_relative "./bootstrap"
require_relative "./utility"
include Utility
require_relative "./wizard.rb"

Dir[File.expand_path(File.dirname(__FILE__)) + '/pages/*.rb'].each {|file|
  require file
}

Shoes.app :title => ReadableNames["title"] , :width => 950, :height => 700 do
  win.set_size_request(950, 700)
  win.set_resizable(false)
  win.set_window_position(Gtk::Window::POS_CENTER_ALWAYS)
  visit('/')
end
