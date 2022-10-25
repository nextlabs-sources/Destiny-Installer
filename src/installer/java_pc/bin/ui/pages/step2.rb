#! /usr/bin/env ruby
# encoding: utf-8
#
require_relative "../bootstrap"
require_relative "../utility"
include Utility
require "fileutils"

class Installation < Shoes

  url '/step2',        :step2

  STEP2_CONTROLS = [
    "cc_host",
    "cc_port",
    "policy_controller_port",
    "installation_dir",
    "dpc_path"
  ]

  def step2
    
    style(Link, :underline => false, :stroke => "#FFF", :weight => "bold")
    style(LinkHover, :underline => false, :stroke => "#FFF", :weight => "bold")

    stack @@installer_page_size_style do

      # The header
      stack @@installer_header_size_style do
        
        background @@header_color_style
        banner
        
      end

      # The main body
      stack @@installer_content_size_style do

        background @@content_color_style

        stack :width => 1.0, :height => 80 do
          # configuration information area
          para ReadableNames["step2_page"]["heading"],
              @@help_note_style
        end

        STEP2_CONTROLS.each do |contr|

          # Only show installtion dir control and DPC Path control if JBOSS
          unless ( ( ["installation_dir", "dpc_path"].include? contr ) \
              && ( $item.server_type.eql? "TOMCAT") )

            flow :width => 1.0, :height => 40 do

              # First the label
              stack :width => 300, :margin_left => 10, :margin_right => 10,
                  :margin_top => 10, :height => 1.0 do
                 para ReadableNames["inputs"][contr],  @@text_label_style
              end

              stack :width => 350, :margin_left => 10, :margin_right => 10,
                  :margin_top => 10, :height => 1.0 do

                # Then the text input, set text edit to instance variable "{contr}_edit"
                case contr
                when "installation_dir", "dpc_path"
                  self.instance_variable_set( "@#{contr}_edit", \
                      nl_text_edit(:long, text=$item.instance_variable_get("@"+contr), \
                        {:width => 350}) )

                  self.instance_variable_get("@#{contr}_edit").change do |t_self|
                    $item.instance_variable_set( "@"+contr, \
                        t_self.text.gsub("\\", "/") )
                  end
                else
                  text_edit_params = {:width => 350}
                  if contr =~ /port/
                    text_edit_params[:width] = 100
                  end
                  self.instance_variable_set( "@#{contr}_edit", \
                      nl_text_edit(:long, text=$item.instance_variable_get("@"+contr), \
                        text_edit_params) )
                  self.instance_variable_get("@#{contr}_edit").change do |t_self|
                    $item.instance_variable_set( "@"+contr, t_self.text )
                  end
                end

              end

              if ( ["installation_dir", "dpc_path"].include? contr )
                # this is a spacer
                stack :width => 15, :height => 1.0 do
                  para " "
                end

                stack :width => 180, :margin_left => 10, :margin_right => 10,
                    :margin_top => 10, :height => 1.0 do
                  button ReadableNames["browse_folder_btn"] do
                    browse_result = ask_open_folder
                    (self.instance_variable_get("@#{contr}_edit").text = browse_result) if browse_result != nil
                  end
                end

              end

            end
          end

        end

      end

      # The footer area
      stack @@installer_footer_size_style do

        background @@footer_color_style

        # This is a vertical spacer
        stack :width => 1.0, :height => 35 do
          para " "
        end

        flow :width => 1.0, :height => 50 do
          # This is a horizontal spacer
          stack :width => 30, :height => 1.0 do
            para " "
          end

          back_btn_click_proc = Proc.new{
            visit(wizard(:back))
          }

          stack :width => 50, :height => 1.0 do
            @step2_back_btn = nl_button :back
            @step2_back_btn.click { back_btn_click_proc.call }
          end
          
          stack :width => 50, :height => 1.0 do
            @step2_back_text_btn = nl_button :back_text, :click => back_btn_click_proc
          end

          stack :width => 100, :height => 1.0 do
            
            cancel_btn_click_proc = Proc.new{
              if confirm_ontop_parent(app.win, ReadableNames["cancel_confirm"],
                  :title=> app.instance_variable_get('@title')) then
                exit
              end
            }

            nl_button :cancel, :click => cancel_btn_click_proc

          end

          # This is a horizontal spacer
          stack :width => 590, :height => 1.0 do
            para " "
          end

          next_btn_click_proc = Proc.new{

            # before we proceed, we need to check user input
            control_fields = {
              "policy_controller_port"   => @policy_controller_port_edit,
              "cc_host"                  => @cc_host_edit,
              "cc_port"                  => @cc_port_edit,
              "installation_dir"         => @installation_dir_edit,
              "dpc_path"                 => @dpc_path_edit
            }
            validated, field, error_msg = $item.validate_fields "policy_controller_port", 
                "cc_host", "cc_port"
            if ($item.server_type.eql? "TOMCAT") and validated then
              # For tomcat type install, install_dir should be inside the tomcat server path
              $item.installation_dir = File.join($envs.CATALINA_HOME, "nextlabs")
              # For tomcat type install, dpc_path need to be set inside the installation_dir
              # So we need to set the dpc_path explicitly here
              # But we don't need to create the path yet
              $item.dpc_path = File.join($item.installation_dir, "dpc")
              
            elsif ($item.server_type.eql? "JBOSS") and validated 
              # For jboss type install, dpc_path can be specified to any dir
              # So we need to validate that path
              # The dpc path user specified is only the parent folder, later when we generate the 
              # json conifg for chef-client, we need append dpc explicitly
              validated, field, error_msg = $item.validate_fields "installation_dir", "dpc_path"
            end

            if not validated then
              alert_ontop_parent(app.win, error_msg, :title => app.instance_variable_get('@title'))
              control_fields[field].focus
            else
              # If the installation type is tomcat, then we need to create the installation dir
              # if it's not existed
              if ($item.server_type.eql? "TOMCAT") and 
                  not File.exist?($item.installation_dir)  then
                  FileUtils.mkdir($item.installation_dir)
              end
              # before we proceed, since we got the installation_dir, we can get the drive_root_dir
              $item.drive_root_dir = Utility.get_drive_names($item.installation_dir)
              visit(wizard(:next))
            end

          }

          stack :width => 50, :height => 1.0 do
            @step2_next_text_btn = nl_button :next_text, :click => next_btn_click_proc
          end

          stack :width => 50, :height => 1.0 do
            @step2_next_btn = nl_button :next
            @step2_next_btn.click { next_btn_click_proc.call }
          end

        end

      end

    end

  end

end

if __FILE__ == $0
  Shoes.app :title => ReadableNames["title"] , :width => 950, :height => 700 do
    win.set_size_request(950, 700)
    win.set_resizable(false)
    win.set_window_position(Gtk::Window::POS_CENTER_ALWAYS)
    visit('/step2')
  end
end