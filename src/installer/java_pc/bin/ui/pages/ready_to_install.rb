#! /usr/bin/env ruby
# encoding: utf-8
#
require_relative "../bootstrap"
require_relative "../utility"
include Utility

class Installation < Shoes

  url '/ready_to_install',            :ready_to_install

  def ready_to_install 
    
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
          para ReadableNames["ready_to_install_page"]["heading"], @@heading_1_style 
        end

        stack :width => 1.0, :height => 60 do
          para ReadableNames["ready_to_install_page"]["help_note"], @@help_note_style
        end

        stack :width => 1.0, :height => 40 do
          para ReadableNames["ready_to_install_page"]["help_note_2"], @@help_note_style
        end

        stack :width => 1.0, :height => 40 do
          para ReadableNames["ready_to_install_page"]["help_note_3"], @@help_note_style
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
            @ready_to_install_back_btn = nl_button :back
            @ready_to_install_back_btn.click { back_btn_click_proc.call }
          end

          stack :width => 50, :height => 1.0 do
            @ready_to_install_back_text_btn = nl_button :back_text, :click => back_btn_click_proc
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
            visit(wizard(:next))
          }

          stack :width => 50, :height => 1.0 do
            @ready_to_install_next_text_btn = nl_button :next_text, :click => next_btn_click_proc
          end

          stack :width => 50, :height => 1.0 do
            @ready_to_install_next_btn = nl_button :next
            @ready_to_install_next_btn.click { next_btn_click_proc.call }
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
    visit('/ready_to_install')
  end
end