#! /usr/bin/env ruby
# encoding: utf-8
#
require_relative "../bootstrap"
require_relative "../utility"
include Utility

class Installation < Shoes

  url '/',             :welcome
  
  def welcome
    
    stack @@installer_page_size_style do
      
      background @@header_color_style
      
      # First is the company name
      stack :width => 1.0, :height => 200 do
        # border black
        para ReadableNames["common"]["company_name"], @@heading_1_style.merge({:align => "center", 
            :margin_top => 150, :size => 22})
      end

      # Then welcome paragrah
      stack :width => 1.0, :height => 50 do
        para ReadableNames["welcome_page"]["welcome_para"], @@heading_1_style.merge({:align => "center", 
            :margin_top => 25, :size => 15})
      end

      # Then product name
      stack :width => 1.0, :height => 80 do
        para ReadableNames["common"]["product_name"], @@heading_1_style.merge({:align => "center", 
            :size => 17})
      end

      # Then the next button
      flow :width => 1.0, :height => 60 do
        # This is a horizontal spacer  
        stack :width => 450, :height => 60 do
          para " "
        end
        # This is the container for next button
        stack :width => 50, :height => 50 do
          @welcome_next_btn = nl_button :next
          @welcome_next_btn.click do
            visit(wizard(:next))
          end
        end
      end

      # Then the copyright info
      stack @@installer_footer_size_style do
        para ReadableNames["welcome_page"]["copyright_message"],  @@copyright_label_style
      end

    end
  end
end

if __FILE__ == $0
  Shoes.app :title => ReadableNames["title"] , :width => 950, :height => 700 do
    win.set_size_request(950, 700)
    win.set_resizable(false)
    win.set_window_position(Gtk::Window::POS_CENTER_ALWAYS)
    visit('/')
  end
end