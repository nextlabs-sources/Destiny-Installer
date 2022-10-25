#! /usr/bin/env ruby
# encoding: utf-8
#
require_relative "../bootstrap"
require_relative "../utility"
include Utility

class Installation < Shoes

  url '/service_port',             :service_port

  def service_port 

    stack @@installer_page_size_style do
      
      style(Link, :underline => false, :stroke => "#FFF", :weight => "bold")
      style(LinkHover, :underline => false, :stroke => "#FFF", :weight => "bold")
      
      # The header area
      stack  @@installer_header_size_style do

        background @@header_color_style
        banner

      end

      # The body

      stack  @@installer_content_size_style do

        background @@content_color_style

         stack :width => 1.0, :height => 40 do
           para ReadableNames["service_port_page"]["heading"], @@heading_1_style 
         end

         stack :width => 1.0, :height => 100, :margin_right => 10 do
          para ReadableNames["service_port_page"]["help_note"],  @@help_note_style

         end

        @config_service_port_panel = flow :width => 1.0, :height => 40 do

           stack :width => 300, :margin_left => 10, :margin_right => 10,
               :margin_top => 20, :height => 30 do
              para ReadableNames["inputs"]["config_service_port_no"],  @@text_label_style
           end

           stack :width => 250, :margin_left => 10, :margin_right => 10,
               :margin_top => 20, :height => 40 do
            @config_service_port_edit = nl_text_edit( :short, text=$item.config_service_port, { :width => 100 } )
           end
        end
        
        flow :width => 1.0, :height => 40 do 
        
           stack :width => 300, :margin_left => 10, :margin_right => 10, 
               :margin_top => 20, :height => 30 do
              para ReadableNames["inputs"]["web_service_port_no"],  @@text_label_style
           end

           stack :width => 200, :margin_left => 10, :margin_right => 10, 
               :margin_top => 20, :height => 40 do
            @web_service_port_edit = nl_text_edit( :short, text=$item.web_service_port, { :width => 100 } )
           end
        end 

        @web_application_port_panel = flow :width => 1.0, :height => 40 do 

           stack :width => 300, :margin_left => 10, :margin_right => 10, 
               :margin_top => 20, :height => 30 do
              para ReadableNames["inputs"]["web_application_port_no"],  @@text_label_style
           end

           stack :width => 250, :margin_left => 10, :margin_right => 10, 
               :margin_top => 20, :height => 40 do
            @web_application_port_edit = nl_text_edit( :short, text=$item.web_application_port, { :width => 100 } )
           end
        end

      end
      
      if $item.admin_component === "OFF" && $item.reporter_component === "OFF" && $item.cc_console_component === "OFF"
        @web_application_port_panel.hide
      end
      
      if $item.dms_component === "OFF"
        @config_service_port_panel.hide
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
            @service_port_back_btn = nl_button :back
            @service_port_back_btn.click { back_btn_click_proc.call }
          end

          stack :width => 50, :height => 1.0 do
            @service_port_back_text_btn = nl_button :back_text, :click => back_btn_click_proc
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

            control_fields = {
              "web_service_port"      => @web_service_port_edit,
              "web_application_port"  => @web_application_port_edit,
              "config_service_port"   => @config_service_port_edit
            }
            $item.web_service_port = @web_service_port_edit.text
            $item.web_application_port = @web_application_port_edit.text
            $item.config_service_port = @config_service_port_edit.text

            validated, field, error_msg = $item.validate_fields "web_service_port",
                "web_application_port", "config_service_port"

            if ! validated
              alert_ontop_parent(app.win, error_msg, :title => app.instance_variable_get('@title'))
              control_fields[field].focus
            else
              visit(wizard(:next))
            end

          }

          stack :width => 50, :height => 1.0 do
            @service_port_next_text_btn = nl_button :next_text, :click => next_btn_click_proc
          end

          stack :width => 50, :height => 1.0 do
            @service_port_next_btn = nl_button :next
            @service_port_next_btn.click { next_btn_click_proc.call }
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
    visit('/service_port')
  end
end