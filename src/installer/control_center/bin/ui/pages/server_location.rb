#! /usr/bin/env ruby
# encoding: utf-8
#
require_relative '../bootstrap'
require_relative '../utility'
include Utility

class Installation < Shoes

  url '/server_location',             :server_location

  SERVER_LOCATION_CONTROLS = %w[
    installed_cc_host
    installed_cc_port
    trust_store_password
    key_store_password
  ]

  def server_location 

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
          para ReadableNames["server_location_page"]["heading"], @@heading_1_style 
        end

        stack :width => 1.0, :height => 100, :margin_right => 10, :height => 80 do
          para ReadableNames["server_location_page"]["help_note"], @@help_note_style
        end

        SERVER_LOCATION_CONTROLS.each do |contr|

          # First the label
          stack :width => 1.0, :height => 30,  :margin_top => 10, 
              :margin_left => 10, :margin_right => 10 do
            para ReadableNames["server_location_page"][contr],  @@text_label_style
          end

          stack :width => 1.0, :height => 40,  :margin_left => 10,
              :margin_top => 10 do
            # Then the text input, set text edit to instance variable "{contr}_edit"
            # Set the password field to secret
            text_edit_params = {:width => 350}
            if contr =~ /password/ 
              text_edit_params[:secret] = true
            end
            if contr =~ /port/
              text_edit_params[:width] = 100
            end
            self.instance_variable_set( "@#{contr}_edit", \
                nl_text_edit(:long, text=$item.instance_variable_get("@"+contr),
                  text_edit_params) )
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
            @server_location_back_btn = nl_button :back
            @server_location_back_btn.click { back_btn_click_proc.call }
          end

          stack :width => 50, :height => 1.0 do
            @server_location_back_text_btn = nl_button :back_text, :click => back_btn_click_proc
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

            # First populate the instance variables of items
            SERVER_LOCATION_CONTROLS.each do |contr|
              $item.instance_variable_set("@"+contr, \
                self.instance_variable_get("@#{contr}_edit").text)
            end

            control_fields = {}
            
            SERVER_LOCATION_CONTROLS.each do |contr|
              control_fields[contr] = self.instance_variable_get("@#{contr}_edit")
            end

            validated, field, error_msg = $item.validate_fields *SERVER_LOCATION_CONTROLS
              
            if ! validated
              alert_ontop_parent(app.win, error_msg, :title => app.instance_variable_get('@title'))
              control_fields[field].focus
            else
              visit(wizard(:next))
            end

          }

          stack :width => 50, :height => 1.0 do
            @server_location_next_text_btn = nl_button :next_text, :click => next_btn_click_proc
          end

          stack :width => 50, :height => 1.0 do
            @server_location_next_btn = nl_button :next
            @server_location_next_btn.click { next_btn_click_proc.call }
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
    visit('/server_location')
  end
end
