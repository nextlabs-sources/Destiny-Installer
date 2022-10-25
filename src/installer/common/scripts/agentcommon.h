#ifndef AGENT_COMMON_HEADER
   	//Support DLL names                                            
	#define AGENT_CONTROLLER_DLL_NAME  "AgentController.dll"
	
	//Possible return code from agent controller
	#define ERROR_INCORRECT_PASSWORD 1
	#define ERROR_AGENT_NOT_STOPPED 2
	#define ERROR_AGENT_NOT_RUNNING 3 
	
	#define ICENET_HOST_TOKEN "[ICENET_HOST]"
	#define ICENET_PORT_TOKEN "[ICENET_PORT]"
	
	//Property containing the uninstallation password
	#define UNINSTALL_PASSWORD_PROP_NAME "UNINSTALL_PASSWORD"
	
	#define AGENT_SERVICE_NAME_PROPERTY_NAME "Agent_Service_Name"
	//This (private) is set to 1 once the action has been done once
	//This allows the UI and non UI cases to co-exist nicely (UI requires
	//immediate validation, whereas non UI does no)
	#define AGENT_STOPPED_PROP_NAME "IsAgentStopped"

   	#define ICENET_SERVER_LOCATION_PROP_NAME "ICENET_SERVER_LOCATION"
	#define NEED_AGENT_STOP_PROPERTY_NAME "_NeedAgentStop"
	#define NEED_DISCOVERY_PROP_NAME "NeedIcenetServerDiscovery"

	export prototype INT BeforeOnMoving(HWND);
	export prototype INT CheckAgentMaintenanceStatus(HWND);
	export prototype INT ConfigureAgentCommProfile(HWND);
	export prototype INT ConfigureAgentLogging(HWND);
	export prototype INT DiscoverIcenetServerLocations(HWND);
	export prototype BOOL IsAgentStopped(HWND);
	export prototype BOOL IsRunAsSystem(HWND);
	export prototype INT LoadAgentControllerDLL(HWND);
	export prototype INT OnRemoveInstallation(HWND);
	export prototype INT ShutdownAgentService(HWND);
	export prototype INT ShutdownAgentWithChallenge(HWND);
	export prototype INT UnloadAgentControllerDLL(HWND);
	export prototype INT ValidateIcenetServerLocation(HWND);                  
	export prototype INT ValidateUninstallPassword(HWND);

	//External DLL functions
	prototype INT AgentController.stopAgentService(BYREF WSTRING);
	prototype INT AgentController.stopAgentServiceWithChallenge(BYREF WSTRING);

#endif
#define AGENT_COMMON_HEADER