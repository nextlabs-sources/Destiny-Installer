#! /usr/bin/env ruby
# encoding: utf-8
#
require_relative "../bootstrap"
require_relative "../utility"
include Utility

class Installation < Shoes

  url '/administrator_passwd',             :administrator_passwd

  def administrator_passwd 

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
          para ReadableNames["administrator_passwd_page"]["heading"], @@heading_1_style 
        end

        stack :width => 1.0, :height => 100, :margin_right => 10, :height => 80 do
          para ReadableNames["administrator_passwd_page"]["help_note"], @@help_note_style
        end

        flow :width => 1.0, :height => 40 do
          stack :width => 250, :margin_left => 10, :margin_right => 10, 
              :margin_top => 20, :height => 40 do
             para ReadableNames["administrator_passwd_page"]["admin_login_name"],  @@text_label_style
          end
          stack :width => 350, :margin_left => 10, :margin_right => 10, 
              :margin_top => 20, :height => 30 do
           @super_user_name_edit = nl_text_edit( :short, text=$item.super_user_name, { :width => 200 , :state => "disabled" } )
          end
        end
        
        flow :width => 1.0, :height => 40 do
          stack :width => 250, :margin_left => 10, :margin_right => 10, 
              :margin_top => 20, :height => 40 do
             para ReadableNames["administrator_passwd_page"]["password"],  @@text_label_style
          end
          stack :width => 350, :margin_left => 10, :margin_right => 10, 
              :margin_top => 20, :height => 30 do
           @admin_user_password_edit = nl_text_edit( :short, text=$item.admin_user_password, { :width => 200, :secret => true } )
          end
        end
       
        flow :width => 1.0, :height => 40 do
          stack :width => 250, :margin_left => 10, :margin_right => 10, 
              :margin_top => 20, :height => 40 do
             para ReadableNames["administrator_passwd_page"]["confirm_password"],  @@text_label_style
          end
          stack :width => 350, :margin_left => 10, :margin_right => 10, 
              :margin_top => 20, :height => 30 do
           @admin_user_password_confi_edit = nl_text_edit( :short, text=$item.admin_user_password, { :width => 200, :secret => true } )
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
            @administrator_passwd_back_btn = nl_button :back
            @administrator_passwd_back_btn.click { back_btn_click_proc.call }
          end

          stack :width => 50, :height => 1.0 do
            @administrator_passwd_back_text_btn = nl_button :back_text, :click => back_btn_click_proc
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
              "admin_user_password"    => @admin_user_password_edit
            }
            # First, the two passwords should match
            validated, field, error_msg = true, nil, nil

            if @admin_user_password_edit.text != @admin_user_password_confi_edit.text
              validated = false
              error_msg = ReadableNames["pop_up_messages"]["passwd_repeat_no_match"]
              field = "admin_user_password"
            end

            if validated
              # Then we can assign the value to item
              $item.admin_user_password = @admin_user_password_edit.text
              validated, field, error_msg = $item.validate_fields "admin_user_password"
            end

            if ! validated
              alert_ontop_parent(app.win, error_msg, :title => app.instance_variable_get('@title'))
              control_fields[field].focus
            else
              visit(wizard(:next))
            end

          }

          stack :width => 50, :height => 1.0 do
            @administrator_passwd_next_text_btn = nl_button :next_text, :click => next_btn_click_proc
          end

          stack :width => 50, :height => 1.0 do
            @administrator_passwd_next_btn = nl_button :next
            @administrator_passwd_next_btn.click  { next_btn_click_proc.call }              
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
    visit('/administrator_passwd')
  end
end
