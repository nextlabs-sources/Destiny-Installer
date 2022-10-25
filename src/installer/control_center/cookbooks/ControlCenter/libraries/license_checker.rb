#
# library:: license_checker
#     library to check if the license provided is valid or not
#
# Copyright 2015, Nextlabs Inc.
#
# All rights reserved - Do Not Redistribute
#

require "timeout"

module Utility
  module LicenseChecker
    # check the validity of the License file
    #
    # - Must be a valid data file with .dat extention
    # - Must have a valid expiry date
    def self.check_license(licenseJarFileLocation, licenseDataFileLocation, jre_x_path, classpath, tries=1, seconds=5)

      retries ||= tries

      Timeout::timeout(seconds) do
        command = %Q[
          "#{jre_x_path}"
          -cp "#{classpath}"
          -Dlicense.jar.file.loc="#{licenseJarFileLocation}"
          -Dlicense.data.file.loc="#{licenseDataFileLocation}"
          com.nextlabs.installer.controlcenter.validatelicense.LicenseChecker
        ].gsub("\n", ' ')

        puts command
        pipe = IO.popen(command, :err=>[:child, :out])

        Process.wait(pipe.pid)

        output = pipe.readline.strip
        if $?.exitstatus != 0 || output != 'true'
          if output.end_with? ':'
            cause = pipe.readlines[0].strip
            output = output + ' ' + cause
          end
          raise "Invalid License File: #{output}"
        else
          return true
        end
      end
    rescue Exception => ex
        raise ex
    end

    def self.validate_license(licenseDataFileLocation, classpath, licenseJarFile, jre_x_path)
      check_license(licenseJarFile, licenseDataFileLocation, jre_x_path, classpath, tries=1, seconds=seconds)
    end

    private_class_method(:check_license)

  end
end
