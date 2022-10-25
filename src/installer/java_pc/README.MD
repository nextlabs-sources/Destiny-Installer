
 /$$   /$$                    /$$    /$$               /$$                      /$$$$$$
| $$$ | $$                   | $$   | $$              | $$                     |_  $$_/
| $$$$| $$ /$$$$$$ /$$   /$$/$$$$$$ | $$       /$$$$$$| $$$$$$$  /$$$$$$$        | $$  /$$$$$$$  /$$$$$$$
| $$ $$ $$/$$__  $|  $$ /$$|_  $$_/ | $$      |____  $| $$__  $$/$$_____/        | $$ | $$__  $$/$$_____/
| $$  $$$| $$$$$$$$\  $$$$/  | $$   | $$       /$$$$$$| $$  \ $|  $$$$$$         | $$ | $$  \ $| $$
| $$\  $$| $$_____/ >$$  $$  | $$ /$| $$      /$$__  $| $$  | $$\____  $$        | $$ | $$  | $| $$
| $$ \  $|  $$$$$$$/$$/\  $$ |  $$$$| $$$$$$$|  $$$$$$| $$$$$$$//$$$$$$$/       /$$$$$| $$  | $|  $$$$$$$/$$
|__/  \__/\_______|__/  \__/  \___/ |________/\_______|_______/|_______/       |______|__/  |__/\_______|__/


									Java Policy Controller Installer ReadMe
----------------------------------------------------------------------------------------------------------------

- Unzip the PolicyControllerJava-xxx-xxx.zip to PolicyControllerJava folder
- Open the PolicyControllerJava folder

- Installing this software using terminal
   - Open jpc_properties.json using your favorite text file editor
	 - provide the installation details and save
	 - Windows
	      -  Open command line as Administrator
				-  change your directory to PolicyControllerJava folder
				-  bin/install.bat to start installation.

	 - Linux
	      - change user to root
				- change your directory to PolicyControllerJava folder
				- sh bin/install.sh to start installation.

- GUI installer
   - Windows
        - change your directory to PolicyControllerJava folder
        - double click on bin/install_ui.bat

   - Linux
        - change your directory to PolicyControllerJava folder
        - sh bin/install_ui.sh to start installation.

++ This software installation requires CATALINA_HOME environmental variable before
   start the Tomcat based installation.

++ This software doesn't install any JBOSS or Apache Tomcat Servers.
