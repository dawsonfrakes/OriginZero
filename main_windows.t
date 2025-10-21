require "lib/windows"

local function utf8_to_utf16lez_string_literal(s)
	local function inner(s)
		local result = {}
		for i = 1, #s do
			table.insert(result, constant(int16, s:byte(i)))
		end
		table.insert(result, constant(int16, 0))
		return result
	end

	return constant(`arrayof(int16, [inner(s)]))
end

local function load_procedures_from_libraries(libraries)
	local code = {}
	for _,library in ipairs(libraries) do
		local dll = symbol(HMODULE, library.."_dll")
		table.insert(code, quote var [dll] = LoadLibraryW([utf8_to_utf16lez_string_literal(library:upper()..".DLL")]) end)
		for _,v in ipairs(_G[library]) do
			local name, typ = v[1], v[2]
			table.insert(code, quote [_G[name]] = [typ](GetProcAddress([dll], name)) end)
		end
	end
	return code
end

local static_libraries = {"Kernel32"}
local dynamic_libraries = {"User32", "Ws2_32", "Dwmapi", "Winmm"}
for _,library in ipairs(static_libraries) do
	for _,v in ipairs(_G[library]) do
		local name, typ = v[1], v[2]
		_G[name] = terralib.externfunction(name, typ)
	end
end
for _,library in ipairs(dynamic_libraries) do
	for _,v in ipairs(_G[library]) do
		local name, typ = v[1], v[2]
		_G[name] = global(typ)
	end
end

platform_hinstance       = global(HMODULE)
platform_hwnd            = global(HWND)
platform_hdc             = global(HDC)
platform_width           = global(uint16)
platform_height          = global(uint16)
platform_keys            = global(bool[128])
platform_key_transitions = global(uint8[128])

local save_placement = global(`WINDOWPLACEMENT {sizeof(WINDOWPLACEMENT)})
local terra toggle_fullscreen()
	var style = GetWindowLongPtrW(platform_hwnd, GWL_STYLE)
	if (style and WS_OVERLAPPEDWINDOW) ~= 0 then
		var mi = MONITORINFO {sizeof(MONITORINFO)}
		GetMonitorInfoW(MonitorFromWindow(platform_hwnd, MONITOR_DEFAULTTOPRIMARY), &mi)

		GetWindowPlacement(platform_hwnd, &save_placement)
		SetWindowLongPtrW(platform_hwnd, GWL_STYLE, style and not WS_OVERLAPPEDWINDOW)
		SetWindowPos(platform_hwnd, HWND_TOP, mi.rcMonitor.left, mi.rcMonitor.top,
			mi.rcMonitor.right - mi.rcMonitor.left,
			mi.rcMonitor.bottom - mi.rcMonitor.top,
			SWP_FRAMECHANGED)
	else
		SetWindowLongPtrW(platform_hwnd, GWL_STYLE, style or WS_OVERLAPPEDWINDOW)
		SetWindowPlacement(platform_hwnd, &save_placement)
		SetWindowPos(platform_hwnd, nil, 0, 0, 0, 0, SWP_NOMOVE or
			SWP_NOSIZE or SWP_NOZORDER or SWP_FRAMECHANGED)
	end
end

local terra update_cursor_clip()
	ClipCursor(nil)
end

local terra clear_held_keys()
	for i = 0,[platform_keys:gettype().N] do
		if platform_keys[i] then
			platform_key_transitions[i] = platform_key_transitions[i] + 1
		end
	end
	memset(&platform_keys, 0, sizeof([platform_keys:gettype()]))
end

local terra window_proc(hwnd: HWND, message: uint32, wParam: intptr, lParam: ptrdiff): ptrdiff
	switch message do
		case WM_PAINT then
			ValidateRect(hwnd, nil)
		case WM_ERASEBKGND then
			return 1
		case WM_ACTIVATEAPP then
			var tabbing_in = wParam ~= 0
			if tabbing_in then update_cursor_clip()
			else               clear_held_keys() end
		case WM_SIZE then
			platform_width = [uint16](lParam)
			platform_height = [uint16](lParam >> 16)
		case WM_CREATE then
			platform_hwnd = hwnd
			platform_hdc = GetDC(hwnd)

			if DwmSetWindowAttribute ~= nil then
				var dark_mode = [int32](true)
				DwmSetWindowAttribute(hwnd, DWMWA_USE_IMMERSIVE_DARK_MODE, &dark_mode, sizeof(int32))
				var round_mode: int32 = DWMWCP_DONOTROUND
				DwmSetWindowAttribute(hwnd, DWMWA_WINDOW_CORNER_PREFERENCE, &round_mode, sizeof(int32))
			end
		case WM_DESTROY then
			PostQuitMessage(0)
		case WM_SYSCOMMAND then
			if wParam ~= SC_KEYMENU then
				return DefWindowProcW(hwnd, message, wParam, lParam) -- @Hack goto default?
			end
		else
			return DefWindowProcW(hwnd, message, wParam, lParam)
	end
	return 0
end

local terra key_event(msg: &MSG)
	var pressed = (msg.lParam and (1 << 31)) == 0
	var repeated = pressed and (msg.lParam and (1 << 30)) ~= 0
	var sys = msg.message == WM_SYSKEYDOWN or msg.message == WM_SYSKEYUP
	var alt = sys and (msg.lParam and (1 << 29)) ~= 0

	if not repeated and (not sys or alt or msg.wParam == VK_MENU or msg.wParam == VK_F10) then
		if pressed then
			if msg.wParam == VK_F4 and alt       then DestroyWindow(platform_hwnd) end
			if DEBUG and msg.wParam == VK_ESCAPE then DestroyWindow(platform_hwnd) end
			if msg.wParam == VK_RETURN and alt   then toggle_fullscreen() end
			if msg.wParam == VK_F11              then toggle_fullscreen() end
		end
	end

	DispatchMessageW(msg) -- @Hack for steam overlay
end

terra WinMainCRTStartup()
	[load_procedures_from_libraries(dynamic_libraries)]

	platform_hinstance = GetModuleHandleW(nil)

	var sleep_is_granular = timeBeginPeriod ~= nil and timeBeginPeriod(1) == TIMERR_NOERROR

	var clock_frequency: int64
	QueryPerformanceFrequency(&clock_frequency)
	var clock_start: int64
	QueryPerformanceCounter(&clock_start)
	var clock_previous = clock_start

	var wsadata: WSADATA
	var networking_supported = WSAStartup ~= nil and WSAStartup(0x202, &wsadata) == 0

	var memory: Slice(uint8)
	memory.count = 1 * 1024 * 1024 * 1024
	memory.data = [&uint8](VirtualAlloc(nil, memory.count, MEM_RESERVE or MEM_COMMIT, PAGE_READWRITE))
	if memory.data == nil then
		ExitProcess(1)
	end

	SetProcessDPIAware()
	var wndclass: WNDCLASSEXW
	memset(&wndclass, 0, sizeof(WNDCLASSEXW))
	wndclass.cbSize        = sizeof(WNDCLASSEXW)
	wndclass.style         = CS_OWNDC
	wndclass.lpfnWndProc   = window_proc
	wndclass.hInstance     = platform_hinstance
	wndclass.hIcon         = LoadIconW(nil, IDI_WARNING)
	wndclass.hCursor       = LoadCursorW(nil, IDC_CROSS)
	wndclass.lpszClassName = [utf8_to_utf16lez_string_literal("A")]
	RegisterClassExW(&wndclass)
	CreateWindowExW(0, wndclass.lpszClassName, [utf8_to_utf16lez_string_literal("Origin Zero")],
		WS_OVERLAPPEDWINDOW or WS_VISIBLE,
		CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT,
		nil, nil, platform_hinstance, nil)

	while true do
		var msg: MSG
		while PeekMessageW(&msg, nil, 0, 0, PM_REMOVE) ~= 0 do
			TranslateMessage(&msg)
			switch msg.message do
				case WM_KEYDOWN    then key_event(&msg)
				case WM_KEYUP      then key_event(&msg)
				case WM_SYSKEYDOWN then key_event(&msg)
				case WM_SYSKEYUP   then key_event(&msg)
				case WM_QUIT then
					goto main_loop_end
				else
					DispatchMessageW(&msg)
			end
		end

		var clock_current: int64
		QueryPerformanceCounter(&clock_current)
		var delta_time = [float](clock_current - clock_previous) / clock_frequency
		clock_previous = clock_current

		var input = Game_Input {}
		input.delta_time = delta_time
		var output = Game_Output {}
		game_update_and_render(memory, &input, &output)

		if sleep_is_granular then
			Sleep(1)
		end
	end
	::main_loop_end::

	if networking_supported then WSACleanup() end
	ExitProcess(0)
end
