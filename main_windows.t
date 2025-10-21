require "lib/windows"

function utf8_to_utf16lez_string_literal(s)
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

function load_procedures_from_libraries(libraries)
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
local dynamic_libraries = {"User32"}
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

platform_hinstance = global(HMODULE)

local terra window_proc(hwnd: HWND, message: uint32, wParam: intptr, lParam: ptrdiff): ptrdiff
	switch message do
		case WM_DESTROY then
			PostQuitMessage(0)
		else
			return DefWindowProcW(hwnd, message, wParam, lParam)
	end
	return 0
end

local terra key_event(msg: &MSG)
	DispatchMessageW(msg)
end

terra WinMainCRTStartup()
	[load_procedures_from_libraries(dynamic_libraries)]

	platform_hinstance = GetModuleHandleW(nil)

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
	end
	::main_loop_end::

	ExitProcess(0)
end
