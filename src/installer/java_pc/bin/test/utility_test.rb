#! /usr/bin/env ruby
# encoding: utf-8
# Java Policy Controller Installer GUI Utility Test
#
#@author::     Duan Shiqiang
#@copyright::  Nextlabs Inc.
#
require_relative "../utility.rb"
include Utility
require "test/unit"

class TestUtility < Test::Unit::TestCase


  def test01_validate_ip
    valid, error_msg = Validator.validate_ip "10.0.0.1"
    assert_equal(valid, true)
    assert_equal(error_msg, "")
    valid, error_msg = Validator.validate_ip "10.0.1.888"
    assert_equal(valid, false)
  end

  def test02_validate_hostname
    valid, error_msg = Validator.validate_hostname "nextlabs.com"
    assert_equal(valid, true)
    assert_equal(error_msg, "")
    valid, error_msg = Validator.validate_hostname "nextlabs.com+"
    assert_equal(valid, false)
  end

  def test03_validate_port
    valid, error_msg = Validator.validate_port "8080"
    assert_equal(valid, true)
    assert_equal(error_msg, "")
    valid, error_msg = Validator.validate_port "99999"
    assert_equal(valid, false)
    valid, error_msg = Validator.validate_port "port"
    assert_equal(valid, false)
  end

  def test04_validate_dir
    valid, error_msg = Validator.validate_dir "C:/Program Files"
    assert_equal(valid, true)
    assert_equal(error_msg, "")
    valid, error_msg = Validator.validate_dir "W:/Program Files"
    assert_equal(valid, false)
  end

  def test05_validate_non_empty
    valid, error_msg = Validator.validate_non_empty "not empty"
    assert_equal(valid, true)
    assert_equal(error_msg, "")

    valid, error_msg = Validator.validate_non_empty nil
    assert_equal(valid, false)

    valid, error_msg = Validator.validate_non_empty ""
    assert_equal(valid, false)
  end

  def test06_get_drive_names
    if RUBY_PLATFORM =~ /mingw/ then
      assert_equal(Utility.get_drive_names("C:/Program Files"), "C:")
    end
  end

end