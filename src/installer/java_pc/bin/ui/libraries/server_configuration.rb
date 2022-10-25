#
# library:: server_configuration
#     library for check server installation details
#
# Copyright 2016, Nextlabs Inc.
# Author:: Duan Shiqiang
#
# All rights reserved - Do Not Redistribute
#
module Server
  module Config
  
    # Returns true if new_version large then old_version
    # It will check the major version, minor version and maintenance version number and also the 4th number in order
    # for example, version 8.0.1's major version is 8, minor version is 0, maintenance version is 1
    # then, 8.0.1 will be treated newer than 8.0.0
    def self.server_version_newer?(old_version, new_version)
      old_version_components = old_version.to_s().split('.')
      new_version_components = new_version.to_s().split('.')
      # make sure the component array is at least length 3
      raise("version not valid: " + old_version.to_s()) if old_version_components.length < 1
      raise("version not valid: " + new_version.to_s()) if new_version_components.length < 1
      # change all string in the array to int
      old_version_components.map! {|x| x.to_i() }
      new_version_components.map! {|x| x.to_i() }
      while old_version_components.length < 4 do
        old_version_components.push(0)
      end
      while new_version_components.length < 4 do
        new_version_components.push(0)
      end

      for i in 0..3
        if old_version_components[i] < new_version_components[i]
          return true
        elsif old_version_components[i] > new_version_components[i]
          return false
        end
      end
      return false
    end

  end
end