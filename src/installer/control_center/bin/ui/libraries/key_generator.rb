#
# library:: key generator
#     library to generate random shared key for encryption or signature
#
# Copyright 2018, Nextlabs Inc.
#
# All rights reserved - Do Not Redistribute
#

require "timeout"
require "mixlib/shellout"

module Utility
  module KeyGen

    def self.generate_shared_key(algorithm, keySize, jre_x_path, classpath, seconds=15)

      Timeout::timeout(seconds) do

        command = %Q[
          "#{jre_x_path}"
          -cp "#{classpath}"
          com.nextlabs.installer.controlcenter.generator.KeyGenerator
          #{algorithm}
          #{keySize}
        ].gsub("\n", ' ')

        #puts "#{command}"

        pipe = IO.popen(command, :err=>[:child, :out])
        Process.wait(pipe.pid)
        output = pipe.readline.strip

        if $?.exitstatus != 0
          if output.end_with? ':'
            cause = pipe.readlines[0].strip
            output = output + ' ' + cause
          end

          puts "#{output}"
          raise "Failed to generate key: #{output}"
        else
          return output
        end

      end

    rescue => ex
      puts "Unable to generate shared key"
      raise ex

    end

    # method that would be invoked by the GUI
    def self.generate_key(algorithm, keySize, seconds=15)
      # The java executable path
      java_executable = case RUBY_PLATFORM
                          when /mswin|mingw|windows/
                            'java.exe'
                          when /linux/
                            'java'
                        end
      jre_x_path = File.join(Utility::START_DIR, 'dist', 'Policy_Server', 'java', 'jre', 'bin', java_executable)
      classpath_separator = case RUBY_PLATFORM
                              when /mswin|mingw|windows/
                                ';'
                              when /linux/
                                ':'
                            end
      # the path contains required jars used for db validation
      support_dir = File.join(Utility::START_DIR, 'dist', 'support')
      classpath = Dir[support_dir + '/*.jar'].join(classpath_separator)
      generate_shared_key(algorithm, keySize, jre_x_path, classpath, seconds=seconds)
    end

    private_class_method(:generate_shared_key)

  end

end