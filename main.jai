/* TODO
Draw all ui_rects.
	Create white texture.
	Create max-sized buffer.
	Emit draw call.
*/

usize :: u64;
ssize :: s64;

v2 :: struct {
	x: float;
	y: float;
}

v3 :: struct {
	x: float;
	y: float;
	z: float;
}

v4 :: struct {
	x: float;
	y: float;
	z: float;
	w: float;
}

max :: inline (a: $T, b: T) -> T #no_context { return ifx a > b a else b; }
min :: inline (a: $T, b: T) -> T #no_context { return ifx a < b a else b; }

Game_Input :: struct {
	dt: float;
	keys: *[128] bool;
	key_transitions: *[128] u8;
}

Game_Renderer :: struct {
	Texture_2D :: enum u8 {
		WHITE :: 0;
	}

	Rect :: struct {
		position: v3;
		size: v2;
		texcoords: [2] v2;
		texture: Texture_2D;
		color: v4;
	}
}

Game_Output :: struct {
	ui_rects: [4096] Game_Renderer.Rect;
	ui_rects_count: u16;
}

Game_State :: struct {
	initted: bool;
	keys_previous: [128] bool;
}

rect :: (using output: *Game_Output, rect: Game_Renderer.Rect) #no_context {
	if ui_rects_count < ui_rects.count {
		ui_rects[ui_rects_count] = rect;
		ui_rects_count += 1;
	}
}

game_update_and_render :: (memory: []u8, input: *Game_Input, output: *Game_Output) #no_context {
	state := memory.data.(*Game_State);
	if !state.initted {
		state.* = .{}; // default-init.
		state.initted = true;
	}

	rect(output, .{
		position=.{0.5, 0.0, 0.0},
		size=.{0.5, 0.5},
		texcoords=.[.{}, .{1.0, 1.0}],
		texture=.WHITE,
		color=.{1.0, 0.0, 1.0, 1.0},
	});

	state.keys_previous = input.keys.*;
}

#if RENDERER == .OPENGL {
	// 1.0
	GL_DEPTH_BUFFER_BIT :: 0x00000100;
	GL_COLOR_BUFFER_BIT :: 0x00004000;
	GL_COLOR :: 0x1800;
	GL_DEPTH :: 0x1801;
	GL_NEAREST :: 0x2600;
	GL_LINEAR :: 0x2601;

	// 3.0
	GL_RGBA16F :: 0x881A;
	GL_DEPTH_COMPONENT32F :: 0x8CAC;
	GL_READ_FRAMEBUFFER :: 0x8CA8;
	GL_DRAW_FRAMEBUFFER :: 0x8CA9;
	GL_COLOR_ATTACHMENT0 :: 0x8CE0;
	GL_COLOR_ATTACHMENT1 :: 0x8CE1;
	GL_DEPTH_ATTACHMENT :: 0x8D00;
	GL_FRAMEBUFFER :: 0x8D40;
	GL_RENDERBUFFER :: 0x8D41;
	GL_FRAMEBUFFER_SRGB :: 0x8DB9;

	// 3.2
	GL_MAX_COLOR_TEXTURE_SAMPLES :: 0x910E;
	GL_MAX_DEPTH_TEXTURE_SAMPLES :: 0x910F;

	#if OS == .WINDOWS {
		opengl_platform_context: HGLRC;
	}
	opengl_main_fbo:        u32;
	opengl_main_fbo_color0: u32;
	opengl_main_fbo_depth:  u32;
	using opengl_procs:     struct {
		glViewport: (x: s32, y: s32, w: u32, h: u32) #c_call; @v1_0
		glClear: (mask: u32) #c_call; @v1_0
		glGetIntegerv: (name: u32, data: *s32) #c_call; @v1_0
		glEnable: (capability: u32) #c_call; @v1_0
		glDisable: (capability: u32) #c_call; @v1_0

		glBindFramebuffer: (target: u32, fbo: u32) #c_call; @v3_0

		glCreateFramebuffers: (n: u32, ids: *u32) #c_call; @v4_5
		glClearNamedFramebufferfv: (fbo: u32, buffer: u32, drawbuffer: s32, value: *float) #c_call; @v4_5
		glNamedFramebufferRenderbuffer: (fbo: u32, attachment: u32, target: u32, rbo: u32) #c_call; @v4_5
		glBlitNamedFramebuffer: (read_fbo: u32, write_fbo: u32, sx0: s32, sy0: s32, sx1: s32, sy1: s32, dx0: s32, dy0: s32, dx1: s32, dy1: s32, mask: u32, filter: u32) #c_call; @v4_5
		glCreateRenderbuffers: (n: u32, ids: *u32) #c_call; @v4_5
		glNamedRenderbufferStorageMultisample: (rbo: u32, samples: u32, internalformat: u32, w: u32, h: u32) #c_call; @v4_5
	};

	opengl_init :: () #no_context {
		#if OS == .WINDOWS {
			pfd: PIXELFORMATDESCRIPTOR;
			pfd.nSize = size_of(PIXELFORMATDESCRIPTOR);
			pfd.nVersion = 1;
			pfd.dwFlags = PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER | PFD_DEPTH_DONTCARE;
			pfd.cColorBits = 24;
			format := ChoosePixelFormat(platform_hdc, *pfd);
			SetPixelFormat(platform_hdc, format, *pfd);

			temp_ctx := wglCreateContext(platform_hdc);
			defer wglDeleteContext(temp_ctx);
			wglMakeCurrent(platform_hdc, temp_ctx);

			wglCreateContextAttribsARB :=
				cast(#type (hdc: HDC, share: HGLRC, attributes: *s32) -> HGLRC #c_call)
				wglGetProcAddress("wglCreateContextAttribsARB");

			attributes := s32.[
				WGL_CONTEXT_MAJOR_VERSION_ARB, 4,
				WGL_CONTEXT_MINOR_VERSION_ARB, 5,
				WGL_CONTEXT_FLAGS_ARB, xx ifx DEBUG WGL_CONTEXT_DEBUG_BIT_ARB,
				WGL_CONTEXT_PROFILE_MASK_ARB, WGL_CONTEXT_CORE_PROFILE_BIT_ARB,
				0,
			];
			opengl_platform_context = wglCreateContextAttribsARB(platform_hdc, null, attributes.data);
			wglMakeCurrent(platform_hdc, opengl_platform_context);

			wglSwapIntervalEXT :=
				cast(#type (interval: s32) -> s32 #c_call)
				wglGetProcAddress("wglSwapIntervalEXT");
			if wglSwapIntervalEXT wglSwapIntervalEXT(1); // force vsync for now.

			opengl32 := GetModuleHandleW((#run utf8_to_utf16lez("Opengl32.dll")).data);
			#insert -> string {
				buffer: [4096] u8;
				buffer_count := 0;
				print :: (s: string) #expand {
					p := buffer.data + buffer_count;
					for s p[it_index] = it;
					buffer_count += s.count;
				}

				for type_info(type_of(opengl_procs)).members {
					if it.notes[0][1] == #char "1" {
						print(it.name);
						print(" = xx GetProcAddress(opengl32, \"");
						print(it.name);
						print("\");\n");
					} else {
						print(it.name);
						print(" = xx wglGetProcAddress(\"");
						print(it.name);
						print("\");\n");
					}
				}

				return .{buffer_count, buffer.data};
			}
		}

		glCreateFramebuffers(1, *opengl_main_fbo);
		glCreateRenderbuffers(1, *opengl_main_fbo_color0);
		glCreateRenderbuffers(1, *opengl_main_fbo_depth);
	}

	opengl_deinit :: () #no_context {
		#if OS == .WINDOWS {
			if opengl_platform_context wglDeleteContext(opengl_platform_context);
			opengl_platform_context = null;
		}
	}

	opengl_resize :: () #no_context {
		fbo_color_samples_max: s32 = ---;
		glGetIntegerv(GL_MAX_COLOR_TEXTURE_SAMPLES, *fbo_color_samples_max);
		fbo_depth_samples_max: s32 = ---;
		glGetIntegerv(GL_MAX_DEPTH_TEXTURE_SAMPLES, *fbo_depth_samples_max);
		fbo_samples: u32 = xx max(min(fbo_color_samples_max, fbo_depth_samples_max), 1);

		glNamedRenderbufferStorageMultisample(opengl_main_fbo_color0,
			fbo_samples, GL_RGBA16F, platform_width, platform_height);
		glNamedFramebufferRenderbuffer(opengl_main_fbo,
			GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, opengl_main_fbo_color0);

		glNamedRenderbufferStorageMultisample(opengl_main_fbo_depth,
			fbo_samples, GL_DEPTH_COMPONENT32F, platform_width, platform_height);
		glNamedFramebufferRenderbuffer(opengl_main_fbo,
			GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, opengl_main_fbo_depth);

		glViewport(0, 0, platform_width, platform_height);
	}

	opengl_present :: (ui_rects: []Game_Renderer.Rect) #no_context {
		glClearNamedFramebufferfv(opengl_main_fbo, GL_COLOR, 0, float.[0.6, 0.2, 0.2, 1.0].data);
		glClearNamedFramebufferfv(opengl_main_fbo, GL_DEPTH, 0, float.[0.0].data);
		glBindFramebuffer(GL_FRAMEBUFFER, opengl_main_fbo);

		// @Hack fixes default framebuffer bug on intel.
		glBindFramebuffer(GL_FRAMEBUFFER, 0);
		glClear(0);

		glEnable(GL_FRAMEBUFFER_SRGB);
		glBlitNamedFramebuffer(opengl_main_fbo, 0,
			0, 0, platform_width, platform_height,
			0, 0, platform_width, platform_height,
			GL_COLOR_BUFFER_BIT, GL_NEAREST);
		glDisable(GL_FRAMEBUFFER_SRGB);

		#if OS == .WINDOWS {
			SwapBuffers(platform_hdc);
		}
	}
}

renderer_init :: inline () #no_context {
	#if #complete RENDERER == {
	case .NONE;
	case .OPENGL; opengl_init();
	}
}

renderer_deinit :: inline () #no_context {
	#if #complete RENDERER == {
	case .NONE;
	case .OPENGL; opengl_deinit();
	}
}

renderer_resize :: inline () #no_context {
	#if #complete RENDERER == {
	case .NONE;
	case .OPENGL; opengl_resize();
	}
}

renderer_present :: inline (ui_rects: []Game_Renderer.Rect) #no_context {
	#if #complete RENDERER == {
	case .NONE;
	case .OPENGL; opengl_present(ui_rects);
	}
}

#if OS == .WINDOWS {
	Kernel32 :: #library,system "Kernel32";

	MEM_COMMIT :: 0x00001000;
	MEM_RESERVE :: 0x00002000;
	PAGE_READWRITE :: 0x04;

	HINSTANCE :: *struct {};
	HMODULE :: HINSTANCE;
	PROC :: #type () -> ssize #c_call;

	GetModuleHandleW :: (name: *u16) -> HMODULE #foreign Kernel32;
	GetProcAddress :: (module: HMODULE, name: *u8) -> PROC #foreign Kernel32;
	QueryPerformanceFrequency :: (freq: *s64) -> s32 #foreign Kernel32;
	QueryPerformanceCounter :: (counter: *s64) -> s32 #foreign Kernel32;
	Sleep :: (duration: u32) #foreign Kernel32;
	VirtualAlloc :: (address: *void, size: usize, kind: u32, protect: u32) -> *void #foreign Kernel32;
	ExitProcess :: (status: u32) #foreign Kernel32;

	User32 :: #library,system "User32";

	CS_OWNDC :: 0x0020;
	IDI_WARNING :: cast(*u16) 32515;
	IDC_CROSS :: cast(*u16) 32515;
	WS_MAXIMIZEBOX :: 0x00010000;
	WS_MINIMIZEBOX :: 0x00020000;
	WS_THICKFRAME :: 0x00040000;
	WS_SYSMENU :: 0x00080000;
	WS_CAPTION :: 0x00C00000;
	WS_VISIBLE :: 0x10000000;
	WS_OVERLAPPEDWINDOW :: WS_CAPTION | WS_SYSMENU | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX;
	CW_USEDEFAULT :: 0x80000000;
	PM_REMOVE :: 0x0001;
	WM_CREATE :: 0x0001;
	WM_DESTROY :: 0x0002;
	WM_SIZE :: 0x0005;
	WM_PAINT :: 0x000F;
	WM_QUIT :: 0x0012;
	WM_ERASEBKGND :: 0x0014;
	WM_ACTIVATEAPP :: 0x001C;
	WM_KEYDOWN :: 0x0100;
	WM_KEYUP :: 0x0101;
	WM_SYSKEYDOWN :: 0x0104;
	WM_SYSKEYUP :: 0x0105;
	WM_SYSCOMMAND :: 0x0112;
	SC_KEYMENU :: 0xF100;
	GWL_STYLE :: -16;
	MONITOR_DEFAULTTOPRIMARY :: 0x1;
	HWND_TOP :: cast(HWND) 0;
	SWP_NOSIZE :: 0x0001;
	SWP_NOMOVE :: 0x0002;
	SWP_NOZORDER :: 0x0004;
	SWP_FRAMECHANGED :: 0x0020;
	VK_RETURN :: 0x0D;
	VK_MENU :: 0x12;
	VK_ESCAPE :: 0x1B;
	VK_F4 :: 0x73;
	VK_F10 :: 0x79;
	VK_F11 :: 0x7A;

	HDC :: *struct {};
	HWND :: *struct {};
	HMENU :: *struct {};
	HICON :: *struct {};
	HBRUSH :: *struct {};
	HCURSOR :: *struct {};
	HMONITOR :: *struct {};
	WNDPROC :: #type (hwnd: HWND, message: u32, wParam: usize, lParam: ssize) -> ssize #c_call;
	POINT :: struct {
		x: s32;
		y: s32;
	}
	RECT :: struct {
		left: s32;
		top: s32;
		right: s32;
		bottom: s32;
	}
	WNDCLASSEXW :: struct {
		cbSize: u32;
		style: u32;
		lpfnWndProc: WNDPROC;
		cbClsExtra: s32;
		cbWndExtra: s32;
		hInstance: HINSTANCE;
		hIcon: HICON;
		hCursor: HCURSOR;
		hbrBackground: HBRUSH;
		lpszMenuName: *u16;
		lpszClassName: *u16;
		hIconSm: HICON;
	}
	MSG :: struct {
		hwnd: HWND;
		message: u32;
		wParam: usize;
		lParam: ssize;
		time: ssize;
		pt: POINT;
		lPrivate: ssize;
	}
	WINDOWPLACEMENT :: struct {
		length: u32;
		flags: u32;
		showCmd: u32;
		ptMinPosition: POINT;
		ptMaxPosition: POINT;
		rcNormalPosition: RECT;
		rcDevice: RECT;
	}
	MONITORINFO :: struct {
		cbSize: u32;
		rcMonitor: RECT;
		rcWork: RECT;
		dwFlags: u32;
	}

	SetProcessDPIAware :: () -> s32 #foreign User32;
	LoadIconW :: (instance: HINSTANCE, name: *u16) -> HICON #foreign User32;
	LoadCursorW :: (instance: HINSTANCE, name: *u16) -> HCURSOR #foreign User32;
	RegisterClassExW :: (wndclass: *WNDCLASSEXW) -> u16 #foreign User32;
	CreateWindowExW :: (ex_style: u32, class_name: *u16, name: *u16, style: u32, x: s32, y: s32, w: s32, h: s32, parent: HWND, menu: HMENU, instance: HINSTANCE, param: *void) -> HWND #foreign User32;
	PeekMessageW :: (msg: *MSG, hwnd: HWND, mmin: u32, mmax: u32, mremove: u32) -> s32 #foreign User32;
	TranslateMessage :: (msg: *MSG) -> s32 #foreign User32;
	DispatchMessageW :: (msg: *MSG) -> ssize #foreign User32;
	DefWindowProcW :: (hwnd: HWND, message: u32, wParam: usize, lParam: ssize) -> ssize #foreign User32;
	PostQuitMessage :: (status: s32) #foreign User32;
	GetDC :: (hwnd: HWND) -> HDC #foreign User32;
	ValidateRect :: (hwnd: HWND, rect: *RECT) -> s32 #foreign User32;
	ClipCursor :: (rect: *RECT) -> s32 #foreign User32;
	DestroyWindow :: (hwnd: HWND) -> s32 #foreign User32;
	GetWindowLongPtrW :: (hwnd: HWND, index: s32) -> ssize #foreign User32;
	SetWindowLongPtrW :: (hwnd: HWND, index: s32, value: ssize) -> ssize #foreign User32;
	GetWindowPlacement :: (hwnd: HWND, placement: *WINDOWPLACEMENT) -> s32 #foreign User32;
	SetWindowPlacement :: (hwnd: HWND, placement: *WINDOWPLACEMENT) -> s32 #foreign User32;
	SetWindowPos :: (hwnd: HWND, after: HWND, x: s32, y: s32, w: s32, h: s32, flags: u32) -> s32 #foreign User32;
	MonitorFromWindow :: (hwnd: HWND, flags: u32) -> HMONITOR #foreign User32;
	GetMonitorInfoW :: (monitor: HMONITOR, info: *MONITORINFO) -> s32 #foreign User32;

	Gdi32 :: #library,system "Gdi32";

	PFD_DOUBLEBUFFER :: 0x00000001;
	PFD_DRAW_TO_WINDOW :: 0x00000004;
	PFD_SUPPORT_OPENGL :: 0x00000020;
	PFD_DEPTH_DONTCARE :: 0x20000000;

	PIXELFORMATDESCRIPTOR :: struct {
		nSize: u16;
		nVersion: u16;
		dwFlags: u32;
		iPixelType: u8;
		cColorBits: u8;
		cRedBits: u8;
		cRedShift: u8;
		cGreenBits: u8;
		cGreenShift: u8;
		cBlueBits: u8;
		cBlueShift: u8;
		cAlphaBits: u8;
		cAlphaShift: u8;
		cAccumBits: u8;
		cAccumRedBits: u8;
		cAccumGreenBits: u8;
		cAccumBlueBits: u8;
		cAccumAlphaBits: u8;
		cDepthBits: u8;
		cStencilBits: u8;
		cAuxBuffers: u8;
		iLayerType: u8;
		bReserved: u8;
		dwLayerMask: u32;
		dwVisibleMask: u32;
		dwDamageMask: u32;
	}

	ChoosePixelFormat :: (hdc: HDC, pfd: *PIXELFORMATDESCRIPTOR) -> s32 #foreign Gdi32;
	SetPixelFormat :: (hdc: HDC, format: s32, pfd: *PIXELFORMATDESCRIPTOR) -> s32 #foreign Gdi32;
	SwapBuffers :: (hdc: HDC) -> s32 #foreign Gdi32;

	Opengl32 :: #library,system "Opengl32";

	WGL_CONTEXT_MAJOR_VERSION_ARB :: 0x2091;
	WGL_CONTEXT_MINOR_VERSION_ARB :: 0x2092;
	WGL_CONTEXT_FLAGS_ARB :: 0x2094;
	WGL_CONTEXT_PROFILE_MASK_ARB :: 0x9126;
	WGL_CONTEXT_DEBUG_BIT_ARB :: 0x0001;
	WGL_CONTEXT_CORE_PROFILE_BIT_ARB :: 0x00000001;

	HGLRC :: *struct {};

	wglCreateContext :: (hdc: HDC) -> HGLRC #foreign Opengl32;
	wglDeleteContext :: (hglrc: HGLRC) -> s32 #foreign Opengl32;
	wglMakeCurrent :: (hdc: HDC, hglrc: HGLRC) -> s32 #foreign Opengl32;
	wglGetProcAddress :: (name: *u8) -> PROC #foreign Opengl32;

	Dwmapi :: #library,system "Dwmapi";

	DWMWA_USE_IMMERSIVE_DARK_MODE :: 20;
	DWMWA_WINDOW_CORNER_PREFERENCE :: 33;
	DWMWCP_DONOTROUND :: 1;

	DwmSetWindowAttribute :: (hwnd: HWND, attribute: u32, value: *void, size: u32) -> u32 #foreign Dwmapi;

	Winmm :: #library,system "Winmm";

	TIMERR_NOERROR :: 0;

	timeBeginPeriod :: (interval: u32) -> u32 #foreign Winmm;
}

#if OS == .WINDOWS {
	platform_frequency:       s64;
	platform_hinstance:       HINSTANCE;
	platform_hwnd:            HWND;
	platform_hdc:             HDC;
	platform_width:           u16;
	platform_height:          u16;
	platform_keys:            [128] bool;
	platform_key_transitions: [128] u8;

	utf8_to_utf16lez :: ($s: string) -> [s.count + 1]u16 #no_context #compile_time {
		result: [s.count + 1]u16 = ---;
		for s {
			if it & 0x80 compile_time_debug_break(); // ASCII-only for now.
			result[it_index] = it;
		}
		result[s.count] = 0;
		return result;
	}

	toggle_fullscreen_save_placement := WINDOWPLACEMENT.{length=size_of(WINDOWPLACEMENT)};

	toggle_fullscreen :: () #no_context {
		style := GetWindowLongPtrW(platform_hwnd, GWL_STYLE);
		if style & WS_OVERLAPPEDWINDOW {
			mi := MONITORINFO.{cbSize=size_of(MONITORINFO)};
			GetMonitorInfoW(MonitorFromWindow(platform_hwnd, MONITOR_DEFAULTTOPRIMARY), *mi);

			GetWindowPlacement(platform_hwnd, *toggle_fullscreen_save_placement);
			SetWindowLongPtrW(platform_hwnd, GWL_STYLE, style & ~WS_OVERLAPPEDWINDOW);
			SetWindowPos(platform_hwnd, HWND_TOP, mi.rcMonitor.left, mi.rcMonitor.top,
				mi.rcMonitor.right - mi.rcMonitor.left,
				mi.rcMonitor.bottom - mi.rcMonitor.top,
				SWP_FRAMECHANGED);
		} else {
			SetWindowLongPtrW(platform_hwnd, GWL_STYLE, style | WS_OVERLAPPEDWINDOW);
			SetWindowPlacement(platform_hwnd, *toggle_fullscreen_save_placement);
			SetWindowPos(platform_hwnd, null, 0, 0, 0, 0, SWP_NOMOVE |
				SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED);
		}
	}

	update_cursor_clip :: () #no_context {
		ClipCursor(null);
	}

	clear_held_keys :: () #no_context {
		memset(platform_keys.data, 0, platform_keys.count * size_of(type_of(platform_keys[0])));
	}

	WinMainCRTStartup :: () #c_call {
		platform_hinstance = GetModuleHandleW(null);

		sleep_is_granular := timeBeginPeriod(1) == TIMERR_NOERROR;

		QueryPerformanceFrequency(*platform_frequency);
		start_ticks: s64 = ---;
		QueryPerformanceCounter(*start_ticks);
		previous_ticks := start_ticks;

		memory: []u8 = ---;
		memory.count = 1 * 1024 * 1024 * 1024; // 1 gigglebyte is enough for anybody.
		memory.data = VirtualAlloc(null, xx memory.count, MEM_RESERVE | MEM_COMMIT, PAGE_READWRITE);
		if !memory.data ExitProcess(1);

		SetProcessDPIAware();
		wndclass: WNDCLASSEXW;
		wndclass.cbSize = size_of(WNDCLASSEXW);
		wndclass.style = CS_OWNDC;
		wndclass.lpfnWndProc = (hwnd: HWND, message: u32, wParam: usize, lParam: ssize) -> ssize #c_call {
			if message == {
			case WM_PAINT;
				ValidateRect(hwnd, null);
			case WM_ERASEBKGND;
				return 1;
			case WM_ACTIVATEAPP;
				tabbing_in := wParam != 0;
				if tabbing_in update_cursor_clip();
				else          clear_held_keys();
			case WM_SIZE;
				platform_width  = ((lParam >> 0)  & 0xFFFF).(u16);
				platform_height = ((lParam >> 16) & 0xFFFF).(u16);

				renderer_resize();
			case WM_CREATE;
				platform_hwnd = hwnd;
				platform_hdc  = GetDC(hwnd);

				dark_mode: s32 = xx true;
				DwmSetWindowAttribute(hwnd, DWMWA_USE_IMMERSIVE_DARK_MODE, *dark_mode, size_of(s32));
				round_mode: s32 = DWMWCP_DONOTROUND;
				DwmSetWindowAttribute(hwnd, DWMWA_WINDOW_CORNER_PREFERENCE, *round_mode, size_of(s32));

				renderer_init();
			case WM_DESTROY;
				renderer_deinit();

				PostQuitMessage(0);
			case WM_SYSCOMMAND;
				if wParam == SC_KEYMENU return 0;
				#through;
			case;
				return DefWindowProcW(hwnd, message, wParam, lParam);
			}
			return 0;
		};
		wndclass.hInstance = platform_hinstance;
		wndclass.hIcon = LoadIconW(null, IDI_WARNING);
		wndclass.hCursor = LoadCursorW(null, IDC_CROSS);
		wndclass.lpszClassName = (#run utf8_to_utf16lez("A")).data;
		RegisterClassExW(*wndclass);
		CreateWindowExW(0, wndclass.lpszClassName, (#run utf8_to_utf16lez("Origin Zero")).data,
			WS_OVERLAPPEDWINDOW | WS_VISIBLE,
			CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT,
			null, null, platform_hinstance, null);

		while main_loop := true {
			msg: MSG = ---;
			while PeekMessageW(*msg, null, 0, 0, PM_REMOVE) {
				using msg;
				TranslateMessage(*msg);
				if message == {
				case WM_KEYDOWN; #through;
				case WM_KEYUP; #through;
				case WM_SYSKEYDOWN; #through;
				case WM_SYSKEYUP;
					pressed := (lParam & (1 << 31)) == 0;
					repeat  := pressed && (lParam & (1 << 30)) != 0;
					sys     := message == WM_SYSKEYDOWN || message == WM_SYSKEYUP;
					alt     := sys && (lParam & (1 << 29)) != 0;

					if !repeat && (!sys || alt || wParam == VK_F10 || wParam == VK_MENU) {
						if pressed {
							if DEBUG && wParam == VK_ESCAPE DestroyWindow(platform_hwnd);
							if wParam == VK_F4 && alt DestroyWindow(platform_hwnd);
							if wParam == VK_RETURN && alt toggle_fullscreen();
							if wParam == VK_F11 toggle_fullscreen();
						}
					}
				case WM_QUIT;
					break main_loop;
				case;
					DispatchMessageW(*msg);
				}
			}

			current_ticks: s64 = ---;
			QueryPerformanceCounter(*current_ticks);
			delta_ticks := current_ticks - previous_ticks;
			delta_seconds := cast(float) delta_ticks / platform_frequency;
			previous_ticks = current_ticks;

			input: Game_Input;
			input.dt = delta_seconds;
			input.keys = *platform_keys;
			input.key_transitions = *platform_key_transitions;

			output: Game_Output;
			game_update_and_render(memory, *input, *output);

			ui_rects: []Game_Renderer.Rect = ---;
			ui_rects.data = output.ui_rects.data;
			ui_rects.count = output.ui_rects.count;
			renderer_present(ui_rects);

			if sleep_is_granular {
				Sleep(1);
			}
		}

		ExitProcess(0);
	}

	// linker garbage.
	#program_export _fltused: s32;

	// @Cleanup remove this when X64 backend is fixed.
	#if BACKEND == .X64
		#program_export "WinMainCRTStartup" __WinMainCRTStartup :: WinMainCRTStartup;
}
