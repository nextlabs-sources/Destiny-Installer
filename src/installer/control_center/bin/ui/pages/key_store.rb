#! /usr/bin/env ruby
# encoding: utf-8
#
require_relative "../bootstrap"
require_relative "../utility"
include Utility

class Installation < Shoes

  url '/key_store',             :key_store

  def key_store 

    stack @@installer_page_size_style do
      
      style(Link, :underline => false, :stroke => "#FFF", :weight => "bold")
      style(LinkHover, :underline => false, :stroke => "#FFF", :weight => "bold")
      
      # The header area
      stack @@installer_header_size_style do

        background @@header_color_style
        banner

      end

      # The body
      stack @@installer_content_size_style do

        background @@content_color_style

          stack :width => 1.0, :height => 40 do
          para ReadableNames["key_store_page"]["heading"], @@heading_1_style 
        end

        stack :width => 1.0, :height => 100, :height => 60 do
          para ReadableNames["key_store_page"]["help_note"], @@help_note_style
        end
        
        flow :width => 1.0, :height => 40 do
          stack :width => 250, :margin_left => 10, :margin_right => 10, 
              :margin_top => 20, :height => 40 do
             para ReadableNames["key_store_page"]["key_store_password"],  @@text_label_style
          end

          stack :width => 350, :margin_left => 10, :margin_right => 10, 
              :margin_top => 20, :height => 30 do
           @key_store_password_edit = nl_text_edit( :short, text=$item.key_store_password, 
               { :width => 200 , :secret => true } )
          end
        end

        flow :width => 1.0, :height => 40 do
          stack :width => 250, :margin_left => 10, :margin_right => 10, 
              :margin_top => 20, :height => 40 do
             para ReadableNames["key_store_page"]["confirm_password"],  @@text_label_style
          end

          stack :width => 350, :margin_left => 10, :margin_right => 10, 
              :margin_top => 20, :height => 30 do
           @key_store_password_confi_edit = nl_text_edit( :short, text=$item.key_store_password, 
               { :width => 200, :secret => true } )
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
            @key_store_back_btn = nl_button :back
            @key_store_back_btn.click { back_btn_click_proc.call }
          end

          stack :width => 50, :height => 1.0 do
            @key_store_back_text_btn = nl_button :back_text, :click => back_btn_click_proc
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
              "key_store_password"    => @key_store_password_edit
            }
            # First, the two passwords should match
            validated, field, error_msg = true, nil, nil

            if @key_store_password_edit.text != @key_store_password_confi_edit.text
              validated = false
              error_msg = ReadableNames["pop_up_messages"]["passwd_repeat_no_match"]
              field = "key_store_password"
            end
            
            if validated
              # Then we can assign the value to item
              $item.key_store_password = @key_store_password_edit.text
              validated, field, error_msg = $item.validate_fields "key_store_password"
            end
            
            if ! validated
              alert_ontop_parent(app.win, error_msg, :title => app.instance_variable_get('@title'))
              control_fields[field].focus
            else
              visit(wizard(:next))
            end

          }

          stack :width => 50, :height => 1.0 do
            @key_store_next_text_btn = nl_button :next_text, :click => next_btn_click_proc
          end

          stack :width => 50, :height => 1.0 do
            @key_store_next_btn = nl_button :next
            @key_store_next_btn.click { next_btn_click_proc.call }
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
    visit('/key_store')
  end
end
