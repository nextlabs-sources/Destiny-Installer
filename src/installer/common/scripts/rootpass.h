#ifndef ROOT_PASSWORD_HEADER

	#define SUPER_USER_PASSWORD_PROPERTY "SUPER_USER_PASSWORD"
	#define SUPER_USER_PASSWORD_CONFIRM_PROPERTY "_super_user_password_confirm"

	export prototype WSTRING GetSuperUserPassword(HWND);
	export prototype INT ValidateSuperUserPassword(HWND);

#endif
#define ROOT_PASSWORD_HEADER
