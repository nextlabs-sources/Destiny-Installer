#
# Cookbook Name:: ControlCenter
# library:: certificate_generation
#     this will handle all system certificate generation
#
# Use key_store_password for key_pass as well
# 
# Copyright 2015, Nextlabs Inc.
# Author:: Amila Silva
#
# All rights reserved - Do Not Redistribute
#

require 'fileutils'
require 'chef/mixin/shell_out'
include Chef::Mixin::ShellOut

module Server
  module Certs

    DN = 'CN=CompliantEnterprise Server, OU=CompliantEnterprise, O=NextLabs, L=San Mateo, ST=CA, C=US'
    WEB_DN_TEMPLATE = 'CN=%s, OU=CompliantEnterprise, O=NextLabs, L=San Mateo, ST=CA, C=US'
    KEY_ALGO = 'RSA'
    KEY_SIZE = 2048
    SIGNATURE_ALGO = 'SHA256withRSA'
    LEGACY_KEY_ALGO = 'DSA'
    LEGACY_KEY_SIZE = 1024
    LEGACY_SIGNATURE_ALGO = 'SHA1withDSA'
    CERT_VALIDITY = 3650

    # ////////////////////////////////////////////////////////////
    # Main function to creates the set of certificates required by
    # the server
    # ///////////////////////////////////////////////////////////
    def self.create_all_certificates(node, key_store_path, key_store_password, trust_store_password)
      create_DCC_certificate(node, key_store_path, key_store_password, trust_store_password)
      create_legacy_DCC_certificate(node, key_store_path, key_store_password, trust_store_password)
      create_agent_certificate(node, key_store_path, key_store_password, trust_store_password)
      create_legacy_agent_certificate(node, key_store_path, key_store_password, trust_store_password)
      create_application_certificate(node, key_store_path, key_store_password, trust_store_password)
      create_web_certificate(node, key_store_path, key_store_password, trust_store_password)
      create_digital_signature_certificate(node, key_store_path, key_store_password, trust_store_password)
      create_truststores(node, key_store_path, key_store_password, trust_store_password)
      
      import_db_ssl_certificate(node, key_store_path, trust_store_password)
      
      #import_web_certificate_to_cacerts(node, 'Web')
      #import_database_certificate_to_cacerts(node, 'Database')
    end

    # Creates the Agent Certificate and keystore/truststore
    def self.create_agent_certificate(node, key_store_path, key_store_password, trust_store_password)
      generate_key_pair(node, 'Agent', DN, key_store_path, 'agent-keystore.jks', key_store_password, KEY_ALGO, KEY_SIZE, SIGNATURE_ALGO, key_store_password, CERT_VALIDITY);
      export_certificate(node, 'Agent', key_store_path, 'agent-keystore.jks', 'agent.cer', key_store_password)
      import_cert_into_truststore(node, 'Agent', key_store_path, 'agent.cer', 'agent-truststore.jks', trust_store_password)
    end

    # Creates the legacy Agent Certificate and legacy truststores
    def self.create_legacy_agent_certificate(node, key_store_path, key_store_password, trust_store_password)
      generate_key_pair(node, 'Agent', DN, key_store_path, 'legacy-agent-keystore.jks', key_store_password, LEGACY_KEY_ALGO, LEGACY_KEY_SIZE, LEGACY_SIGNATURE_ALGO, key_store_password, CERT_VALIDITY);
      export_certificate(node, 'Agent', key_store_path, 'legacy-agent-keystore.jks', 'legacy-agent.cer', key_store_password)

      # Move to create_truststores?
      # Legacy systems assume truststore password is same as keystore
      import_cert_into_truststore(node, 'Agent', key_store_path, 'legacy-agent.cer', 'legacy-agent-truststore.jks', key_store_password)

      # Pre 9.0, but post 8.5, should use the new cert, but the key_store_password
      import_cert_into_truststore(node, 'Agent', key_store_path, 'agent.cer', 'legacy-agent-truststore-kp.jks', key_store_password)
    end

    # Creates the Application Certificate
    def self.create_application_certificate(node, key_store_path, key_store_password, trust_store_password)
      generate_key_pair(node, 'APP', DN, key_store_path, 'application-keystore.jks', key_store_password, KEY_ALGO, KEY_SIZE, SIGNATURE_ALGO, key_store_password, CERT_VALIDITY);
      export_certificate(node, 'APP', key_store_path, 'application-keystore.jks', 'application.cer', key_store_password)
      import_cert_into_truststore(node, 'APP', key_store_path, 'application.cer', 'application-truststore.jks', trust_store_password)
    end

    # Creates the DCC Certificate
    def self.create_DCC_certificate(node, key_store_path, key_store_password, trust_store_password)
      generate_key_pair(node, 'DCC', DN, key_store_path, 'dcc-keystore.jks', key_store_password, KEY_ALGO, KEY_SIZE, SIGNATURE_ALGO, key_store_password, CERT_VALIDITY);
      export_certificate(node, 'DCC', key_store_path, 'dcc-keystore.jks', 'dcc.cer', key_store_password)
      import_cert_into_truststore(node, 'DCC', key_store_path, 'dcc.cer', 'dcc-truststore.jks', trust_store_password)
    end
    
    # Creates the legacy DCC Certificate
    def self.create_legacy_DCC_certificate(node, key_store_path, key_store_password, trust_store_password)
      # We need it in the dcc-keystore for signing bundles for legacy systems
      generate_key_pair(node, 'Legacy_DCC', DN, key_store_path, 'dcc-keystore.jks', key_store_password, LEGACY_KEY_ALGO, LEGACY_KEY_SIZE, LEGACY_SIGNATURE_ALGO, key_store_password, CERT_VALIDITY);
      export_certificate(node, 'Legacy_DCC', key_store_path, 'dcc-keystore.jks', 'legacy-dcc.cer', key_store_password)
    end
    
    # Creates the web Certificate
    def self.create_web_certificate(node, key_store_path, key_store_password, trust_store_password)
      generate_key_pair(node, 'Web', WEB_DN_TEMPLATE % (node['fqdn'] || node['hostname']).downcase(), key_store_path, 'web-keystore.jks', key_store_password, KEY_ALGO, KEY_SIZE, SIGNATURE_ALGO, key_store_password, CERT_VALIDITY);
      export_certificate(node, 'Web', key_store_path, 'web-keystore.jks', 'web.cer', key_store_password)
      import_cert_into_truststore(node, 'Web', key_store_path, 'web.cer', 'web-truststore.jks', trust_store_password)
      import_cert_into_truststore(node, 'DCC', key_store_path, 'dcc.cer', 'web-truststore.jks', trust_store_password)
    end
    
    # Creates the digital signature Certificate
    def self.create_digital_signature_certificate(node, key_store_path, key_store_password, trust_store_password)
      generate_key_pair(node, (node['fqdn'] || node['hostname']), WEB_DN_TEMPLATE % (node['fqdn'] || node['hostname']).downcase(), key_store_path, 'digital-signature-keystore.jks', key_store_password, KEY_ALGO, KEY_SIZE, SIGNATURE_ALGO, key_store_password, CERT_VALIDITY);
      export_certificate(node, (node['fqdn'] || node['hostname']), key_store_path, 'digital-signature-keystore.jks', 'digital-signature.cer', key_store_password)
      import_cert_into_truststore(node, (node['fqdn'] || node['hostname']), key_store_path, 'digital-signature.cer', 'digital-signature-truststore.jks', trust_store_password)
    end

    # Creates the all the truststores
    def self.create_truststores(node, key_store_path, key_store_password, trust_store_password)
      import_cert_into_truststore(node, 'Agent', key_store_path, 'agent.cer', 'dcc-truststore.jks', trust_store_password)
      import_cert_into_truststore(node, 'Legacy_Agent', key_store_path, 'legacy-agent.cer', 'dcc-truststore.jks', trust_store_password)
      import_cert_into_truststore(node, 'APP', key_store_path, 'application.cer', 'dcc-truststore.jks', trust_store_password)
      import_cert_into_truststore(node, 'PolicyAuthor', key_store_path, 'policyAuthor.cer', 'dcc-truststore.jks', trust_store_password)
      import_cert_into_truststore(node, 'Enrollment', key_store_path, 'enrollment.cer', 'dcc-truststore.jks', trust_store_password)
      import_cert_into_truststore(node, 'KeyManagement', key_store_path, 'keymanagement.cer', 'dcc-truststore.jks', trust_store_password)
      import_cert_into_truststore(node, 'Temp_Agent', key_store_path, 'temp_agent.cer', 'dcc-truststore.jks', trust_store_password)
      import_cert_into_truststore(node, 'Orig_Temp_Agent', key_store_path, 'orig_temp_agent.cer', 'dcc-truststore.jks', trust_store_password)
      import_cert_into_truststore(node, 'DCC', key_store_path, 'dcc.cer', 'agent-truststore.jks', trust_store_password)
      
      # We have two legacy agent truststores. The first is for pre-8.5
      # systems. These signed the bundle with a weaker cipher. We need
      # that cert (the legacy dcc) to verify the signing, but we need
      # the current dcc cert to verify the connection.
      #
      # The use of key_store_password is not an error. Pre-9.0 systems
      # used the same password for keystore and truststore
      #
      # Pre 8.5
      import_cert_into_truststore(node, 'DCC', key_store_path, 'legacy-dcc.cer', 'legacy-agent-truststore.jks', key_store_password)
      import_cert_into_truststore(node, 'Current_DCC', key_store_path, 'dcc.cer', 'legacy-agent-truststore.jks', key_store_password)

      # 8.5-9.0
      import_cert_into_truststore(node, 'DCC', key_store_path, 'dcc.cer', 'legacy-agent-truststore-kp.jks', key_store_password)

      import_cert_into_truststore(node, 'DCC', key_store_path, 'dcc.cer', 'application-truststore.jks', trust_store_password)
    end

    # Generates an SSL certificate
    #
    # keytool.exe -genkeypair -alias 'Agent' -dName 'CN=Agent, OU=CompliantEnterprise, O=NextLabs, L=San Mateo, ST=CA, C=US'
    #  -keypass [trust_store_password]
    #  -keystore '[INSTALLDIR]server\certificates\agent-keystore.jks' -storepass [trust_store_password]
    def self.generate_key_pair(node, alias_name, d_name, key_store_path, key_store_name, key_pass, key_algorithm, key_size, signature_algorithm, key_store_password, validity)

      keytool = get_key_tool(node)
      key_store_location = File.join(key_store_path, key_store_name)

      cmd_str = %Q["#{keytool}" -genkeypair -alias "#{alias_name}" -dName "#{d_name}" -keypass "#{key_pass}" -keystore "#{key_store_location}" -storepass "#{key_store_password}" -keyalg "#{key_algorithm}" -keysize "#{key_size}" -sigalg "#{signature_algorithm}" -validity "#{validity}"]
      shell_out!(cmd_str)

    end

    # Self signs a certificate (no need since we can set the validity of certs when we generate the certificate)
    #
    # keytool.exe -selfcert -alias 'Agent' -keypass [trust_store_password] -keystore '[INSTALLDIR]server\certificates\agent-keystore.jks' -storepass [trust_store_password] -validity 3650
    # ///////////////////////////////////////////////////////////////
    # def self.sign_certificate(node, alias_name, key_store_path, key_store_name, key_store_password, trust_store_password)
    #   begin
    #
    #     keytool = get_key_tool(node)
    #     keystoreLocation = File.join(key_store_path, key_store_name)
    #
    #     cmd = %Q[#{keytool} -selfcert -alias '#{alias_name}' -keypass '#{key_store_password}' -keystore '#{keystoreLocation}' -storepass '#{trust_store_password}' -validity 3650 ]
    #
    #     pipe = IO.popen(cmd)
    #     ## TODO:
    #     # A proper way to verify the key is signed correctly
    #     if pipe != nil
    #       return true
    #     else
    #       puts 'Certificate signs failed'
    #       return false
    #     end
    #   rescue
    #     puts 'Unable to perform certificate signs'
    #     false
    #   ensure
    #     if pipe != nil
    #        pipe.close
    #     end
    #   end
    # end

    # Exports a certificate from a keystore to a certificate file
    #
    # keytool.exe -exportcert -alias 'Agent' -file '[INSTALLDIR]server\certificates\agent.cer'
    # -keystore '[INSTALLDIR]server\certificates\agent-keystore.jks' 
    # -storepass [trust_store_password]
    def self.export_certificate(node, alias_name, key_store_path, key_store_name, certificate_file, trust_store_password)

      keytool = get_key_tool(node)
      key_store_location = ::File.join(key_store_path, key_store_name)
      cert_location = ::File.join(key_store_path, certificate_file)

      cmd_str = %Q["#{keytool}" -exportcert -alias "#{alias_name}" -file "#{cert_location}" -keystore "#{key_store_location}" -storepass "#{trust_store_password}" ]
      shell_out!(cmd_str)

    end  

    # Imports a certificate file in a truststore
    #
    # keytool.exe -importcert -v -noprompt -alias 'DCC' -file '[INSTALLDIR]server\certificates\dcc.cer'
    # -keystore '[INSTALLDIR]server\certificates\agent-truststore.jks' 
    # -storepass [trust_store_password]
    def self.import_cert_into_truststore(node, alias_name, key_store_path, certificate_file, trust_store_name, trust_store_password)
      keytool = get_key_tool(node)
      trust_store_location = ::File.join(key_store_path, trust_store_name)
      cert_location = ::File.join(key_store_path, certificate_file)

      cmd_str = %Q["#{keytool}" -importcert -v -noprompt -alias "#{alias_name}" -file "#{cert_location}" -keystore "#{trust_store_location}" -storepass "#{trust_store_password}" ]
      shell_out!(cmd_str)

    end

    # Delete an entry from a keystore/truststore
    # keytool.exe -delete -v -alias 'DCC' -keystore '[INSTALLDIR]server\certificates\dcc-keystore.jks' -storepass [trust_store_password]
    def self.delete_entry(node, alias_name, store_path, store_name, trust_store_password)
      keytool = get_key_tool(node)

      store_location = ::File.join(store_path, store_name)
      cmd_str = %Q["#{keytool}" -delete -v -alias "#{alias_name}" -keystore "#{store_location}" -storepass "#{trust_store_password}" ]
      shell_out!(cmd_str)
    end
    
    # Moves an entry from one keystore to another. This is the only way to move a public/private key
    # pair from one keystore into another (importing an exported .cer doesn't work, because the .cer is
    # just the public key)
    def self.import_from_keystore(node, src_alias, src_key_store_path, src_key_store_name, src_pass, dest_alias, dest_key_store_path, dest_key_store_name, dest_pass)
        keytool = get_key_tool(node)
        
        src_key_store_location = ::File.join(src_key_store_path, src_key_store_name)
        dest_key_store_location = ::File.join(dest_key_store_path, dest_key_store_name)

        cmd_str = %Q["#{keytool}" -importkeystore -v -noprompt -srckeystore "#{src_key_store_location}" -destkeystore "#{dest_key_store_location}" -srcstorepass "#{src_pass}" -deststorepass "#{dest_pass}" -srcalias "#{src_alias}" -destalias "#{dest_alias}" ]
        shell_out!(cmd_str)
    end
    
    # Delete the certificate directory
    def self.delete_certificates( key_store_path )
      FileUtils.rm_rf(key_store_path)
      FileUtils.mkdir_p(key_store_path)
    end 

    def self.get_key_tool(node)
      keytool_exe = (RUBY_PLATFORM =~ /mswin|mingw|windows/) ? 'keytool.exe' : 'keytool'
      File.expand_path("../#{keytool_exe}", node['jre_x_path'])
    end

    def self.import_web_certificate_to_cacerts(node, alias_name)
      keytool = get_key_tool(node)
      cmd_str = %Q["#{keytool}" -import -v -noprompt -alias "#{alias_name}" -keystore "#{::File.join(node['installation_dir'], 'java/jre/lib/security/cacerts')}" -storepass changeit -file "#{::File.join(node['installation_dir'], 'server/certificates/web.cer')}"]
      shell_out!(cmd_str)
    end

    def self.import_db_ssl_certificate(node, key_store_path, trust_store_password)
      if node['db_ssl_certificate'] != nil && node['db_ssl_certificate'] != ""
        ssl_cert = File.basename(node['db_ssl_certificate'])
        import_cert_into_truststore(node, 'Database', key_store_path, ssl_cert, 'web-truststore.jks', trust_store_password)
      end
    end
    
    private_class_method(:get_key_tool, :export_certificate,
                         :generate_key_pair, :create_truststores,
                         :create_DCC_certificate, :create_legacy_DCC_certificate, :create_application_certificate,
                         :create_agent_certificate)

  end unless defined?(Server::Certs) # https://github.com/sethvargo/chefspec/issues/562#issuecomment-74120922
end
