#! /usr/bin/env ruby
# encoding: utf-8
#
require_relative '../bootstrap'
require_relative '../utility'
include Utility

class Installation < Shoes

  url '/db',             :db
  
  DATABASE_SERVER_CONTROLS = %w[
    db_hostname
    db_port
    db_name
    db_username
    db_password
  ]
  
  def db

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
        flow :width => 1.0, :height => 1.0 do
          # left side of the body, contains main behavioral properties
          stack @@installer_content_1_3_column_style do
            background @@content_color_style

            stack :width => 1.0, :height => 40 do
              para ReadableNames["db_page"]["heading"], @@heading_1_style
            end

            flow :width => 1.0, :height => 60 do
              Item::DATABASE_TYPES.each do |db_type|
                stack :width => 0.5, :margin_left => 10, :margin_top => 10, :height => 60 do

                  flow :width => 1.0 do
                    stack :width => 0.2, :margin_top => 10 do
                      # set the radio to instance variable "{db_type}_radio"
                      self.instance_variable_set("@#{db_type}_radio", (radio :db_type_radio))
                    end  

                    stack :width => 0.8, :margin_top => 10 do
                      para (link ReadableNames["db_page"][db_type] {
                        self.instance_variable_get("@#{db_type}_radio").checked = true
                      }), @@text_label_style.merge({:width => 200})

                      self.instance_variable_get("@#{db_type}_radio").click do |r_self|
                        if r_self.checked? then
                          if $item.database_type != db_type
                            $item.database_type = db_type
                            self.instance_variable_get("@db_port_edit").text = Item::DATABASE_DEFAULT_PORTS[db_type + "_PORT"]
                            if @db_ssl_connection_check.checked?
                              if @db_validate_server_check.checked?
                                $item.db_connection_url_template = Item::DB_CONNECTION_URL_TEMPLATES[$item.database_type + "_SSL_VALIDATE"]
                              else
                                $item.db_connection_url_template = Item::DB_CONNECTION_URL_TEMPLATES[$item.database_type + "_SSL"]
                              end
                            else
                              $item.db_connection_url_template = Item::DB_CONNECTION_URL_TEMPLATES[$item.database_type]
                            end
                            
                            if @db_ssl_connection_check.checked?
                              if db_type == "ORACLE"
                                @db_ssl_certificate_edit.state = nil
                                @browse_ssl_certificate_btn.state = nil
                              else
                                if !@db_validate_server_check.checked?
                                  @db_ssl_certificate_edit.text = ""
                                  @db_ssl_certificate_edit.state = "disabled"
                                  @browse_ssl_certificate_btn.state = "disabled"
                                end
                              end
                            end
                          end
                        end
                      end
                    end
                  end
                end
              end

              stack :width => 1.0, :height => 30 do
                flow :width => 1.0, :height => 1.0 do
                  @db_ssl_connection_check = check({ :margin_left => 10})
                  @db_ssl_connection_check.checked = false
                  @db_ssl_connection_check.checked = true if ( $item.db_ssl_connection == "true" )
                  para ReadableNames["db_page"]["ssl_connection"], @@text_label_style.merge({:width => 200, :margin_left => 10})
                  @db_ssl_connection_check.click do |c_self|
                    if c_self.checked? then
                      $item.db_ssl_connection = "true"
                      if $item.database_type == "ORACLE"
                        @db_ssl_certificate_edit.state = nil
                        @browse_ssl_certificate_btn.state = nil
                      end
                      @db_validate_server_check.state = nil
                      $item.db_connection_url_template = Item::DB_CONNECTION_URL_TEMPLATES[$item.database_type + "_SSL"]
                    else
                      $item.db_ssl_connection = "false"
                      $item.db_validate_server = "false"
                      @db_validate_server_check.checked = false
                      @db_ssl_certificate_edit.text = ""
                      @db_ssl_certificate_edit.state = "disabled"
                      @browse_ssl_certificate_btn.state = "disabled"
                      @db_validate_server_check.state = "disabled"
                      $item.db_connection_url_template = Item::DB_CONNECTION_URL_TEMPLATES[$item.database_type]
                    end
                  end
                end
              end

              stack :width => 1.0, :height => 30 do
                flow :width => 1.0, :height => 1.0 do
                  @db_validate_server_check = check({ :margin_left => 40, :state => "disabled"})
                  @db_validate_server_check.checked = false
                  @db_validate_server_check.checked = true if ( $item.db_validate_server == "true" )
                  para ReadableNames["db_page"]["validate_server"], @@text_label_style.merge({:width => 200, :margin_left => 10})
                  @db_validate_server_check.click do |c_self|
                    if c_self.checked? then
                      $item.db_validate_server = "true"
                      @db_ssl_certificate_edit.state = nil
                      @browse_ssl_certificate_btn.state = nil
                      @db_server_dn_edit.state = nil
                      $item.db_connection_url_template = Item::DB_CONNECTION_URL_TEMPLATES[$item.database_type + "_SSL_VALIDATE"]
                    else
                      $item.db_validate_server = "false"
                      if $item.database_type == "MSSQL"
                        @db_ssl_certificate_edit.text = ""
                        @db_ssl_certificate_edit.state = "disabled"
                        @browse_ssl_certificate_btn.state = "disabled"
                      end
                      @db_server_dn_edit.text = ""
                      @db_server_dn_edit.state = "disabled"
                      $item.db_connection_url_template = Item::DB_CONNECTION_URL_TEMPLATES[$item.database_type + "_SSL"]
                    end
                  end
                end
              end
            end
          end

          # right side of the body, contains parameter fields to collect values
          stack @@installer_content_2_3_column_style do
            background @@sub_content_color_style

            stack :width => 1.0, :height => 280 do
              stack :width => 1.0, :height => 40 do
                @db_help_note_para = para ReadableNames["db_page"]["help_note"], @@heading_1_style
              end

              flow :width => 1.0, :height => 40 do
                stack :width => 175, :height => 1.0, :margin_top => 20, :margin_left => 10, :margin_right => 10 do
                  para ReadableNames["db_page"]["hostname"], @@text_label_style
                end
                stack :width => 225, :height => 1.0, :margin_top => 20 do
                  text_edit_params = {:width => 225}
                  self.instance_variable_set("@db_hostname_edit", nl_text_edit(:long, text=$item.db_hostname, text_edit_params))
                end

                stack :width => 120, :height => 1.0, :margin_top => 20, :margin_left => 20, :margin_right => 10 do
                  para ReadableNames["db_page"]["port"], @@text_label_style
                end
                stack :width => 80, :height => 1.0, :margin_top => 20 do
                  text_edit_params = {:width => 80}
                  self.instance_variable_set("@db_port_edit", nl_text_edit(:long, text=$item.db_port, text_edit_params))
                end

                stack :width => 175, :height => 1.0, :margin_top => 20, :margin_left => 10, :margin_right => 10 do
                  para ReadableNames["db_page"]["name"], @@text_label_style
                end
                stack :width => 425, :height => 1.0, :margin_top => 20 do
                  text_edit_params = {:width => 425}
                  self.instance_variable_set("@db_name_edit", nl_text_edit(:long, text=$item.db_name, text_edit_params))
                end

                stack :width => 175, :height => 1.0, :margin_top => 20, :margin_left => 10, :margin_right => 10 do
                  para ReadableNames["db_page"]["username"], @@text_label_style
                end
                stack :width => 425, :height => 1.0, :margin_top => 20 do
                  text_edit_params = {:width => 425}
                  self.instance_variable_set("@db_username_edit", nl_text_edit(:long, text=$item.db_username, text_edit_params))
                end

                stack :width => 175, :height => 1.0, :margin_top => 20, :margin_left => 10, :margin_right => 10 do
                  para ReadableNames["db_page"]["password"], @@text_label_style
                end
                stack :width => 425, :height => 1.0, :margin_top => 20 do
                  text_edit_params = {:width => 425, :secret => true}
                  self.instance_variable_set("@db_password_edit", nl_text_edit(:long, text=$item.db_password, text_edit_params))
                end

                stack :width => 175, :height => 1.0, :margin_top => 20, :margin_left => 10, :margin_right => 10 do
                  para ReadableNames["db_page"]["ssl_certificate"], @@text_label_style
                end
                stack :width => 365, :height => 1.0, :margin_top => 20 do
                  text_edit_params = {:width => 365}
                  self.instance_variable_set("@db_ssl_certificate_edit", nl_text_edit(:long, text=$item.db_ssl_certificate, text_edit_params))
                end
                stack :width => 60, :margin_left => 10, :margin_right => 10, :margin_top => 20, :height => 1.0 do
                  @browse_ssl_certificate_btn = button ReadableNames["browse_file_btn"] do
                    # if user cancel the folder selection, ask_open_folder will return nil
                    # to prevent the nil being assigned to the variables, we need to check
                    browse_result = ask_open_file
                    (@db_ssl_certificate_edit.text = browse_result) if browse_result != nil
                  end
                end

                stack :width => 175, :height => 1.0, :margin_top => 20, :margin_left => 10, :margin_right => 10 do
                  para ReadableNames["db_page"]["server_dn"], @@text_label_style
                end
                stack :width => 425, :height => 1.0, :margin_top => 20 do
                  text_edit_params = {:width => 425}
                  self.instance_variable_set("@db_server_dn_edit", nl_text_edit(:long, text=$item.db_server_dn, text_edit_params))
                end
              end 
            end

            @db_validate_server_check.state = @db_ssl_connection_check.checked? ? nil : "disabled"
            
            if @db_ssl_connection_check.checked? && $item.database_type == "ORACLE"
              @db_ssl_certificate_edit.state = nil
              @browse_ssl_certificate_btn.state = nil
            else
              @db_ssl_certificate_edit.state = "disabled"
              @browse_ssl_certificate_btn.state = "disabled"
            end
            
            if @db_validate_server_check.checked?
              @db_server_dn_edit.state = nil
            else
              @db_server_dn_edit.state = "disabled"
            end
            
            # this is a vertical spacer
            stack :width => 1.0, :height => 20 do
              para " "
            end

            flow :width => 1.0, :height => 50 do
              # this is a horizontal spacer
              stack :width => 175, :height => 1.0 do
                para " "
              end
              stack :width => 100, :height => 1.0 do
                button ReadableNames["db_page"]["test_connnection_btn"] {
                  begin
                    connection_url = $item.db_connection_url_template.dup()
                    connection_url["\<HOSTNAME\>"] = self.instance_variable_get("@db_hostname_edit").text.strip
                    connection_url["\<PORT\>"] = self.instance_variable_get("@db_port_edit").text.strip
                    connection_url["\<INSTANCE_NAME\>"] = self.instance_variable_get("@db_name_edit").text.strip
                    if @db_validate_server_check.checked?
                      connection_url["\<HOST_DN\>"] = self.instance_variable_get("@db_server_dn_edit").text.strip
                    end

                    db_connection_result = DB.test_db_connection(
                      connection_url.gsub('"', '\"'),
                      self.instance_variable_get("@db_username_edit").text.strip,
                      self.instance_variable_get("@db_password_edit").text,
                      self.instance_variable_get("@db_ssl_certificate_edit").text.strip == "" ? "NA" : self.instance_variable_get("@db_ssl_certificate_edit").text.strip,
                      self.instance_variable_get("@db_server_dn_edit").text.strip,
                      30
                    )
                  rescue Exception => e
                    db_connection_result = false
                    msg = ReadableNames["db_page"]["test_connnection_failed_template"] % e.message
                  end

                  if db_connection_result
                    msg = ReadableNames["db_page"]["test_connnection_success"]
                  else
                    msg = (ReadableNames["db_page"]["test_connnection_failed_template"] % '') if msg == nil
                  end
                  alert_ontop_parent(app.win, msg, :title => app.instance_variable_get('@title'))
                }
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
            @db_back_btn = nl_button :back
            @db_back_btn.click { back_btn_click_proc.call }
          end

          stack :width => 50, :height => 1.0 do
            @db_back_text_btn = nl_button :back_text, :click => back_btn_click_proc
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
            $item.db_hostname = @db_hostname_edit.text.strip
            $item.db_port = @db_port_edit.text.strip
            $item.db_name = @db_name_edit.text.strip
            $item.db_username = @db_username_edit.text.strip
            $item.db_password = @db_password_edit.text
            $item.db_ssl_certificate = @db_ssl_certificate_edit.text.strip.gsub("\\", "/")
            $item.db_server_dn = @db_server_dn_edit.text.strip

            control_fields = {}
            DATABASE_SERVER_CONTROLS.each do |contr|
              control_fields[contr] = self.instance_variable_get("@#{contr}_edit")
            end
            
            control_fields["db_ssl_certificate"] = self.instance_variable_get("@db_ssl_certificate_edit")
            control_fields["db_server_dn"] = self.instance_variable_get("@db_server_dn_edit")

            validated, field, error_msg = $item.validate_fields *DATABASE_SERVER_CONTROLS

            if validated
              if self.instance_variable_get("@db_ssl_connection_check").checked?
                if $item.database_type == "ORACLE"
                  validated, field, error_msg = $item.validate_fields "db_ssl_certificate"
                else
                  if self.instance_variable_get("@db_validate_server_check").checked?
                    validated, field, error_msg = $item.validate_fields "db_ssl_certificate"
                  end
                end
              end
              
              if validated
                if self.instance_variable_get("@db_validate_server_check").checked?
                  validated, field, error_msg = $item.validate_fields "db_server_dn"
                end
              end
            end
            
            # then, validate the db connection string matches db type
            if validated
              valid_conn_string_regex = case $item.database_type
                when "POSTGRES"
                  /^postgresql:/
                when "MSSQL"
                  /^sqlserver:/
                when "ORACLE"
                  /^oracle:/
                end
              validated = if $item.db_connection_url_template =~ valid_conn_string_regex then true else false end
              error_msg = ReadableNames["pop_up_messages"]["db_connection_string_template"] % $item.database_type
            end

            # then, validate the DB connection
            if validated
              begin
                connection_url = $item.db_connection_url_template.dup()
                connection_url["\<HOSTNAME\>"] = $item.db_hostname
                connection_url["\<PORT\>"] = $item.db_port
                connection_url["\<INSTANCE_NAME\>"] = $item.db_name
                if @db_validate_server_check.checked?
                  connection_url["\<HOST_DN\>"] = $item.db_server_dn
                end

                db_connection_result = DB.test_db_connection(
                  connection_url.gsub('"', '\"'),
                  $item.db_username,
                  $item.db_password,
                  $item.db_ssl_certificate == "" ? "NA" : $item.db_ssl_certificate,
                  $item.db_server_dn,
                  30
                )
              rescue Exception => e
                db_connection_result = false
                error_msg = ReadableNames["db_page"]["test_connnection_failed_template"] % e.message
              end

              if !db_connection_result
                validated = false
                field = nil
                error_msg = (ReadableNames["db_page"]["test_connnection_failed_template"] % '') if error_msg == nil
              end

            end

            if !validated
              alert_ontop_parent(app.win, error_msg, :title => app.instance_variable_get('@title'))
              if field != nil
                control_fields[field].focus
              end
            else
              # set database connection URL
              $item.db_connection_url = connection_url
              visit(wizard(:next))
            end
          }

          stack :width => 50, :height => 1.0 do
            @db_next_text_btn = nl_button :next_text, :click => next_btn_click_proc
          end

          stack :width => 50, :height => 1.0 do
            @db_next_btn = nl_button :next
            @db_next_btn.click { next_btn_click_proc.call }
          end
        end
      end
    end

    # initialize the radio status
    case $item.database_type
      when "MSSQL", "ORACLE"
       self.instance_variable_get("@#{$item.database_type}_radio").checked = true
       self.instance_variable_get("@db_port_edit").text = ($item.db_port == nil || $item.db_port == "") ? Item::DATABASE_DEFAULT_PORTS[$item.database_type + "_PORT"] : $item.db_port
       if $item.db_connection_url_template == nil || $item.db_connection_url_template == ""
         $item.db_connection_url_template = Item::DB_CONNECTION_URL_TEMPLATES[$item.database_type]
       end
      end
    end
  end

if __FILE__ == $0
  Shoes.app :title => ReadableNames["title"] , :width => 950, :height => 700 do
    win.set_size_request(950, 700)
    win.set_resizable(false)
    win.set_window_position(Gtk::Window::POS_CENTER_ALWAYS)
    visit('/db')
  end
end
