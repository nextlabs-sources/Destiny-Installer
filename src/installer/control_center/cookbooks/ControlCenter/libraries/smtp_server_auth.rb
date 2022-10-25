#
# Cookbook Name:: ControlCenter
# library:: SMTP mail server authentication
#     library for check the smtp connection with mail server and
#     authentication
#
# Copyright 2015, Nextlabs Inc.
# Author:: Amila Silva
#
# All rights reserved - Do Not Redistribute
#

module Utility
  module SMTP

    #
    # Method that checks SMTP Server Connectivity (Currently doesn't SSL connection)
    #
    # @param host [String] the SMTP server's IP-address (ex: 127.0.0.1)
    # @param port [Fixnum] the SMTP server's TCP port (ex: 25)
    # @param username [String] the username to authenticate
    # @param password [String] the password to authenticate
    # @param seconds [Fixnum] the timeout for testing connection, default is 5 seconds
    #
    # @return true or false
    #
    # The method will raise any Exception it encounters

    def self.test_SMTP_connection(host, port, username, password, ssl, seconds=15)
      smtpSuccess = connect_to_SMTP(host, port, username, password, ssl, seconds)
    end

    require 'net/smtp'
    require 'timeout'

    # SMTP connection check
    def self.connect_to_SMTP(host, port, username, password, ssl=false, seconds=15)
      Timeout::timeout(seconds) do
        begin
          smtp = Net::SMTP.new(host, port=port)
          smtp.enable_ssl if ssl
          smtp.start
          response = smtp.auth_login( username, password)
          if response != nil &&  response.success?
            return true
          else
            return false
          end
        rescue Exception => ex
          Chef::Log.error('Unable to connect with given Mail Server configuration')
          raise ex
        ensure
          if smtp != nil
            smtp.finish if smtp.started?
            smtp = nil
          end
        end
      end
      rescue Timeout::Error => ex
        Chef::Log.error('Unable to connect with given Database configuration. timeout')
        raise ex
      end

    private_class_method(:connect_to_SMTP)

  end unless defined?(Utility::SMTP) # https://github.com/sethvargo/chefspec/issues/562#issuecomment-74120922
end
