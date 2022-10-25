#ifndef DRIVER_HEADER
	export prototype INT InstallDriverFile(HWND, int, WSTRING, WSTRING, WSTRING);
	export prototype INT InstallDriverFileWithGroup(HWND, int, WSTRING, WSTRING, WSTRING, WSTRING);
	export prototype INT RemoveDriverFile(HWND, WSTRING);      
	export prototype INT RemoveDriverRegistry(HWND);
	export prototype INT RepairDriverService(HWND, int, WSTRING, WSTRING, WSTRING);
	export prototype INT RepairDriverServiceWithGroup(HWND, int, WSTRING, WSTRING, WSTRING, WSTRING);
	export prototype INT StartDriverService(HWND, WSTRING);
	export prototype INT StopDriverService(HWND, WSTRING);      
	
	//External DLL functions                                  
	prototype INT installercommon.InstallDriver(int, BYREF WSTRING, BYREF WSTRING, BYREF WSTRING, BYREF WSTRING);
	prototype INT installercommon.RemoveDriver(BYREF WSTRING);
	prototype INT installercommon.StartDriver(BYREF WSTRING);
	prototype INT installercommon.StopDriver(BYREF WSTRING);
#endif
#define DRIVER_HEADER