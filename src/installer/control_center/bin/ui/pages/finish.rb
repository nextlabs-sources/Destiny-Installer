#! /usr/bin/env ruby
# encoding: utf-8
#
require_relative "../bootstrap"
require_relative "../utility"
include Utility

class Installation < Shoes

  url '/finish',             :finish

  def finish 
    stack @@installer_page_size_style do
      
      
      # The header area
      stack @@installer_header_size_style do

        background @@header_color_style
        banner

      end

      # The body
      stack @@installer_content_size_style do

        background @@content_color_style

        stack :width => 1.0, :height => 80 do
          if $installation_canceled
            para_text = ReadableNames["finish_page"]["aborted_body"]
          elsif $installation_finished
            if $item.installation_mode == "install"
              para_text = ReadableNames["finish_page"]["install_finish_body"]
            elsif $item.installation_mode == "remove"
              para_text = ReadableNames["finish_page"]["remove_finish_body"]
            elsif $item.installation_mode == "upgrade"
              para_text = ReadableNames["finish_page"]["upgrade_finish_body"]
            end
          else
            para_text = ReadableNames["finish_page"]["failed_body"]
          end
          para para_text,  @@help_note_style
        end

        # post-installation options (start service)
        if $installation_finished && ($item.installation_mode == 'install' || $item.installation_mode == 'upgrade')
          flow :width => 1.0, :height => 200 do
            # a horizontal spacer
            stack :width => 50, :height => 1.0 do
              para " "
            end
            @start_service_check = check
            para ReadableNames["finish_page"]["start_service"], @@text_label_style.merge({:width => 400})
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

          stack :width => 50, :height => 1.0 do
            # Finish page don't have back btn (there's no turning back)
            para " "
          end

          # This is a horizontal spacer
          stack :width => 790, :height => 1.0 do
            para " "
          end

          stack :width => 50, :height => 1.0 do
            @finish_btn = nl_button :finish
            @finish_btn.click do
              if $installation_finished && ($item.installation_mode == 'install' || $item.installation_mode == 'upgrade')
                if @start_service_check.checked?
                  Utility::start_service
                end
              end
              exit
            end
          end

        end

      end

    end

    # initialize the check box
    if self.instance_variable_defined? "@start_service_check"
      @start_service_check.checked = true
    end

  end

end

if __FILE__ == $0
  Shoes.app :title => ReadableNames["title"] , :width => 950, :height => 700 do
    win.set_size_request(950, 700)
    win.set_resizable(false)
    win.set_window_position(Gtk::Window::POS_CENTER_ALWAYS)
    $item.installation_mode = "upgrade"
    $installation_finished = true
    visit('/finish')
  end
end