import basic;
static import game;

/+
	Alias basic.windows definitions as normal if they're not a function,
	or if they're a function from Kernel32. Otherwise, make them a function pointer.
+/
static import basic.windows;
static foreach (it; __traits(allMembers, basic.windows)[1..$]) {
	static if (has_uda!(__traits(getMember, basic.windows, it), foreign) && !string_equal(get_uda!(__traits(getMember, basic.windows, it), foreign).library, "Kernel32")) {
		mixin("__gshared typeof(basic.windows."~it~")* "~it~";");
	} else {
		mixin("alias "~it~" = basic.windows."~it~";");
	}
}

version (Steam) {
	static import basic.steam;
	static foreach (it; __traits(allMembers, basic.steam)[1..$]) {
		static if (has_uda!(__traits(getMember, basic.steam, it), foreign)) {
			mixin("__gshared typeof(basic.steam."~it~")* "~it~";");
		} else {
			mixin("alias "~it~" = basic.steam."~it~";");
		}
	}
}

__gshared {
	HINSTANCE platform_hinstance;
	HWND platform_hwnd;
	HDC platform_hdc;
	ushort platform_width;
	ushort platform_height;
	bool[128] platform_keys;
	byte[128] platform_key_transitions;
}

void toggle_fullscreen() {

}

void update_cursor_clip() {

}

void clear_held_keys() {

}

extern(Windows) noreturn WinMainCRTStartup() {
	// Load basic.windows function pointers for non-Kernel32.
	HMODULE User32_dll = LoadLibraryW("USER32.DLL");
	HMODULE Ws2_32_dll = LoadLibraryW("WS2_32.DLL");
	HMODULE Dwmapi_dll = LoadLibraryW("DWMAPI.DLL");
	HMODULE Winmm_dll = LoadLibraryW("WINMM.DLL");
	static foreach (it; __traits(allMembers, basic.windows)[1..$]) {
		static if (has_uda!(__traits(getMember, basic.windows, it), foreign) && !string_equal(get_uda!(__traits(getMember, basic.windows, it), foreign).library, "Kernel32")) {
			mixin(it~" = cast(typeof("~it~")) GetProcAddress("~get_uda!(__traits(getMember, basic.windows, it), foreign).library~"_dll, \""~it~"\");");
		}
	}

	platform_hinstance = GetModuleHandleW(null);

	bool sleep_is_granular = timeBeginPeriod && timeBeginPeriod(1) == TIMERR_NOERROR;

	long clock_frequency = void;
	QueryPerformanceFrequency(&clock_frequency);
	long clock_start = void;
	QueryPerformanceCounter(&clock_start);
	long clock_previous = clock_start;

	WSADATA wsadata = void;
	bool networking_supported = WSAStartup(0x202, &wsadata) == 0;

	enum memory_count = 1 * 1024 * 1024 * 1024;
	void* memory_data = VirtualAlloc(null, memory_count, MEM_RESERVE | MEM_COMMIT, PAGE_READWRITE);
	ubyte[] memory = (cast(ubyte*) memory_data)[0..memory_count];
	if (!memory.ptr) {
		ExitProcess(1);
	}

	version (Steam) {
		HMODULE SteamAPI_dll = LoadLibraryW("./"~SteamAPI~".DLL");
		static foreach (it; __traits(allMembers, basic.steam)[1..$]) {
			static if (has_uda!(__traits(getMember, basic.steam, it), foreign)) {
				mixin(it~" = cast(typeof("~it~")) GetProcAddress(SteamAPI_dll, \""~it~"\");");
			}
		}
		bool steam_supported = SteamAPI_InitFlat && SteamAPI_InitFlat(null) == ESteamAPIInitResult.OK;
	}

	SetProcessDPIAware();
	WNDCLASSEXW wndclass;
	wndclass.cbSize = WNDCLASSEXW.sizeof;
	wndclass.style = CS_OWNDC;
	wndclass.lpfnWndProc = (hwnd, message, wParam, lParam) {
		switch (message) {
			case WM_PAINT:
				ValidateRect(hwnd, null);
				return 0;
			case WM_ERASEBKGND:
				return 1;
			case WM_ACTIVATEAPP:
				bool tabbing_in = wParam != 0;
				if (tabbing_in) update_cursor_clip();
				else clear_held_keys();
				return 0;
			case WM_SIZE:
				platform_width = cast(ushort) lParam;
				platform_height = cast(ushort) (lParam >> 16);
				return 0;
			case WM_CREATE:
				platform_hwnd = hwnd;
				platform_hdc = GetDC(hwnd);

				if (DwmSetWindowAttribute) {
					int dark_mode = true;
					DwmSetWindowAttribute(hwnd, DWMWA_USE_IMMERSIVE_DARK_MODE, &dark_mode, dark_mode.sizeof);
					int round_mode = DWMWCP_DONOTROUND;
					DwmSetWindowAttribute(hwnd, DWMWA_WINDOW_CORNER_PREFERENCE, &round_mode, round_mode.sizeof);
				}
				return 0;
			case WM_DESTROY:
				PostQuitMessage(0);
				return 0;
			case WM_SYSCOMMAND:
				if (wParam == SC_KEYMENU) return 0;
				goto default;
			default:
				return DefWindowProcW(hwnd, message, wParam, lParam);
		}
	};
	wndclass.hInstance = platform_hinstance;
	wndclass.hIcon = LoadIconW(null, IDI_WARNING);
	wndclass.hCursor = LoadCursorW(null, IDC_CROSS);
	wndclass.lpszClassName = "A";
	RegisterClassExW(&wndclass);
	CreateWindowExW(0, wndclass.lpszClassName, "Origin Zero",
		WS_OVERLAPPEDWINDOW | WS_VISIBLE,
		CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT,
		null, null, platform_hinstance, null);

	main_loop: while (true) {
		MSG msg = void;
		while (PeekMessageW(&msg, null, 0, 0, PM_REMOVE)) {
			TranslateMessage(&msg);
			with (msg) switch (message) {
				case WM_KEYDOWN:
				case WM_KEYUP:
				case WM_SYSKEYDOWN:
				case WM_SYSKEYUP:
					bool pressed = (lParam & (1 << 31)) == 0;
					bool repeat = pressed && (lParam & (1 << 30)) != 0;
					bool sys = message == WM_SYSKEYDOWN || message == WM_SYSKEYUP;
					bool alt = sys && (lParam & (1 << 29)) != 0;

					if (!repeat && (!sys || alt || wParam == VK_MENU || wParam == VK_F10)) {
						if (pressed) {
							debug if (wParam == VK_ESCAPE) DestroyWindow(platform_hwnd);
							if (wParam == VK_F4 && alt) DestroyWindow(platform_hwnd);
							if (wParam == VK_F11) toggle_fullscreen();
							if (wParam == VK_RETURN && alt) toggle_fullscreen();
						}

						if (wParam < 128) {
							platform_keys.ptr[wParam] = pressed;
							platform_key_transitions.ptr[wParam] += 1;
						}
					}
					break;
				case WM_QUIT:
					break main_loop;
				default:
					DispatchMessageW(&msg);
			}
		}

		long clock_current = void;
		QueryPerformanceCounter(&clock_current);
		float delta_time = cast(float) (clock_previous - clock_current) / clock_frequency;
		clock_previous = clock_current;

		game.Input input;
		input.delta_time = delta_time;

		game.Output output;
		game.update_and_render(memory, &input, &output);

		if (sleep_is_granular) {
			Sleep(1);
		}
	}

	version (Steam) if (steam_supported) SteamAPI_Shutdown();
	if (networking_supported) WSACleanup();
	ExitProcess(0);
}

__gshared extern(C) int _fltused;
