#! /usr/bin/env ruby
# encoding: utf-8
#
#@author::     Duan Shiqiang
#@copyright::  Nextlabs Inc.
#
require_relative "./bootstrap"
require_relative "./utility"
include Utility

class Installation < Shoes
  
  WIZARD_ARRAY = [
    '/',
    '/agreement',
    '/step1',
    '/step2',
    # '/ready_to_install',
    '/install',
    '/finish'
  ]
  
  def __defalt_wizard current_location, direction

    current_idx = WIZARD_ARRAY.find_index(current_location)
    case direction
    when :next
      return WIZARD_ARRAY.fetch(current_idx+1)
    when :back
      return WIZARD_ARRAY.fetch(current_idx-1)
    else
      return current_location
    end

  end

  def wizard direction

    current_location = location()
    return __defalt_wizard current_location, direction

  end

end