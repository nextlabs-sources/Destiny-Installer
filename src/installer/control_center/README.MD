# Policy Server Installer Instruction

1. Unzip the **ControlCenter-@platform@-@cc_version@-@build_no@.zip**
2. Open the extracted PolicyServer folder

3. Installing this software using command line
  - Open **cc_properties.json** using your favorite text file editor
  - provide the installation details and save
  - Windows
    - Open command line as Administrator
    - change your directory to PolicyServer folder and execute
        `bin/install.bat`
  - Linux
      - change user to root
      - change your directory to PolicyServer folder and execute
        `sh bin/install.sh`

4. GUI installer
  - Windows
    - change your directory to PolicyServer folder and double click on **bin/install_ui.bat**
  - Linux
    - change your directory to PolicyServer folder and execute
        `sh bin/install_ui.sh`

# Description about the cc_properties.json file

The file is used only for command line installation. The fields inside the json file are:

## installation_dir

Installation Destination Folder, the folder must exist before the installation starts.

Control Center will be installed into a subfolder named "PolicyServer" under it. Must use unix style path separator (forward slash /).

e.g.  For windows: **C:/Program Files/Nextlabs**, For linux: **/opt/Nextlabs**

## installation_mode

valid values: **install** , **upgrade**, **remove**

## license_file_location

The license file location. Must use unix style path separator (forward slash /).

e.g.  For windows: **C:/Users/Administrator/Desktop/license.dat**  For linux: **/root/license.dat**

## admin_user_password

Super User Password for the built-in Administrator user for all Control Center Server Applications.

## trust_store_password

SSL certificates password for Control Center Server. The password will be used to generate the SSL certificates and protect the keystore files.

## key_store_password

Password to access the Encryption Key Store (in Key Management Server) for Control Center Server.

## installation_type and 9 *_component

The values are used to specify Control Center modules to be installed.

The valid values for **installation_type** are **complete** and **custom**. 

The corresponding component full names are:

| Field                | Full Name                           |
| ---------------------|:-----------------------------------:|
| dms_component        | Management Server                   |
| dac_component        | Intelligence Server                 |
| dps_component        | Policy Management Server            |
| dem_component        | Enrollment Manager                  |
| admin_component      | Administrator                       |
| reporter_component   | Reporter                            |
| cc_console_component | Console (Web admin and APIs) Server |
| dabs_component       | ICENet Server                       |
| dkms_component       | Key Management Server               |

### For installation_type set as complete:

Please set all 9 components to **ON**.

### For installation_type set as custom:

For custom installation, 2 modes are supported:

1. All components except ICENet Server and Key Management Server, then only **dabs_component** and **dkms_component** should be set to **OFF** and other components should be set to **ON**.
2. Only ICENet Server and Key Managment Server, then only **dabs_component** and **dkms_component** should be set to **ON** and other components should be set to **OFF**.

## installed_cc_host

This value only valid for Custom installation with only ICENet Server and Keymanagement Server.

Management server host, should be the hostname of another Control Center host with all components except ICENet Server and Key Management Server installed.

## installed_cc_port

This value only valid for Custom installation with only ICENet Server and Keymanagement Server.

Management server port, should be the web_service_port of another Control Center host with all components except ICENet Server and Key Management Server installed

## database_type, db_connection_url, db_username, db_password

Database server details.

No need to specify for custom installation for only ICENet Server and Key Management Server.

The Control Center Installer supports two types of database: Oracle DB and MS SQL Server. The corresponding values for **database_type** are: **ORACLE** and **MSSQL**.

Format of **db_connection_url** for the two databases are:

* `oracle:thin:@<hostname>:1521:<sid>`
* `sqlserver://<hostname>:1433;DatabaseName=<db name>;`

## web_service_port

The web service port for Control Center Server.

## web_application_port

Web Application port number.

For Custom installation with only ICENet Server and Keymanagement Server, it should be same as the **web_application_port** of the Control Center host with all components except ICENet Server and Key Management Server installed

## mail_server_url, mail_server_port, mail_server_username, mail_server_password, mail_server_from, mail_server_to

Mail Server configurations - leave empty if you want to skip.

No need to specify for custom installation for only ICENet Server and Key Management Server.

## temp_dir

Temporary directory for copy and prepare installation artifacts. Must exist before the installation starts. 

Must use unix style path separator (forward slash /).

e.g.  For windows: **C:/Temp**  For linux: **/tmp**

If the field is not present in the **cc_properties.json** file, the default system temporary folder will be used.

## version_number, built_date

System Configuration, Do not change any of the values.

