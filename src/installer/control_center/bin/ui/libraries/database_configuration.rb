#
# library:: database_configuration
#     library for check the Database connectivity and
#     authentication
#
# Copyright 2015, Nextlabs Inc.
#
# All rights reserved - Do Not Redistribute
#

require "timeout"

module Utility
  module DB

    # check the database connection
    #
    # - sqlserver://localhost:1433;DatabaseName=<db name>;
    # - oracle:thin:@localhost:1521:orcl
    # - postgresql://localhost:5432/cc76
    def self.connect_to_DB(connection_string, username, password, ssl_certificate, server_dn, jre_x_path, classpath, tries=1, seconds=15)

      retries ||= tries

      Timeout::timeout(seconds) do
        # shellout doesn't play well with array command, so use string
        command = %Q[
          "#{jre_x_path}"
          -cp "#{classpath}"
          com.nextlabs.installer.controlcenter.validatedb.DBConnectionTesterV3
          "#{connection_string}"
          "#{username}"
          "#{password}"
          "#{ssl_certificate}"
          "#{server_dn}"
        ].gsub("\n", ' ')

        # puts('[DB] execute connect DB command: ' + command)
        pipe = IO.popen(command, :err=>[:child, :out])

        Process.wait(pipe.pid)

        output = pipe.readline.strip
        if $?.exitstatus != 0 || output != 'true'
          if output.end_with? ':'
            cause = pipe.readlines[0].strip
            output = output + ' ' + cause
          end
          raise "Failed to connect to DB: #{output}"
        else
          return true
        end
      end
    rescue Exception => ex
      if (retries -= 1) > 0
        puts("Retry DB connect")
        retry
      else
        raise ex
      end
    end

    # method that would be invoked by the GUI
    def self.test_db_connection(connectionString, username, password, ssl_certificate, server_dn, seconds=15)
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
      connect_to_DB(connectionString, username, password, ssl_certificate, server_dn, jre_x_path, classpath, tries=1, seconds=seconds)
    end

    private_class_method(:connect_to_DB)

  end
end
