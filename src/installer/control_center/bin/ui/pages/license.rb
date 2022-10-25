#! /usr/bin/env ruby
# encoding: utf-8
#
require_relative "../bootstrap"
require_relative "../utility"
include Utility

class Installation < Shoes

  url '/license',             :license

  def license 

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
          para ReadableNames["license_page"]["heading"], @@heading_1_style 
        end

        stack :width => 1.0, :height => 100, :height => 100 do
          para ReadableNames["license_page"]["help_note"], @@help_note_style
        end
        
        flow :width => 750, :height => 50 do

          stack :width => 520, :margin_left => 10, :margin_right => 10, 
              :margin_top => 10, :height => 1.0 do

            @license_file_location_edit = nl_text_edit( :long, text=$item.license_file_location, { :width => 500 } )
            @license_file_location_edit.change {
              # use "/" to be consistent
              $item.license_file_location = @license_file_location_edit.text.gsub("\\", "/")
            }

          end
          
          stack :width => 180, :margin_left => 10, :margin_right => 10,
              :margin_top => 10, :height => 1.0 do
              button ReadableNames["browse_file_btn"] do
              # if user cancel the folder selection, ask_open_folder will reture nil
              # to prevent the nil being assigned to the variables, we need to check
              browse_result = ask_open_file
              (@license_file_location_edit.text = browse_result) if browse_result != nil
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
            @license_back_btn = nl_button :back
            @license_back_btn.click { back_btn_click_proc.call }
          end

          stack :width => 50, :height => 1.0 do
            @license_back_text_btn = nl_button :back_text, :click => back_btn_click_proc
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
              "license_file_location"    => @license_file_location_edit
            }
            validated, field, error_msg = $item.validate_fields "license_file_location"
            if not validated 
              alert_ontop_parent(app.win, error_msg, :title => app.instance_variable_get('@title'))
              control_fields[field].focus
            end
            
            if validated
              begin
                valid_license_result = LicenseChecker.validate_license($item.license_file_location)
              rescue Exception => e
                valid_license_result = false
              end

              if !valid_license_result
                validated = false
                alert_ontop_parent(app.win, ReadableNames["license_page"]["invalid_file"], :title => app.instance_variable_get('@title'))
              end
            end
            
            if validated 
              visit(self.wizard(:next))
            end
          }

          stack :width => 50, :height => 1.0 do
            @license_next_text_btn = nl_button :next_text, :click => next_btn_click_proc
          end

          stack :width => 50, :height => 1.0 do
            @license_next_btn = nl_button :next
            @license_next_btn.click { next_btn_click_proc.call }
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
    visit('/license')
  end
end
