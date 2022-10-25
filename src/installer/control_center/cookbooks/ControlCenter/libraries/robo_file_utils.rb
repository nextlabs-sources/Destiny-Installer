#
# Cookbook Name:: ControlCenter
# library:: robo_file_utils
#     library for doing remove folder, copy folder (using FileUtils has some bug on windows when copying or removing
#     files with too long path)
#
# Copyright 2016, Nextlabs Inc.
# Author:: Duan Shiqiang
#
# All rights reserved - Do Not Redistribute
#
module Utility
  module RoboFileUtils
    require 'fileutils'
    require 'tmpdir'
    include Chef::Mixin::ShellOut

    # the source should be a directory
    def robo_cp_r(source, dest)
      FileUtils.mkdir_p(dest) unless ::File.directory?(dest)
      begin
        FileUtils.cp_r(Dir.glob("#{source}/*"), dest)
      rescue Exception => ex
        if RUBY_PLATFORM =~ /mswin|mingw|windows/
          cmd = %Q[robocopy "#{source}" "#{dest}" /e  /NFL /NDL /NJH /NJS /nc /ns /np]
          shell_out!(cmd, :returns => [0, 1, 2, 3, 4, 5, 6, 7, 8])
        else
          raise(ex)
        end
      end
    end

    # the dir should be a directory
    def robo_rm_rf(dir)
      begin
        FileUtils.rm_rf(dir)
        if (RUBY_PLATFORM =~ /mswin|mingw|windows/) && ::File.exist?(dir)
          # use robocopy trick to remove the folder
          # see: http://superuser.com/questions/179660/how-to-recursively-delete-directory-from-command-line-in-windows#answer-459769
          temp_empty_folder = ::File.join(Dir.tmpdir, 'cc_temp_empty_folder')
          FileUtils.mkdir_p(temp_empty_folder)
          cmd = %Q[robocopy "#{temp_empty_folder}" "#{dir}" /e /purge  /NFL /NDL /NJH /NJS /nc /ns /np]
          shell_out!(cmd, :returns => [0, 1, 2, 3, 4, 5, 6, 7, 8])
          FileUtils.rm_rf(temp_empty_folder)
          FileUtils.rm_rf(dir)
        end
      end
    end

  end
end