#! /usr/bin/env ruby
# encoding: utf-8
#
require_relative "../bootstrap"
require_relative "../utility"
include Utility

class Installation < Shoes

  url "/data_transportation",         :data_transportation

  DATA_TRANSPORTATION_CONTROLS = %w[
    data_transportation_shared_key
  ]

  def data_transportation

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

        # Plain text section
        stack @@installer_content_1_3_row_style do

          stack :width => 1.0, :height => 40 do
            para ReadableNames["data_transportation_page"]["heading"], @@heading_1_style
          end

          stack :width => 1.0, :margin_left => 10, :margin_top => 20, :height => 40 do
            flow :width => 1.0, :height => 10 do
              @data_transportation_radio_plain = radio :data_transportation_radio
              para (link ReadableNames["data_transportation_page"]["plain_radio"] { @data_transportation_radio_plain.checked = true }),
                  @@text_label_style.merge({:width => 200}) 

              @data_transportation_radio_plain.click {
                # need to check the click effect before doing anything
                if @data_transportation_radio_plain.checked?()
                  $item.data_transportation_mode = "PLAIN"

                  # clear and disable shared key
                  @data_transportation_shared_key_edit.text = ""
                  @data_transportation_shared_key_edit.state = "disabled"

                  # disable generate button
                  @data_transportation_generate_button.state = "disabled"

                  # clear and disable SANDE check boxes
                  @data_transportation_import_plain.state = "disabled"
                  @data_transportation_import_plain.checked = false
                  $item.data_transportation_plain_text_import = "false"
                  @data_transportation_export_plain.state = "disabled"
                  @data_transportation_export_plain.checked = false
                  $item.data_transportation_plain_text_export = "false"
                end
              }
            end

            stack :width => 1.0, :margin_left => 30, :height => 10 do
              para ReadableNames["data_transportation_page"]["plain_note"], @@help_note_small_style
            end

          end

        end

        # Signed and encrypted section
        stack @@installer_content_2_3_row_style do

          stack :width => 1.0, :margin_left => 10, :margin_top => 70, :height => 40 do
            flow :width => 1.0, :height => 10 do
              @data_transportation_radio_sande = radio :data_transportation_radio
              para (link ReadableNames["data_transportation_page"]["sande_radio"] { @data_transportation_radio_sande.checked = true }),
                  @@text_label_style.merge({:width => 600}) 

              @data_transportation_radio_sande.click {
                # need to check the click effect before doing anything
                if @data_transportation_radio_sande.checked?()
                  $item.data_transportation_mode = "SANDE"

                  # enable shared key text box
                  @data_transportation_shared_key_edit.state = nil

                  # enable generate button
                  @data_transportation_generate_button.state = nil

                  # enable SANDE check boxes
                  @data_transportation_import_plain.state = nil
                  @data_transportation_export_plain.state = nil
          
                  @data_transportation_shared_key_edit.focus
                end
              }

              stack :width => 1.0, :margin_left => 30 do
                para ReadableNames["data_transportation_page"]["sande_note_1"], @@help_note_small_style_2
                para ReadableNames["data_transportation_page"]["sande_note_2"], @@help_note_small_style_2
              end

            end

            stack :width => 1.0, :margin_left => 30 do
              para ReadableNames["data_transportation_page"]["shared_key"], @@text_label_style_2.merge({:width => 650})
              # Secret key
              flow :width => 1.0, :height => 30, :margin_left => 10 do

                stack :width => 510, :margin_right => 10, :height => 1.0 do
                  @data_transportation_shared_key_edit = nl_text_edit( :long, text=$item.data_transportation_shared_key, { :width => 500 } )
                  self.instance_variable_set( "@data_transportation_shared_key_edit", @data_transportation_shared_key_edit)

                end

                stack :width => 100, :margin_right => 10, :height => 1.0 do
                  @data_transportation_generate_button = button ReadableNames["generate_btn"] do
                    begin
                      @data_transportation_shared_key_edit.text = KeyGen.generate_key("AES", "256", 15)

                    rescue Exception => e
                      error_msg = ReadableNames["data_transportation_page"]["generate_key_failed_template"] % e.message
                    end

                  end

                end

              end

              # Allow import/export check boxes
              flow :width => 900, :height => 40, :margin_left => 10 do
                # Allow import plain text data
                @data_transportation_import_plain = check({ :margin_top => 15})
                @data_transportation_import_plain.checked = true if ( $item.data_transportation_plain_text_import == "true" )
                para ReadableNames["data_transportation_page"]["allow_import_plain_text"], @@help_note_small_style_2.merge({:width => 850, :margin_top => 18, :margin_left => 10})
                @data_transportation_import_plain.click do
                  $item.data_transportation_plain_text_import  = @data_transportation_import_plain.checked? ? "true" : "false"
                end
        
                # Allow export plain text data
                @data_transportation_export_plain = check({ :margin_top => 10})
                @data_transportation_export_plain.checked = true if ( $item.data_transportation_plain_text_export == "true" )
                para ReadableNames["data_transportation_page"]["allow_export_plain_text"], @@help_note_small_style_2.merge({:width => 850, :margin_top => 13, :margin_left => 10})
                @data_transportation_export_plain.click do
                  $item.data_transportation_plain_text_export  = @data_transportation_export_plain.checked? ? "true" : "false"
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
            visit(wizard(:back))
          }

          stack :width => 50, :height => 1.0 do
            @data_transportation_back_btn = nl_button :back
            @data_transportation_back_btn.click { back_btn_click_proc.call }
          end

          stack :width => 50, :height => 1.0 do
            @data_transportation_back_text_btn = nl_button :back_text, :click => back_btn_click_proc
          end

          stack :width => 100, :height => 1.0 do
            cancel_btn_click_proc = Proc.new{
              if confirm_ontop_parent(app.win, ReadableNames["cancel_confirm"],
                  :title=> app.instance_variable_get("@title")) then
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
            validated = true

            # Check if data_transportation_mode is PLAIN,
            # clear shared key field
            if $item.data_transportation_mode.eql?("PLAIN")
              @data_transportation_shared_key_edit.text = ""
              $item.data_transportation_shared_key = ""
              $item.data_transportation_plain_text_import = "false"
              $item.data_transportation_plain_text_export = "false"

            else
              # First populate the instance variables of items
              DATA_TRANSPORTATION_CONTROLS.each do |contr|
                $item.instance_variable_set("@"+contr, \
                  self.instance_variable_get("@#{contr}_edit").text)
              end

              control_fields = {}
              DATA_TRANSPORTATION_CONTROLS.each do |contr|
                control_fields[contr] = self.instance_variable_get("@#{contr}_edit")
              end

              validated, field, error_msg = $item.validate_fields *DATA_TRANSPORTATION_CONTROLS
              if ! validated
                alert_ontop_parent(app.win, error_msg, :title => app.instance_variable_get("@title"))
                control_fields[field].focus
              else
                $item.data_transportation_shared_key = self.instance_variable_get( "@data_transportation_shared_key_edit" ).text
              end

            end
            
            if validated
              visit(wizard(:next))
            end
          }

          stack :width => 50, :height => 1.0 do
            @data_transportation_next_text_btn = nl_button :next_text, :click => next_btn_click_proc
          end

          stack :width => 50, :height => 1.0 do
            @data_transportation_next_btn = nl_button :next
            @data_transportation_next_btn.click { next_btn_click_proc.call }
          end

        end

      end

    end

    # Initialize the radio status
    if $item.data_transportation_mode == "SANDE"
      @data_transportation_radio_sande.checked = true
    else
      @data_transportation_radio_plain.checked = true
    end
    
  end

end

if __FILE__ == $0
  Shoes.app :title => ReadableNames["title"] , :width => 950, :height => 700 do
    # disable the window from resized by the user
    # refer to http://goo.gl/H6m1rZ
    win.set_size_request(950, 700)
    win.set_resizable(false)
    win.set_window_position(Gtk::Window::POS_CENTER_ALWAYS)
    visit("/data_transportation")
  end

end
