#! /usr/bin/env ruby
# encoding: utf-8
#
require_relative '../bootstrap'
require_relative '../utility'
include Utility

class Installation < Shoes

  url '/installation_mode',             :installation_mode

  def installation_mode
    style(Link, :underline => false, :stroke => '#FFF', :weight => 'bold')
    style(LinkHover, :underline => false, :stroke => '#FFF', :weight => 'bold')

    stack @@installer_page_size_style do
            
      # The header area
      stack @@installer_header_size_style do

        background @@header_color_style
        banner

      end

      # The body
      stack @@installer_content_size_style do

        background @@content_color_style

        stack :width => 1.0, :height => 60 do
          para ReadableNames['installation_mode_page']['heading'], @@heading_1_style
        end
        
        # only enable uninstall UI elements if major version and minor version are equal
        if Server::Config.get_current_server_version($node) == $node['version_number']
          stack :width => 1.0, :margin_left => 10, :margin_top => 10, :height => 150 do

            flow :width => 1.0, :height => 30 do
              @installation_mode_radio_remove = radio :installation_mode_radio

              para((link ReadableNames['installation_mode_page']['remove_radio'] {
                @installation_mode_radio_remove.checked = true
              }), @@text_label_style.merge({:width => 100}))

              @installation_mode_radio_remove.click {
                $item.installation_mode = 'remove'
              }

            end

            stack :width => 1.0, :height => 120 do
              para ReadableNames['installation_mode_page']['existing_server_version_template'] %
                       strong(Server::Config.get_current_server_version($node)),
                   @@help_note_style.merge({:margin_top => 0, :margin_left => 20})
              para ReadableNames['installation_mode_page']['existing_server_location_template'] %
                       strong(Server::Config.get_current_installation_dir($node)),
                   @@help_note_style.merge({:margin_top => 0, :margin_left => 20})
            end

          end

        else

          if $node['console_install_mode'] == "OPL"
            stack :width => 1.0, :margin_left => 10, :margin_top => 10, :height => 150 do
              para ReadableNames['installation_mode_page']['not_upgradable_help_note'] %
                  [strong(Server::Config.get_current_server_version($node)),
                   strong($node['version_number'])], @@help_note_style.merge({:margin_top => 0, :margin_left => 20})
            end

          else

            if Server::Config.server_version_newer?(Server::Config.get_current_server_version($node),
                $node['version_number'])

                stack :width => 1.0, :margin_left => 10, :margin_top => 10, :height => 150 do

                  flow :width => 1.0,  :height => 30 do
                    @installation_mode_radio_upgrade = radio :installation_mode_radio

                    @installation_mode_para_upgrade = para (link ReadableNames['installation_mode_page']['upgrade_radio'] {
                      @installation_mode_radio_upgrade.checked = true
                    }), @@text_label_style.merge({:width => 100})

                    @installation_mode_radio_upgrade.click {
                      $item.installation_mode = 'upgrade'
                    }

                  end

                  stack :width => 1.0, :height => 120 do
                    para ReadableNames['installation_mode_page']['existing_server_version_template'] %
                             strong(Server::Config.get_current_server_version($node)),
                         @@help_note_style.merge({:margin_top => 0, :margin_left => 20})
                    para ReadableNames['installation_mode_page']['existing_server_location_template'] %
                             strong(Server::Config.get_current_installation_dir($node)),
                         @@help_note_style.merge({:margin_top => 0, :margin_left => 20})
                    para ReadableNames['installation_mode_page']['installer_version_template'] %
                             strong($node['version_number']),
                         @@help_note_style.merge({:margin_top => 0, :margin_left => 20})
                  end

                end

            end
    
            # show error message if remove and upgrade are both not supported
            if Server::Config.server_version_newer?($node['version_number'], Server::Config.get_current_server_version($node))
              stack :width => 1.0, :margin_left => 10, :margin_top => 10, :height => 150 do
                para ReadableNames['installation_mode_page']['not_supported_help_note'] %
                    [strong(Server::Config.get_current_server_version($node)),
                     strong($node['version_number'])], @@help_note_style.merge({:margin_top => 0, :margin_left => 20})
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
          para ' '
        end

        flow :width => 1.0, :height => 50 do
          # This is a horizontal spacer
          stack :width => 30, :height => 1.0 do
            para ' '
          end

          back_btn_click_proc = Proc.new{
            # here prompt user to stop server if it's running
            visit(wizard(:back))
          }

          stack :width => 50, :height => 1.0 do
            @installation_mode_back_btn = nl_button :back
            @installation_mode_back_btn.click { back_btn_click_proc.call }
          end

          stack :width => 50, :height => 1.0 do
            @installation_mode_back_text_btn = nl_button :back_text, :click => back_btn_click_proc
          end

          stack :width => 100, :height => 1.0 do
            
            cancel_btn_click_proc = Proc.new{
              if confirm_ontop_parent(app.win, ReadableNames['cancel_confirm'],
                  :title=> app.instance_variable_get('@title')) then
                exit
              end
            }

            nl_button :cancel, :click => cancel_btn_click_proc

          end

          # This is a horizontal spacer
          stack :width => 590, :height => 1.0 do
            para ' '
          end

          logqueue_folder_empty_check_proc = Proc.new {
            logqueue_folder = ::File.join(Server::Config.get_current_installation_dir($node), 'server', 'logqueue')
            if Dir["#{logqueue_folder}/*"].empty?
              visit(wizard(:next))
            else
              alert_ontop_parent(app.win, ReadableNames['installation_mode_page']['logqueue_not_empty'],
                                 :title => app.instance_variable_get('@title'))
            end
          }

          next_btn_click_proc = Proc.new {
            # check server running here
            if Server::Config.detect_service_running?($node)
              if confirm_ontop_parent(app.win, ReadableNames['installation_mode_page']['server_running_alert'] ,
                                      :title => app.instance_variable_get('@title'))
                if Server::Config.stop_service($node)
                  if $item.installation_mode == 'upgrade'
                    logqueue_folder_empty_check_proc.call
                  else
                    visit(wizard(:next))
                  end
                else
                  alert_ontop_parent(app.win, ReadableNames['installation_mode_page']['server_stop_error'],
                                     :title => app.instance_variable_get('@title'))
                end
              end
            else
              if $item.installation_mode == 'upgrade'
                logqueue_folder_empty_check_proc.call
              else
                visit(wizard(:next))
              end
            end
          }

          @installation_mode_next_text_btn_stack = stack :width => 50, :height => 1.0 do
            @installation_mode_next_text_btn = nl_button :next_text, :click => next_btn_click_proc
          end

          stack :width => 50, :height => 1.0 do
            @installation_mode_next_btn = nl_button :next
            @installation_mode_next_btn.click { next_btn_click_proc.call }
          end

        end

      end

    end

    # initialize the radio buttons and $item value
    if Server::Config.server_version_newer?(Server::Config.get_current_server_version($node),
        $node['version_number'])
        # hide the next btn stacks if remove and upgrade are both not supported
        if $node['console_install_mode'] == "OPL"
          $item.installation_mode = nil
          @installation_mode_next_btn.hide
          @installation_mode_next_text_btn_stack.hide
        else
          @installation_mode_radio_upgrade.checked = true
          $item.installation_mode = 'upgrade'
        end
    elsif Server::Config.get_current_server_version($node).to_f() == $node['version_number'].to_f()
      @installation_mode_radio_remove.checked = true
      $item.installation_mode = 'remove'
    else
      $item.installation_mode = nil
      @installation_mode_next_btn.hide
      @installation_mode_next_text_btn_stack.hide
    end

  end

end

if __FILE__ == $0

  # for development, override the method
  module Server
    module Config
      def self.get_current_server_version(node)
        return $node['version_number']
      end

      def self.get_current_installation_dir(node)
        return 'C:/Program Files/Nextlabs/PolicyServer'
      end
    end
  end

  Shoes.app :title => ReadableNames['title'] , :width => 950, :height => 700 do
    win.set_size_request(950, 700)
    win.set_resizable(false)
    win.set_window_position(Gtk::Window::POS_CENTER_ALWAYS)
    visit('/installation_mode')
  end
end
