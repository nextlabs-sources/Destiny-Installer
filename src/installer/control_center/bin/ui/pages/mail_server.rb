#! /usr/bin/env ruby
# encoding: utf-8
#
require_relative '../bootstrap'
require_relative '../utility'
include Utility
require 'timeout'

class Installation < Shoes

  url '/mail_server',             :mail_server

  MAIL_SERVER_CONTROLS = %w[
    mail_server_url
    mail_server_port
    mail_server_username
    mail_server_password
    mail_server_from
    mail_server_to
  ]

  def mail_server 

    style(Link, :underline => false, :stroke => "#FFF", :weight => "bold")
    style(LinkHover, :underline => false, :stroke => "#FFF", :weight => "bold")

    stack @@installer_page_size_style do
      
      
      # The header area
      stack @@installer_header_size_style do

        background @@header_color_style
        banner

      end

      # The body
      stack @@installer_content_size_style do

        background @@content_color_style

        stack :width => 1.0, :height => 40 do
          para ReadableNames["mail_server_page"]["heading"], @@heading_1_style 
        end

        stack :width => 1.0, :height => 80, :margin_right => 10 do
          para ReadableNames["mail_server_page"]["help_note"],  @@help_note_style
        end

        MAIL_SERVER_CONTROLS.each do |contr|

          flow :width => 1.0, :height => 40 do 
          
             stack :width => 200, :margin_left => 10, :margin_right => 10, 
                 :margin_top => 20, :height => 30 do
                para ReadableNames["inputs"][contr],  @@text_label_style
             end

             stack :width => 400, :margin_left => 10, :margin_right => 10, 
                 :margin_top => 20, :height => 30 do
                # Then the text input, set text edit to instance variable "{contr}_edit"
                text_edit_params = {}
                # For mail_server_port, the text input length should be short
                if contr =~ /port/ then
                  text_edit_params[:width] = 100
                end
                if contr =~ /password/ 
                  text_edit_params[:secret] = true
                end
                self.instance_variable_set( "@#{contr}_edit", \
                    nl_text_edit( :long, text=$item.instance_variable_get("@"+contr), text_edit_params) )
              end

          end

        end

        # this is a vertical spacer
        stack :width => 1.0, :height => 20 do
          para " "
        end

        flow :width => 1.0, :height => 50 do
          # this is a horizontal spacer
          stack :width => 210, :height => 1.0 do
            para " "
          end
          stack :width => 100, :height => 1.0 do
            button ReadableNames["mail_server_page"]["test_connnection_btn"] {
              begin
                smtp_connection_result = SMTP.test_SMTP_connection(
                    self.instance_variable_get("@mail_server_url_edit").text,
                    self.instance_variable_get("@mail_server_port_edit").text,
                    self.instance_variable_get("@mail_server_username_edit").text,
                    self.instance_variable_get("@mail_server_password_edit").text,
                    30
                  )
              rescue Exception => e
                smtp_connection_result = false
                msg = ReadableNames["mail_server_page"]["test_connnection_failed_template"] % e.message
              end

              if smtp_connection_result
                msg = ReadableNames["mail_server_page"]["test_connnection_success"]
              else
                msg = ReadableNames["mail_server_page"]["test_connnection_failed_template"] % '' if msg == nil
              end

              alert_ontop_parent(app.win, msg, :title => app.instance_variable_get('@title'))
            }
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
            @mail_server_back_btn = nl_button :back
            @mail_server_back_btn.click { back_btn_click_proc.call }
          end

          stack :width => 50, :height => 1.0 do
            @mail_server_back_text_btn = nl_button :back_text, :click => back_btn_click_proc
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
          stack :width => 490, :height => 1.0 do
            para " "
          end
          
          stack :width => 100, :height => 1.0 do
            
            mail_server_skip_btn_click_proc = Proc.new {
              # First we clear all settings for mail server
              MAIL_SERVER_CONTROLS.each do |contr|
                $item.instance_variable_set("@"+contr, "")
              end
              # then let the wizard decide the next page
              visit(wizard(:next))
            }
            nl_button :skip, :click => mail_server_skip_btn_click_proc

          end

          next_btn_click_proc = Proc.new{

            MAIL_SERVER_CONTROLS.each do |contr|
              $item.instance_variable_set("@"+contr,
                  self.instance_variable_get("@#{contr}_edit").text)
            end
            
            control_fields = {}
            MAIL_SERVER_CONTROLS.each do |contr|
              control_fields[contr] = self.instance_variable_get("@#{contr}_edit")
            end
            
            validated, field, error_msg = $item.validate_fields *MAIL_SERVER_CONTROLS

            if ! validated
              alert_ontop_parent(app.win, error_msg, :title => app.instance_variable_get('@title'))
              control_fields[field].focus
            else
              # then, validate the mail server connection
              begin
                smtp_connection_result = SMTP.test_SMTP_connection(
                  $item.mail_server_url,
                  $item.mail_server_port,
                  $item.mail_server_username,
                  $item.mail_server_password,
                  30
                )
              rescue Exception => e
                puts 'Failed to connect to the SMTP server: ' + e.message
                smtp_connection_result = false
              end

              if smtp_connection_result
                # we need to change skip_smtp_check flag
                $item.skip_smtp_check = false
                visit(wizard(:next))
              else
                # proceed with connection failed
                prompt_msg = ReadableNames['mail_server_page']['proceed_with_connection_failed']
                if confirm_ontop_parent(app.win, prompt_msg,
                    :title=> app.instance_variable_get('@title')) then
                  # we need to change skip_smtp_check flag
                  $item.skip_smtp_check = true
                  visit(wizard(:next))
                else
                  # Then focus to first control field
                  control_fields[MAIL_SERVER_CONTROLS[0]].focus
                end
              end
            end

          }

          stack :width => 50, :height => 1.0 do
            @mail_server_next_text_btn = nl_button :next_text, :click => next_btn_click_proc
          end

          stack :width => 50, :height => 1.0 do

            @mail_server_next_btn = nl_button :next
            @mail_server_next_btn.click { next_btn_click_proc.call }

          end

        end

      end

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
    visit('/mail_server')
  end
end
