import basic;

version (Windows) {
	static import basic.windows;
	static foreach (it; __traits(allMembers, basic.windows)[1..$]) {
		static if (has_uda!(__traits(getMember, basic.windows, it), foreign) && !string_equal(get_uda!(__traits(getMember, basic.windows, it), foreign).library, "Kernel32")) {
			mixin("__gshared typeof(basic.windows."~it~")* "~it~";");
		} else {
			mixin("alias "~it~" = basic.windows."~it~";");
		}
	}

	__gshared {
		HINSTANCE platform_hinstance;
		HWND platform_hwnd;
		HDC platform_hdc;
	}

	extern(Windows) noreturn WinMainCRTStartup() {
		HMODULE User32_dll = LoadLibraryW("USER32.DLL");
		HMODULE Winmm_dll = LoadLibraryW("WINMM.DLL");

		static foreach (it; __traits(allMembers, basic.windows)[1..$]) {
			static if (has_uda!(__traits(getMember, basic.windows, it), foreign) && !string_equal(get_uda!(__traits(getMember, basic.windows, it), foreign).library, "Kernel32")) {
				mixin(it~" = cast(typeof("~it~")) GetProcAddress("~get_uda!(__traits(getMember, basic.windows, it), foreign).library~"_dll, \""~it~"\");");
			}
		}

		platform_hinstance = GetModuleHandleW(null);

		bool sleep_is_granular = timeBeginPeriod && timeBeginPeriod(1) == TIMERR_NOERROR;

		SetProcessDPIAware();
		WNDCLASSEXW wndclass;
		wndclass.cbSize = WNDCLASSEXW.sizeof;
		wndclass.style = CS_OWNDC;
		wndclass.lpfnWndProc = (hwnd, message, wParam, lParam) {
			switch (message) {
				case WM_CREATE:
					platform_hwnd = hwnd;
					platform_hdc = GetDC(hwnd);
					return 0;
				case WM_DESTROY:
					PostQuitMessage(0);
					return 0;
				default:
					return DefWindowProcW(hwnd, message, wParam, lParam);
			}
		};
		wndclass.hInstance = platform_hinstance;
		wndclass.hIcon = LoadIconW(null, IDI_WARNING);
		wndclass.hCursor = LoadCursorW(null, IDC_CROSS);
		wndclass.lpszClassName = "A";
		RegisterClassExW(&wndclass);

		ExitProcess(0);
	}
}
