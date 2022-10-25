#! /usr/bin/env ruby
# encoding: utf-8
#
require_relative "../bootstrap"
require_relative "../utility"
include Utility

class Installation < Shoes

  url '/step1',        :step1

  STEP1_CONTROLS = [
    "server_ip",
    "server_type",
    "server_port"
  ]

  def step1
    
    style(Link, :underline => false, :stroke => "#FFF", :weight => "bold")
    style(LinkHover, :underline => false, :stroke => "#FFF", :weight => "bold")

    stack @@installer_page_size_style do
      
      
      # The header area
      stack @@installer_header_size_style do

        background @@header_color_style
        banner

      end
    
      # The main body
      stack @@installer_content_size_style do

        background @@content_color_style

        stack :width => 1.0, :height => 80 do
          # configuration information area
          para ReadableNames["step1_page"]["heading"],
              @@help_note_style
        end

        STEP1_CONTROLS.each do |contr|

          flow :width => 1.0, :height => 40 do
            
            # First the label
            stack :width => 300, :margin_left => 10, :margin_right => 10, 
                :margin_top => 10, :height => 1.0 do
               para ReadableNames["inputs"][contr],  @@text_label_style
            end

            stack :width => 350, :margin_left => 10, :margin_right => 10, 
                :margin_top => 10, :height => 1.0 do

              case contr
              when "server_type"
                @server_type_edit = list_box :items => Item::Server_types, :width => 200,
                    :choose => $item.server_type do

                  $item.server_type = @server_type_edit.text
                  # need to show the CATALINA_HOME control if the server type is TOMCAT
                  if $item.server_type.eql? "TOMCAT"
                    @CATALINA_HOME_label.show
                    @CATALINA_HOME_edit.show
                    @CATALINA_HOME_Choose_btn.show
                  else
                    @CATALINA_HOME_label.hide
                    @CATALINA_HOME_edit.hide
                    @CATALINA_HOME_Choose_btn.hide
                  end

                end
              when "server_ip"
                @server_ip_edit = nl_text_edit( :long, text=$item.instance_variable_get("@"+contr),
                    {:width => 350} )
                @server_ip_edit.change do
                  $item.server_ip = @server_ip_edit.text
                end
              when "server_port"
                @server_port_edit = nl_text_edit( :short, text=$item.server_port )
                @server_port_edit.change do
                  $item.server_port = @server_port_edit.text
                end
              end  

            end

          end

        end
        
        # The catalina home controls
        flow :width => 1.0, :height => 40 do

          stack :width => 300, :margin_left => 10, :margin_right => 10, 
              :margin_top => 10, :height => 1.0 do
            @CATALINA_HOME_label = para ReadableNames["inputs"]["CATALINA_HOME"], 
                @@text_label_style
          end

          stack :width => 350, :margin_left => 10, :margin_right => 10, 
              :margin_top => 10, :height => 1.0 do
            @CATALINA_HOME_edit = nl_text_edit( :long, text=$envs.CATALINA_HOME,
                {:width => 350} )
            
            # use "/" to be consistent
            @CATALINA_HOME_edit.change { 
              $envs.CATALINA_HOME = @CATALINA_HOME_edit.text.gsub("\\", "/")
            }
          end

          # this is a spacer
          stack :width => 15, :height => 1.0 do
            para " "
          end

          stack :width => 180, :margin_left => 10, :margin_right => 10,
              :margin_top => 10, :height => 1.0 do
              @CATALINA_HOME_Choose_btn = button ReadableNames["browse_folder_btn"] do
                # if user cancel the folder selection, ask_open_folder will reture nil
                # to prevent the nil being assigned to the variables, we need to check
                browse_result = ask_open_folder
                (@CATALINA_HOME_edit.text = browse_result) if browse_result != nil
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
            @step1_back_btn = nl_button :back
            @step1_back_btn.click { back_btn_click_proc.call }
          end

          stack :width => 50, :height => 1.0 do
            @step1_back_text_btn = nl_button :back_text, :click => back_btn_click_proc
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

          next_btn_click_lambda = lambda {

            # before we proceed, we need to check user input
            control_fields = {
              "server_ip"     => @server_ip_edit,
              "server_port"   => @server_port_edit,
              "CATALINA_HOME" => @CATALINA_HOME_edit
            }
            validated, field, error_msg = $item.validate_fields "server_ip", "server_port"

            if ($item.server_type.eql? "TOMCAT") and validated then
              validated, err_msg = Validator.validate_dir $envs.CATALINA_HOME
              field = "CATALINA_HOME"
              
              error_msg = ReadableNames["ErrorMsgTemplate"] % 
                  [ReadableNames["inputs"][field], err_msg]
              
            end

            if not validated then
              alert_ontop_parent(app.win, error_msg, :title => app.instance_variable_get('@title'))
              control_fields[field].focus
            else
              # before we procceed, we need to set policy_controller_host according to server_ip
              $item.policy_controller_host = $item.server_ip
              visit(self.wizard(:next))
            end
          }

          stack :width => 50, :height => 1.0 do
            @step1_next_text_btn = nl_button :next_text, :click => next_btn_click_lambda
          end

          stack :width => 50, :height => 1.0 do
            @step1_next_btn = nl_button :next
            @step1_next_btn.click { next_btn_click_lambda.call }
          end

        end

      end

    end

    # need to hide the CATALINA_HOME control if the server type is not TOMCAT
    unless $item.server_type.eql? "TOMCAT" then
      @CATALINA_HOME_label.hide
      @CATALINA_HOME_edit.hide
      @CATALINA_HOME_Choose_btn.hide
    end

  end

end

if __FILE__ == $0
  Shoes.app :title => ReadableNames["title"] , :width => 950, :height => 700 do
    win.set_size_request(950, 700)
    win.set_resizable(false)
    win.set_window_position(Gtk::Window::POS_CENTER_ALWAYS)
    visit('/step1')
  end
end
