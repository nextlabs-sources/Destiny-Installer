#! /usr/bin/env ruby
# encoding: utf-8
#
require_relative "../bootstrap"
require_relative "../utility"
include Utility

class Installation < Shoes

  url '/setup_type',         :setup_type

  def setup_type
    # changes the link style and link hover style
    style(Link, :underline => false, :stroke => "#FFF", :weight => "bold")
    style(LinkHover, :underline => false, :stroke => "#FFF", :weight => "bold")

    stack @@installer_page_size_style do

      # The header area
      stack @@installer_header_size_style do

        background @@header_color_style
        banner

      end

      # The body
      flow @@installer_content_size_style do

        background @@content_color_style

        # stack :width => 1.0, :height => 40 do
        #   para ReadableNames["setup_type_page"]["heading"], @@heading_1_style 
        # end

        # Left side of the body, contains a radio button group for selecting setup type
        stack @@installer_content_1_3_column_style do

          stack :width => 1.0, :height => 60 do
            para ReadableNames["setup_type_page"]["field_label"], @@heading_1_style
          end
          
          stack :width => 1.0, :margin_left => 10, :margin_top => 10, :height => 200 do

            flow :width => 1.0, :height => 40 do
              @setup_type_radio_complete = radio :setup_type_radio
              para (link ReadableNames["setup_type_page"]["complete_radio"] { @setup_type_radio_complete.checked = true }),
                  @@text_label_style.merge({:width => 100}) 

              @setup_type_radio_complete.click {
                # need to check the click effect before doing anything
                if @setup_type_radio_complete.checked?()
                  $item.installation_type = "complete"
                  @setup_type_module_selection_stack.hide
                end
              }
            end

            stack :width => 1.0, :height => 60 do
              para ReadableNames["setup_type_page"]["complete_help_note"], @@help_note_small_style
            end

          end

          stack :width => 1.0, :margin_left => 10, :margin_top => 10, :height => 50 do

            flow :width => 1.0,  :height => 40 do
              @setup_type_radio_custom = radio :setup_type_radio
              para (link ReadableNames["setup_type_page"]["custom_radio"] { @setup_type_radio_custom.checked = true}),
                  @@text_label_style.merge({:width => 100})

              @setup_type_radio_custom.click {
                if @setup_type_radio_custom.checked?()
                  $item.installation_type = "custom"
                  @setup_type_module_selection_stack.show
                end
              }
            end

            stack :width => 1.0, :height => 60 do
              para ReadableNames["setup_type_page"]["custom_help_note"], @@help_note_small_style
            end

          end

        end

        # Right side of the body
        @setup_type_module_selection_stack = stack @@installer_content_2_3_column_style do

        stack :width => 1.0, :height => 50 do
            para ReadableNames["setup_type_page"]["module_selection_heading"],  @@heading_1_style
        end

        stack :width => 1.0, :margin_left => 10 do

          Item::SETUP_COMPONENTS.each do |component|

            flow :width => 1.0 do
              @c = check
              @c.checked = true if ( $item.instance_variable_get("@"+component) == "ON" )
              para ReadableNames["inputs"][component], @@text_label_style.merge({:width => 300, :margin_bottom => 13})
              @c.click do |c_self|
                new_value = c_self.checked? ? "ON" : "OFF"
                $item.instance_variable_set("@"+component, new_value)
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
            # before we procceed, we need to check setup_type
            # if custom setup is checked but all components are selected,
            # then set installation_type to complete
            if Item::SETUP_COMPONENTS.reject {
                |item| $item.instance_variable_get("@"+item) == "ON" }.empty?
              $item.installation_type = "complete"
            end
            visit(wizard(:back))
          }

          stack :width => 50, :height => 1.0 do
            @setup_type_back_btn = nl_button :back
            @setup_type_back_btn.click { back_btn_click_proc.call }
          end

          stack :width => 50, :height => 1.0 do
            @setup_type_back_text_btn = nl_button :back_text, :click => back_btn_click_proc
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
            # before we procceed, we need to check setup_type
            # if custom setup is checked but all components are selected,
            # then set installation_type to complete
            if Item::SETUP_COMPONENTS.reject {
                |item| $item.instance_variable_get("@"+item) == "ON" }.empty?
              $item.installation_type = "complete"
            else
              # make sure the installation_type is set correctly
              $item.installation_type = "custom"
            end

            # if completed setup type is checked, then mark all components as ON
            if @setup_type_radio_complete.checked?
              Item::SETUP_COMPONENTS.each do |component|
                $item.instance_variable_set("@"+component, "ON")
              end
            end

            # from 8.7 onwards, there is only OPN mode
            $item.console_install_mode = 'OPN'

            # if dms is unselected (icenet type installation), clear console_install_mode
            if $item.dms_component.eql?('OFF')
              $item.console_install_mode = ''
            end

            visit(wizard(:next))
          }

          stack :width => 50, :height => 1.0 do
            @setup_type_next_text_btn = nl_button :next_text, :click => next_btn_click_proc
          end

          stack :width => 50, :height => 1.0 do
            @setup_type_next_btn = nl_button :next
            @setup_type_next_btn.click { next_btn_click_proc.call }
          end

        end

      end

    end

    # Initialize the radio status
    if $item.installation_type == "custom"
      @setup_type_radio_custom.checked = true
    else
      @setup_type_radio_complete.checked = true
    end

  end

end

if __FILE__ == $0
  Shoes.app :title => ReadableNames["title"] , :width => 950, :height => 700 do
    win.set_size_request(950, 700)
    win.set_resizable(false)
    win.set_window_position(Gtk::Window::POS_CENTER_ALWAYS)
    visit('/setup_type')
  end
end