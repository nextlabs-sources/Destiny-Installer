#ifndef INSTALL_HEADER

	//Private functions
	prototype BOOL IsInstallingFeature(HWND, WSTRING);  
	prototype BOOL IsKeepingFeatureInstalled(HWND, WSTRING);
	prototype BOOL IsKeepingFeatureUninstalled(HWND, WSTRING);
	prototype BOOL IsProductInstalled(HWND, WSTRING);
	prototype BOOL IsUninstallingFeature(HWND, WSTRING); 
	
	// defered versions
	prototype BOOL DeferredIsProductInstalled(HWND, WSTRING);
    prototype BOOL DeferredIsInstallingFeature(HWND, WSTRING);  
	prototype BOOL DeferredIsKeepingFeatureInstalled(HWND, WSTRING);
	prototype BOOL DeferredIsKeepingFeatureUninstalled(HWND, WSTRING);
	prototype BOOL DeferredIsUninstallingFeature(HWND, WSTRING); 

	export prototype INT installercommon.isProductInstalled(BYREF WSTRING);
	export prototype INT InstallCCService(HWND); 
	export prototype INT RemoveCCService(HWND); 
	export prototype INT IsServiceOpen(HWND);       
	

#endif
#define INSTALL_HEADER
