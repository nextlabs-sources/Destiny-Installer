#! /usr/bin/env ruby
# encoding: utf-8
#
require_relative '../bootstrap'
require_relative '../utility'
include Utility
require 'tmpdir'
require 'fileutils'

$install_cmd_exited = false

# to stop the installation half way, we need to send SIGINT to the subprocess,
# but the chef-client spawns other processes, so we must send SIGINT to the process group
# which means the father process will also receive the SIGINT
# so we need to ignore here
trap('INT') {}

class Installation < Shoes

  url '/install',             :install

  def install

    style(Link, :underline => false, :stroke => '#FFF', :weight => 'bold')
    style(LinkHover, :underline => false, :stroke => '#FFF', :weight => 'bold')

    stack @@installer_page_size_style do
      
      
      # The header area
      stack @@installer_header_size_style do

        background @@header_color_style
        banner

      end

      # The progress area
      stack :width => 1.0, :heigth => 75 do

        background @@content_color_style

        # a vertical spacer
        stack :width => 1.0, :height => 50 do
          para ' '
        end

        flow :width => 1.0, :height => 25 do
          
          # a horizontal spacer
          stack :width => 85, :height => 1.0 do
            para ' '
          end
          # the progress message
          stack :width => 750, :height => 1.0 do
            @progress_msg = inscription ' '
          end
        end

        @progress = progress :width => 750, :left => 85, :top => 150
        
      end

      # The log area
      flow :width => 1.0, :height => 350 do
        stack :width => 50, :height => 1.0 do
          background @@content_color_style
          para ' '
        end

        stack :width => 850, :height => 1.0 do
          @log_area = edit_box :width => 1.0, :height => 1.0, :state => "disabled"
        end

        stack :width => 50, :height => 1.0 do
          background @@content_color_style
          para ' '
        end
      end

      # A vertical spacer
      stack :width => 1.0, :height => 25 do
        background @@content_color_style
        para ' '
      end
      
      # The footer area
      stack @@installer_footer_size_style do

        background @@footer_color_style

        # This is a vertical spacer
        stack :width => 1.0, :height => 35 do
          para ' '
        end

        flow :width => 1.0, :height => 50 do
          # This is a horizontal spacer
          stack :width => 30, :height => 1.0 do
            para ' '
          end

          # The installation page has no back btn
          stack :width => 50, :height => 1.0 do
           para ' '
          end

          @install_cancel_btn_slot = stack :width => 100, :height => 1.0 do
            
            # a helper lambda for getting process group id
            sysint_gpid = lambda do
              case RUBY_PLATFORM
              when /mswin|mingw|windows/ then
                return 0
              when /linux/ then
                return -Process.getpgrp
              end
            end
            install_cancel_btn_click_proc = Proc.new{
              # The cancel btn should only work during installation
              if !$install_cmd_exited
                if confirm_ontop_parent(app.win, ReadableNames["cancel_confirm"],
                    :title=> app.instance_variable_get('@title')) then
                  if @install_util["pipe"] != nil then
                    # set the canceled flag
                    $installation_canceled = true
                    Process.kill 'INT', sysint_gpid.call
                    # then disable the cancel btn for now
                    @install_cancel_btn.state = "disabled"
                    # Sometimes the SIGINT got ignored by subprocesses, then ,
                    # let's send one more, but still there's occasions 
                    # the subprocess just can't stop itself
                    sleep 1
                    Process.kill 'INT', sysint_gpid.call
              
                  else
                    puts "child not live"
                  end
                end
              end
            }

            nl_button :cancel, :click => install_cancel_btn_click_proc

          end

          # This is a horizontal spacer
          stack :width => 640, :height => 1.0 do
            para " "
          end

          next_btn_click_proc = Proc.new{

            # we need to check the installation process
            if $install_cmd_exited 
              # First we need move the progress bar
              @progress.move(0, -200)
              visit(wizard(:next))
            end

          }

          stack :width => 50, :height => 1.0 do
            @install_next_text_btn = nl_button :next_text, :click => next_btn_click_proc
          end

          stack :width => 50, :height => 1.0 do
            @install_next_btn = nl_button :next, :state => "disabled" 
            @install_next_btn.click { next_btn_click_proc.call }
          end

        end

      end
    end

    # Hide the cancel functionality
    @install_cancel_btn_slot.hide

    # Then the installation call
    # First generate the json property file
    config_path = $item.save_config_to_temp_dir

    # also try to save the properties config file to the predefined location
    begin
      File.open(CHEF_JSON_PROPERTIES_FILE_BACKUP_LOCATION, 'w') do |file|
        file.write($item.to_json('admin_user_password', 'trust_store_password', 'key_store_password',
            'db_password', 'mail_server_password'))
      end
    rescue Exception => ex
      puts "Failed to save json properties file for later reference"
    end

    @progress_msg.text = strong(fg(ReadableNames["install_page"]["progress_save_config"],
        @@progress_msg_color_style))
    @progress.fraction = 0.05

    # then we create and save the chef-client config file
    chef_client_config = <<"END_OF_CONFIG"
cookbook_path       "#{File.join(START_DIR, 'cookbooks')}"
local_mode          true
chef_zero.enabled   true
json_attribs        "#{config_path}"
log_location        STDOUT
log_level           :info
verbose_logging     true
END_OF_CONFIG

    chef_client_config_path = File.join(Dir::tmpdir, "client.rb")
    # save the chef-client config file to temp dir
    File.open(chef_client_config_path, 'w') do |file|
      file.write(chef_client_config)
    end

    @progress_msg.text = strong(fg(ReadableNames["install_page"]["progress_start_chef"],
        @@progress_msg_color_style))
    @progress.fraction = 0.1

    @install_util = {}
    # This is the variable to store the original logs for storing to log file
    @install_util["original_log"] = ""
    # This is a variable to store error message from chef-client process
    @install_util["error_msg"] = ""

    update_progress = lambda do |log_msg|

      if match = log_msg.match(/INFO: \[Progress\]\s(.*)/i)

        progress_msg = match.captures[0].strip
        @progress_msg.text = strong(fg(progress_msg, @@progress_msg_color_style))

        if log_msg.include?(ProgressLog::PRECHECK_DONE) ||
            log_msg.include?(ProgressLog::COPYFILE_STARTED) ||
            log_msg.include?(ProgressLog::UPGRADE_BACKUP_SERVER_FILES_STARTED) ||
            log_msg.include?(ProgressLog::REMOVE_STARTED)
          @progress.fraction = 0.2
        elsif log_msg.include?(ProgressLog::UPGRADE_BACKUP_SERVER_FILES_DONE) ||
            log_msg.include?(ProgressLog::UPGRADE_BACKUP_SERVICE_STARTED)
          @progress.fraction = 0.3
        elsif log_msg.include?(ProgressLog::UPGRADE_BACKUP_SERVICE_DONE) ||
            log_msg.include?(ProgressLog::UPGRADE_RESTORE_OLD_SERVER_FILES_CONFIGS_STARTED) ||
            log_msg.include?(ProgressLog::UPGRADE_RESTORE_OLD_SERVER_FILES_CONFIGS_DONE)
          @progress.fraction = 0.35
        elsif log_msg.include?(ProgressLog::COPYFILE_DONE)
          @progress.fraction = 0.4
        elsif log_msg.include?(ProgressLog::INSTALL_DATABASE_MANIPULATE_STARTED) ||
            log_msg.include?(ProgressLog::UPGRADE_MODIFY_CONFIGURATION_FILES_DONE) ||
            log_msg.include?(ProgressLog::UPGRADE_DATABASE_MANIPULATE_STARTED)
          @progress.fraction = 0.45
        elsif log_msg.include?(ProgressLog::INSTALL_DATABASE_MANIPULATE_DONE) ||
            log_msg.include?(ProgressLog::INSTALL_SERVICE_CREATE_STARTED) ||
            log_msg.include?(ProgressLog::UPGRADE_DATABASE_MANIPULATE_DONE) ||
            log_msg.include?(ProgressLog::UPGRADE_CREATE_NEW_SERVICE_STARTED)
          @progress.fraction = 0.6
        elsif log_msg.include?(ProgressLog::INSTALL_SERVICE_CREATE_DONE) ||
            log_msg.include?(ProgressLog::REMOVE_NONEED_FILES_STARTED) ||
            log_msg.include?(ProgressLog::UPGRADE_CREATE_NEW_SERVICE_DONE)
          @progress.fraction = 0.65
        elsif log_msg.include?(ProgressLog::REMOVE_NONEED_FILES_DONE) ||
            log_msg.include?(ProgressLog::ADD_UNINSTALL_SCRIPTS_STARTED) ||
            log_msg.include?(ProgressLog::UPGRADE_MODIFY_EXISTING_SERVICE_STARTED) ||
            log_msg.include?(ProgressLog::UPGRADE_MODIFY_EXISTING_SERVICE_DONE)
          @progress.fraction = 0.7
        elsif log_msg.include?(ProgressLog::ADD_UNINSTALL_SCRIPTS_DONE)
          @progress.fraction = 0.9
        elsif log_msg.include?(ProgressLog::INSTALL_FINISHED)
          @progress.fraction = 1.0
          @progress_msg.text = strong(fg(ReadableNames["install_page"]["progress_finish"], @@progress_msg_color_style))
          $installation_finished = true
        elsif log_msg.include?(ProgressLog::UPGRADE_FINISHED)
          @progress.fraction = 1.0
          @progress_msg.text = strong(fg(ReadableNames["install_page"]["progress_upgrade_finish"], @@progress_msg_color_style))
          $installation_finished = true
        elsif log_msg.include?(ProgressLog::REMOVE_FINISHED)
          @progress.fraction = 1.0
          @progress_msg.text = strong(fg(ReadableNames["install_page"]["progress_remove_finish"], @@progress_msg_color_style))
          $installation_finished = true
        else
          nil
        end
      end

      if match_error = log_msg.match(/ERROR:(.*)/i)
        error_msg = match_error.captures[0].strip
        # we got an error, then the installation is regarded as failed
        $installation_failed = true
        @install_util["error_msg"] = "#{ReadableNames["install_page"]["progress_failed"]}: #{error_msg}"
      end

    end

    clean_log = lambda do |log_msg|
      # first remove the timestamp
      log_msg.gsub!(/\[[\d\-T:+]*\]/, '')

      case log_msg
        when /Terminate batch job/i then
          return ""
        when /INFO: Storing updated/i then
          return ""
        else
          return log_msg
      end
    end

    post_install_script_call = lambda do
      if $installation_failed
        @progress.fraction = 0.0
        @progress_msg.text = strong(fg(@install_util["error_msg"],
            @@progress_error_msg_color_style))
      end

      if $installation_canceled then
        @progress.fraction = 0.0
        @progress_msg.text = strong(fg(ReadableNames["install_page"]["progress_canceled"],
            @@progress_msg_color_style))
      end

      # update the flag
      $install_cmd_exited = true
      # # The installation is finished, change btn states
      # @install_next_btn.state = nil
      
      # write the log to log file
      begin
        File.write(ORIGINAL_LOG_LOCATION, @install_util["original_log"])
      rescue Errno::ENOENT => error
        puts "Failed to write log to file"
      end

      # delete json property file
      ::FileUtils.rm_rf(config_path)
    end
    
    @progress.fraction = 0.1

    case RUBY_PLATFORM
    when /mswin|mingw|windows/ then # we are on windows
      trap('INT') {}
      
      @install_util['install_script'] = %Q[
        "#{START_DIR}/engine/chef/bin/chef-client"
        --config "#{chef_client_config_path}"
        -o ControlCenter::main
      ].gsub("\n", ' ')

      @install_util['rollback_script'] = %Q[
        "#{START_DIR}/engine/chef/bin/chef-client"
        --config ""
      ].gsub("\n", ' ')

      
      Thread.new do
        trap('INT') {}
        @install_util["pipe"] = IO.popen(@install_util["install_script"])
        @install_util["pipe"].each do |line|
          @install_util["original_log"] += line
          update_progress.call line
          @log_area.text += clean_log.call(line.to_s)
        end
        # end
        post_install_script_call.call

      end
    when /linux/ then # we are on linux
      trap("INT") {}

      @install_util["install_script"] = <<"END_OF_SCRIPT"
/opt/chef/bin/chef-client --config #{chef_client_config_path} \
-o ControlCenter::main
END_OF_SCRIPT
      
      Thread.new do
        trap("INT") {}

        @install_util["pipe"] = IO.popen(@install_util["install_script"])
        @install_util["pipe"].each do |line|
          @install_util["original_log"] += line
          update_progress.call line
          @log_area.text += clean_log.call(line.to_s)
        end
        # end
        post_install_script_call.call

      end

    else 
      puts "Sorry, your platform [#{RUBY_PLATFORM}] is not supported..."
    end

  end
end

if __FILE__ == $0
  Shoes.app :title => ReadableNames["title"] , :width => 950, :height => 700 do
    # disable the window from resized by the user
    # refer to http://goo.gl/H6m1rZ
    win.set_size_request(950, 700)
    win.set_resizable(false)
    win.set_window_position(Gtk::Window::POS_CENTER_ALWAYS)
    visit('/install')
  end
end
