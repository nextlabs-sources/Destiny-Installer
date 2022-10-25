#
# Cookbook Name:: ControlCenter
# library:: active_direcotry_auth
#     library for check the Active Directory connectivity and
#     authentication
#
# Copyright 2015, Nextlabs Inc.
# Author:: Amila Silva & Duan Shiqiang
#
# All rights reserved - Do Not Redistribute
#

require "timeout"
require "mixlib/shellout"

module Utility
  module DB

    # Logical Database names
    ACTIVITY_DB = 'activity'
    MANAGEMENT_DB = 'management'
    DICTIONARY_DB = 'dictionary'
    PF_DB = 'pf'
    KM_DB = 'keymanagement'

    # Various database constants
    ORACLE_DIALECT = 'net.sf.hibernate.dialect.Oracle9Dialect'
    ORACLE_DIALECT_CC_CONSOLE = 'org.hibernate.dialect.Oracle10gDialect'
    ORACLE_DRIVER = 'oracle.jdbc.driver.OracleDriver'

    SQL_SERVER_DIALECT = 'com.bluejungle.framework.datastore.hibernate.dialect.SqlServer2000Dialect'
    SQL_SERVER_DIALECT_CC_CONSOLE = 'com.nextlabs.destiny.console.hibernate.dialect.SqlServerDialectEx'
    SQL_SERVER_DIALECT_CAS = 'org.hibernate.dialect.SQLServerDialect'
    SQL_SERVER_DRIVER = 'com.microsoft.sqlserver.jdbc.SQLServerDriver'

    POSTGRES_DIALECT = 'net.sf.hibernate.dialect.PostgreSQLDialect'
    POSTGRES_DIALECT_CC_CONSOLE = 'com.nextlabs.destiny.console.hibernate.dialect.PostgreSQL9DialectEx'
    POSTGRES_DIALECT_CAS = 'org.hibernate.dialect.PostgreSQL9Dialect'
    POSTGRES_DRIVER = 'org.postgresql.Driver'

    DEFAULT_ORACLE_PORT = 1521
    DEFAULT_SQL_SERVER_PORT = 1433
    DEFAULT_POSTGRES_PORT = 5432

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
        Chef::Log.info("Retry DB connect")
        retry
      else
        raise ex
      end
    end


    # //////////////////////////////////////////////////////////
    # Returns the database connect string for the specified database
    # //////////////////////////////////////////////////////////
    def self.db_connection_url( db_type, connection_string )
      if db_type === 'POSTGRES'
        connectionUrl = "jdbc:" + connection_string;
      elsif db_type === 'MSSQL'
        connectionUrl = "jdbc:" + connection_string;
      elsif db_type === 'ORACLE'
        connectionUrl = "jdbc:" + connection_string;
      end

      return connectionUrl
    end


    # //////////////////////////////////////////////////////////
    # Returns the database dialect
    # //////////////////////////////////////////////////////////
    def self.get_db_dialect( db_type )
      if db_type === 'POSTGRES'
        return POSTGRES_DIALECT
      elsif db_type === 'MSSQL'
        return SQL_SERVER_DIALECT
      elsif db_type === 'ORACLE'
        return ORACLE_DIALECT
      end
    end

    # Get the DB dialect for cc-console app based on db_type
    def self.get_cc_console_db_dialect(db_type)
      if db_type === 'POSTGRES'
        return POSTGRES_DIALECT_CC_CONSOLE
      elsif db_type === 'MSSQL'
        return SQL_SERVER_DIALECT_CC_CONSOLE
      elsif db_type === 'ORACLE'
        return ORACLE_DIALECT_CC_CONSOLE
      end
    end

    def self.get_cas_db_dialect(db_type)
      if db_type === 'POSTGRES'
        return POSTGRES_DIALECT_CAS
      elsif db_type === 'MSSQL'
        return SQL_SERVER_DIALECT_CAS
      elsif db_type === 'ORACLE'
        return ORACLE_DIALECT_CC_CONSOLE
      end
    end

    # //////////////////////////////////////////////////////////
    # Returns the database driver
    # //////////////////////////////////////////////////////////
    def self.get_db_driver( db_type )
      if db_type === 'POSTGRES'
        return POSTGRES_DRIVER
      elsif db_type === 'MSSQL'
        return SQL_SERVER_DRIVER
      elsif db_type === 'ORACLE'
        return ORACLE_DRIVER
      end
    end

    # method that would be invoked by recipe for testing connection
    def self.test_db_connection(connection_string, username, password, ssl_certificate, server_dn, jre_x_path, classpath, tries=1, seconds=15)
      connect_to_DB(connection_string, username, password, ssl_certificate, server_dn, jre_x_path, classpath, tries, seconds)
    end

    # ///////////////////////////////////////////////////////////
    # Database Initialization
    #  - create tables
    #  - populate initial data
    #
    #  Action : install, upgrade, createschema, dropcreateschema, updateschema, sqlfile,
    #
    # ////////////////////////////////////////////////////////////
    def self.db_init(node, action, config_file_name, library_path, tries=1)

      # only set reties when it's not set already
      retries ||= tries

      logConfigFile = File.join(node['log_dir'], 'dbinit_logging.properties')
      dbInitJarFile = "#{node['installation_dir']}/tools/dbInit/db-init.jar"
      installDir = node['installation_dir']
      truststore_file = File.join(node['installation_dir'], 'server/certificates/web-truststore.jks')

      if action == 'upgrade'
        upgradeArgs = "-fromV #{Server::Config.get_current_server_version(node)} -toV #{node['version_number']}"
      else
        upgradeArgs = '';
      end
      
      db_init_args = %Q[-Ddb.url="#{Utility::DB.db_connection_url(node['database_type'].to_s.strip, node['db_connection_url'].to_s.strip)}" -Ddb.username="#{node['db_username'].to_s.strip()}" -Ddb.password="#{node['db_password'].to_s.strip}" -Ddb.driver="#{Utility::DB.get_db_driver(node['database_type'].to_s.strip)}" -Ddb.dialect="#{Utility::DB.get_db_dialect(node['database_type'].to_s.strip)}" -Djavax.net.ssl.trustStore="#{truststore_file}" -Djavax.net.ssl.trustStorePassword="#{node['trust_store_password'].to_s.strip()}"]
      
      command = %Q["#{node['instance_jre_x_path']}" -noverify #{db_init_args} -Djava.util.logging.config.file="#{logConfigFile}" -jar "#{dbInitJarFile}" -#{action} #{upgradeArgs} -config "#{config_file_name}" -connection "#{installDir}" -libraryPath "#{library_path}" -quiet]

      Chef::Log.debug('[DB] Execute DB command:' + command)
      # the db init jar will write all log to stderr, so we need to let popen capture stderr to stdout
      IO.popen(command, :err=>[:child, :out]) { |io|
        io.each do |line|
          Chef::Log.debug(line)
        end
      }

      if $?.exitstatus != 0
        Chef::Log.info('[DB] DB command Failed')
        # raise exception if error ( the output can be lengthy, so only show first line)
        raise 'DB command Failed'
      else
        Chef::Log.info('[DB] Finished DB command')
      end
    rescue Exception => ex
      if (retries -= 1) > 0
        Chef::Log.info('[DB] Retry DB command: ' + command)
        # sleep 3 seconds and retry
        sleep 3
        retry
      else
        raise ex
      end
    end

    def self.handle_db_Init(node, action, tries=1)

      ['dictionary_db_init', 'management_db_init', 'pf_db_Init', 'activty_db_init'].each { |x|
        method(x).call(node, action, tries)
      }

    end

    # -Djava.util.logging.config.file="C:\Users\ADMINI~1.TDO\AppData\Local\Temp\2\{52922d44-b510-445e-9e3c-062496e425db}\dbinit_logging.properties"
    # -jar "C:\Program Files\NextLabs\Policy Server\tools\dbInit\db-init.jar" 
    # -upgrade -fromV 7.5.0.0 -toV 7.6.0.764
    # -config "C:\Program Files\NextLabs\Policy Server\tools\dbInit\activity\activity.cfg" 
    # -connection "C:\Program Files\NextLabs\Policy Server" 
    # -libraryPath "C:\Program Files\NextLabs\Policy Server\tools\dbInit\activity" -quiet

    # ///////////////////////////////////////////////////////////
    # Activity Database Initialization 
    #  
    #  Action : install, upgrade, createschema, dropcreateschema, updateschema, sqlfile,
    # ////////////////////////////////////////////////////////////
    def self.activty_db_init(node, action, tries=1)

      configFile = "#{node['installation_dir']}/tools/dbInit/activity/activity.cfg"
      libraryPath = "#{node['installation_dir']}/tools/dbInit/activity"

      Chef::Log.info("[DB] Start Activity Repository Initialization")

      db_init(node, action, configFile, libraryPath, tries)

      Chef::Log.info("[DB] Finished Activity Repository Initialization")

    end

    # ///////////////////////////////////////////////////////////
    # Dictionary Database Initialization 
    #  
    #  Action : install, upgrade, createschema, dropcreateschema, updateschema, sqlfile,
    # ////////////////////////////////////////////////////////////
    def self.dictionary_db_init(node, action, tries=1)

      configFile = "#{node['installation_dir']}/tools/dbInit/dictionary/dictionary.cfg"
      libraryPath = "#{node['installation_dir']}/tools/dbInit/dictionary"

      Chef::Log.info("[DB] Start Dictionary Repository Initialization")

      db_init(node, action, configFile, libraryPath, tries)

      Chef::Log.info("[DB] Finished Dictionary Repository Initialization")

    end

    # ///////////////////////////////////////////////////////////
    # Management Database Initialization 
    #  
    #  Action : install, upgrade, createschema, dropcreateschema, updateschema, sqlfile,
    # ////////////////////////////////////////////////////////////
    def self.management_db_init(node, action, tries=1)

      configFile = "#{node['installation_dir']}/tools/dbInit/mgmt/mgmt.cfg"
      libraryPath = "#{node['installation_dir']}/tools/dbInit/mgmt"

      Chef::Log.info("[DB] Start Management Repository Initialization")

      db_init(node, action, configFile, libraryPath, tries)

      Chef::Log.info("[DB] Finished Management Repository Initialization")

    end


    # ///////////////////////////////////////////////////////////
    # PF Database Initialization 
    #  
    #  Action : install, upgrade, createschema, dropcreateschema, updateschema, sqlfile,
    # ////////////////////////////////////////////////////////////
    def self.pf_db_Init(node, action, tries=1)

      configFile = "#{node['installation_dir']}/tools/dbInit/pf/pf.cfg"
      libraryPath = "#{node['installation_dir']}/tools/dbInit/pf"

      Chef::Log.info("[DB] Start PF Repository Initialization")

      db_init(node, action, configFile, libraryPath, tries)

      Chef::Log.info("[DB] Finished PF Repository Initialization")

    end

    private_class_method(:activty_db_init, :dictionary_db_init, :management_db_init, :pf_db_Init,
                         :db_init, :connect_to_DB)

  end unless defined?(Utility::DB) # https://github.com/sethvargo/chefspec/issues/562#issuecomment-74120922
end
