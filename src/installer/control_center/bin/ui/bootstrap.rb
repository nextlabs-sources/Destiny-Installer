#! /usr/bin/env ruby
# encoding: utf-8
#
#
#@author::     Duan Shiqiang
#@copyright::  Nextlabs Inc.
#
require "green_shoes"
require "gtk2"
require_relative "./utility"
require_relative "./attributes"
include Utility

# Added alert_ontop_parent method to Object
# to allow alert window be the center of the main window
class Object
  include Types
  def alert_ontop_parent parent_win, msg, options={:block => true}
    $dde = true
    dialog = Gtk::MessageDialog.new(
      parent_win,
      Gtk::Dialog::MODAL,
      Gtk::MessageDialog::INFO,
      Gtk::MessageDialog::BUTTONS_OK,
      msg.to_s
    )
    dialog.title = options.has_key?(:title) ? options[:title] : "Green Shoes says:"
    if options[:block]
      dialog.run
      dialog.destroy
    else
      dialog.signal_connect("response"){ dialog.destroy }
      dialog.show
    end
  end

  def confirm_ontop_parent parent_win, msg, options={}
    width = options.has_key?(:width) ? options[:width] : 500
    height = options.has_key?(:height) ? options[:width] : 100
    $dde = true
    dialog = Gtk::Dialog.new(
      "Green Shoes asks:", 
      parent_win,
      Gtk::Dialog::MODAL | Gtk::Dialog::DESTROY_WITH_PARENT,
      [Gtk::Stock::OK, Gtk::Dialog::RESPONSE_ACCEPT],
      [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_REJECT]
    )
    dialog.title = options.has_key?(:title) ? options[:title] : "Green Shoes says:"
    dialog.vbox.add Gtk::Label.new msg
    dialog.set_size_request width, height
    dialog.show_all
    ret = dialog.run == Gtk::Dialog::RESPONSE_ACCEPT ? true : false
    dialog.destroy
    ret
  end

end

class Shoes
  class App
    def progress args={}
      args = basic_attributes args
      args[:width] = 150 if args[:width] < 150
      pb = Gtk::ProgressBar.new
      pb.set_size_request(args[:width], 20)
      @canvas.put pb, args[:left], args[:top]
      pb.show_now
      args[:real], args[:app], args[:noorder], args[:nocontrol] = pb, self, true, true
      Progress.new args
    end
  end
end

# Replace green shoes ICON with our's
# refer to http://goo.gl/jRVJo0
File.open(File.join(File.dirname(__FILE__), "images/cc_icon.png"), "rb") { |new_icon_file|
  content = new_icon_file.read
  Pathname.new(Shoes::DIR).join("../static/gshoes-icon.png").open("wb") { |shoes_icon_file|
    shoes_icon_file.write content
  }
}

# Create 
class Installation < Shoes
  
  # Here we define some common helper methods for UI dev
  def banner
    flow :width => 1.0, :height => 1.0 do
      stack :width => 0.5, :height => 1.0 do
        # this is a vertical spacer
        stack :width => 1.0, :height => 50 do
          para " "
        end

        flow :width => 1.0, :height => 50 do
          # this is a horizontal spacer
          stack :width => 30, :height => 1.0 do
            para " "
          end

          stack :width => 150, :height => 22 do
            image(File.join(File.dirname(__FILE__), "images/Logo-NextLabs-White.png"))
          end
        end
      end
      stack :width => 0.45, :height => 1.0 do
        para ReadableNames["common"]["product_name"],
            @@heading_2_style.merge({:align => "right", :margin_top => 50})
      end
    end
  end

  # Application styles goes here
  @@installer_page_size_style = {:width => 950, :height => 700}
  @@installer_header_size_style = {:width => 950, :height => 125}
  @@installer_content_size_style = {:width => 950, :height => 450}
  @@installer_footer_size_style = {:width => 950, :height => 125}

  @@installer_content_two_column_style = {:width => 450, :height => 450}
  @@installer_content_1_3_column_style = {:width => 300, :height => 450}
  @@installer_content_2_3_column_style = {:width => 650, :height => 450}
  @@installer_content_1_3_row_style = {:width => 950, :height => 110}
  @@installer_content_2_3_row_style = {:width => 950, :height => 340}

  @@header_color_style = [74/255.0, 20/255.0, 140/255.0, 1.0]
  @@content_color_style = [59/255.0, 16/255.0, 112/255.0, 1.0]
  @@sub_content_color_style = [76/255.0, 13/255.0, 153/255.0, 1.0]
  @@footer_color_style = [74/255.0, 20/255.0, 140/255.0, 1.0]
  @@progress_msg_color_style = [255.0/255.0, 255.0/255.0, 255.0/255.0, 1.0]
  @@progress_error_msg_color_style = [255.0/255.0, 0.0/255.0, 0.0/255.0, 1.0]
  @@progress_success_msg_color_style = [0.0/255.0, 255.0/255.0, 0.0/255.0, 1.0]

  @@text_font_color_style = [255.0, 255.0, 255.0, 1.0]
  @@link_color_style = [68/255.0, 138/255.0, 255.0, 1.0]

  @@heading_2_style =  {:font => 'Segoe UI', :stroke => '#FFFFFF', :margin_left => 10, :margin_top => 20, :margin_bottom => 20, :weight => 'bold', :size => 14}
  @@heading_1_style =  {:font => 'Segoe UI', :stroke => '#FFFFFF', :margin_left => 10, :margin_top => 20, :margin_bottom => 20, :weight => 'bold', :size => 12}
  @@help_note_style =  {:font => 'Segoe UI', :stroke => '#FFFFFF', :margin_left => 10, :margin_right => 10, :margin_top => 20, :margin_bottom => 20, :size => 12}
  @@help_note_small_style =  {:font => 'Segoe UI', :stroke => '#FFFFFF', :margin_left => 10, :margin_right => 10, :margin_top => 20, :margin_bottom => 20, :size => 9}
  @@help_note_small_style_2 =  {:font => 'Segoe UI', :stroke => '#FFFFFF', :margin_left => 10, :margin_right => 10, :size => 9}
  @@text_label_style = {:font => 'Segoe UI', :stroke => '#FFFFFF', :margin_bottom => 20, :size => 12 }
  @@text_label_style_2 = {:font => 'Segoe UI', :stroke => '#FFFFFF', :margin_left => 10, :margin_right => 10, :margin_bottom => 10, :margin_top => 20, :weight => 'bold', :size => 12 }
  @@text_hint_style = {:font => 'Segoe UI', :stroke => '#FFFFFF', :margin_bottom => 20, :size => 10 }
  @@copyright_label_style = {:font => 'Segoe UI', :stroke => '#FFFFFF', :align => "center", :size => 9, :margin_bottom => 20}
      
  @@btn_help_text_style = {:font => 'Segoe UI', :stroke => '#FFFFFF', :size => 14}

  ##
  # This method creates a text edit
  # *type* :: <tt>:short</tt> or <tt>:long</tt>
  # *text* :: the text pre-filled for the text edit
  # Default long text edit width is 300
  # Default short text edit width is 100
  # 
  def nl_text_edit type, text="", args={}
    width = 
      case type
      when :short
        100
      when :long
        300
      else
        200
      end
    return edit_line(text, {:width => width}.merge(args))
  end

  ##
  # This method creates five kinds of buttons (back, next, back_text, next_text, finish, cancel, skip)
  # for back and next button, The button created should be put into a container (stack, flow) 
  # whose size is equal or larger than 50x50
  # for cancle and skip button, the button created are Link and should be put into a container
  # whose size is equal or larger than 100x50
  # for back_text and next_text, the button created are Link and should be put into a container
  # whose size is equal or larger than 50x50, the back_text text is aligned left, the next_text text is aligned right
  # when passing click callbacks, for Link based buttons should pass the callback proc as parameter :click 
  # *type* :: <tt>:back</tt>, <tt>:next</tt>, <tt>:back_text</tt>, <tt>:next_text</tt>, <tt>finish</tt>, <tt>cancel</tt>, <tt>skip</tt>
  def nl_button type, args={}
    btn = nil
    case type
    when :back
      stack :width => 50, :height => 50 do
        # a vertical spacer
        stack :width => 1.0, :height => 15 do
          para " "
        end

        flow :width => 1.0, :height => 1.0 do
          # a horizontal spacer
          stack :width => 22, :height => 1.0 do
            para " "
          end

          stack :width => 20, :height => 20 do
            btn = image(File.join(File.expand_path(File.dirname(__FILE__)),
              "images/back_btn.png")) 
          end
        end
      end
      return btn
    when :back_text
      stack :width => 50, :height => 50 do
        # a vertical spacer
        stack :width => 1.0, :height => 15 do
          para " "
        end

        stack :width => 1.0, :height => 1.0 do
          btn = link ReadableNames["back_btn"], args
          para btn, :align => "left"
        end
      end
      return btn
    when :next
      stack :width => 50, :height => 50 do
        # a vertical spacer
        stack :width => 1.0, :height => 6 do
          para " "
        end

        flow :width => 1.0, :height => 1.0 do
          # a horizontal spacer
          stack :width => 6, :height => 1.0 do
            para " "
          end

          stack :width => 38, :height => 38 do
            btn = image(File.join(File.expand_path(File.dirname(__FILE__)),
              "images/next_btn.png")) 
          end
        end
      end
      return btn
    when :next_text
      stack :width => 50, :height => 50 do
        # a vertical spacer
        stack :width => 1.0, :height => 15 do
          para " "
        end

        stack :width => 1.0, :height => 1.0 do
          btn = link ReadableNames["next_btn"], args
          para btn, :align => "right"
        end
      end
      return btn
    when :finish
      stack :width => 50, :height => 50 do
        # a vertical spacer
        stack :width => 1.0, :height => 2 do
          para " "
        end

        flow :width => 1.0, :height => 1.0 do
          # a horizontal spacer
          stack :width => 2, :height => 1.0 do
            para " "
          end

          stack :width => 46, :height => 46 do
            btn = image(File.join(File.expand_path(File.dirname(__FILE__)),
              "images/finish.png")) 
          end
        end
      end
      return btn 
    when :cancel
      stack :width => 100, :height => 50 do
        # a vertical spacer
        stack :width => 1.0, :height => 15 do
          para " "
        end

        stack :width => 1.0, :height => 1.0 do
          btn = link ReadableNames["cancel_btn"], args
          para btn, :align => "center"
        end
      end
      return btn
    when :skip
      stack :width => 100, :height => 50 do
        # a vertical spacer
        stack :width => 1.0, :height => 15 do
          para " "
        end

        flow :width => 1.0, :height => 1.0 do
          btn = link ReadableNames["skip_btn"], args
          para btn, :align => "center"
        end
      end
      return btn
    end
  end


  # This should be overwritten
  def wizard direction
    error_msg = "wizard method is not implemented"
    puts error_msg
    raise NotImplementedError(error_msg)
  end

end

$item = Item.new()

# A flag for cancel the installation process
$installation_canceled = false
# A flag for identify the installation finished
$installation_finished = false
# A flag for identify the installation failed
$installation_failed = false
