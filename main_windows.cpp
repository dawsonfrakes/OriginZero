#define X(RET, NAME, ...) extern "C" RET WINAPI NAME(__VA_ARGS__);
	KERNEL32_PROCEDURES(X)
#undef X
#define X(RET, NAME, ...) RET (WINAPI* NAME)(__VA_ARGS__);
	USER32_PROCEDURES(X)
#undef X

HINSTANCE platform_hinstance;
HWND      platform_hwnd;
HDC       platform_hdc;

SSize WINAPI win32_window_proc(HWND hwnd, U32 message, USize wParam, SSize lParam) {
	switch (message) {
		case WM_DESTROY:
			PostQuitMessage(0);
			return 0;
		default:
			return DefWindowProcW(hwnd, message, wParam, lParam);
	}
}

extern "C" [[noreturn]] void WINAPI WinMainCRTStartup() {
	HMODULE lib;
	#define X(RET, NAME, ...) NAME = cast(RET (WINAPI*)(__VA_ARGS__), GetProcAddress(lib, String(#NAME).data));
		lib = LoadLibraryW(WString(L"USER32.DLL").data);
		USER32_PROCEDURES(X)
	#undef X

	platform_hinstance = GetModuleHandleW(nil);

	SetProcessDPIAware();
	WNDCLASSEXW wndclass   = {};
	wndclass.cbSize        = size_of(WNDCLASSEXW);
	wndclass.style         = CS_OWNDC;
	wndclass.lpfnWndProc   = win32_window_proc;
	wndclass.hInstance     = platform_hinstance;
	wndclass.hIcon         = LoadIconW(nil, IDI_WARNING);
	wndclass.hCursor       = LoadCursorW(nil, IDC_CROSS);
	wndclass.lpszClassName = WString(L"A").data;
	RegisterClassExW(&wndclass);

	ExitProcess(0);
}
