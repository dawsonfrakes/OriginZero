-- Kernel32
HRESULT = int32
HINSTANCE = &terralib.types.newstruct("HINSTANCE__")
HMODULE = HINSTANCE
PROC = {} -> ptrdiff

Kernel32 = {
	{"GetModuleHandleW", &int16 -> HMODULE},
	{"LoadLibraryW", &int16 -> HMODULE},
	{"GetProcAddress", {HMODULE, &int8} -> PROC},
	{"QueryPerformanceFrequency", &int64 -> int32},
	{"QueryPerformanceCounter", &int64 -> int32},
	{"Sleep", uint32 -> {}},
	{"ExitProcess", uint32 -> {}},
}

-- User32
CS_OWNDC = 0x0020
IDI_WARNING = constant(&int16, 32515)
IDC_CROSS = constant(&int16, 32515)
WS_MAXIMIZEBOX = 0x00010000
WS_MINIMIZEBOX = 0x00020000
WS_THICKFRAME = 0x00040000
WS_SYSMENU = 0x00080000
WS_CAPTION = 0x00C00000
WS_VISIBLE = 0x10000000
WS_OVERLAPPEDWINDOW = constant(uint32, `WS_CAPTION or WS_SYSMENU or WS_THICKFRAME or WS_MINIMIZEBOX or WS_MAXIMIZEBOX)
CW_USEDEFAULT = constant(uint32, 0x80000000)
PM_REMOVE = 0x0001
WM_CREATE = 0x0001
WM_DESTROY = 0x0002
WM_SIZE = 0x0005
WM_PAINT = 0x000F
WM_QUIT = 0x0012
WM_ERASEBKGND = 0x0014
WM_ACTIVATEAPP = 0x001C
WM_KEYDOWN = 0x0100
WM_KEYUP = 0x0101
WM_SYSKEYDOWN = 0x0104
WM_SYSKEYUP = 0x0105
WM_SYSCOMMAND = 0x0112
SC_KEYMENU = 0xF100
GWL_STYLE = -16
MONITOR_DEFAULTTOPRIMARY = 0x1
SWP_NOSIZE = 0x0001
SWP_NOMOVE = 0x0002
SWP_NOZORDER = 0x0004
SWP_FRAMECHANGED = 0x0020
VK_RETURN = 0x0D
VK_MENU = 0x12
VK_ESCAPE = 0x1B
VK_F4 = 0x73
VK_F10 = 0x79
VK_F11 = 0x7A

HDC = &terralib.types.newstruct("HDC__")
HWND = &terralib.types.newstruct("HWND__")
HMENU = &terralib.types.newstruct("HMENU__")
HICON = &terralib.types.newstruct("HICON__")
HBRUSH = &terralib.types.newstruct("HBRUSH__")
HCURSOR = &terralib.types.newstruct("HCURSOR__")
HMONITOR = &terralib.types.newstruct("HMONITOR__")
WNDPROC = {HWND, uint32, intptr, ptrdiff} -> ptrdiff
struct POINT {
	x: int32;
	y: int32;
}
struct RECT {
	left: int32;
	top: int32;
	right: int32;
	bottom: int32;
}
struct WNDCLASSEXW {
	cbSize: uint32;
	style: uint32;
	lpfnWndProc: WNDPROC;
	cbClsExtra: int32;
	cbWndExtra: int32;
	hInstance: HINSTANCE;
	hIcon: HICON;
	hCursor: HCURSOR;
	hbrBackground: HBRUSH;
	lpszMenuName: &int16;
	lpszClassName: &int16;
	hIconSm: HICON;
}
struct MSG {
	hwnd: HWND;
	message: uint32;
	wParam: intptr;
	lParam: ptrdiff;
	time: uint32;
	pt: POINT;
	lPrivate: uint32;
}
struct WINDOWPLACEMENT {
	length: uint32;
	flags: uint32;
	showCmd: uint32;
	ptMinPosition: POINT;
	ptMaxPosition: POINT;
	rcNormalPosition: RECT;
	rcDevice: RECT;
}
struct MONITORINFO {
	cbSize: uint32;
	rcMonitor: RECT;
	rcWork: RECT;
	dwFlags: uint32;
}

HWND_TOP = constant(HWND, 0) -- @Hack this should be above the declaration, but can't be.

User32 = {
	{"SetProcessDPIAware", {} -> int32},
	{"LoadIconW", {HINSTANCE, &int16} -> HICON},
	{"LoadCursorW", {HINSTANCE, &int16} -> HCURSOR},
	{"RegisterClassExW", &WNDCLASSEXW -> uint16},
	{"CreateWindowExW", {uint32, &int16, &int16, uint32, int32, int32, int32, int32, HWND, HMENU, HINSTANCE, &opaque} -> HWND},
	{"PeekMessageW", {&MSG, HWND, uint32, uint32, uint32} -> int32},
	{"TranslateMessage", &MSG -> int32},
	{"DispatchMessageW", &MSG -> ptrdiff},
	{"DefWindowProcW", {HWND, uint32, intptr, ptrdiff} -> ptrdiff},
	{"PostQuitMessage", int32 -> {}},
	{"GetDC", HWND -> HDC},
	{"ValidateRect", {HWND, &RECT} -> int32},
	{"ClipCursor", &RECT -> int32},
	{"DestroyWindow", HWND -> int32},
	{"GetWindowLongPtrW", {HWND, int32} -> ptrdiff},
	{"SetWindowLongPtrW", {HWND, int32, ptrdiff} -> ptrdiff},
	{"GetWindowPlacement", {HWND, &WINDOWPLACEMENT} -> int32},
	{"SetWindowPlacement", {HWND, &WINDOWPLACEMENT} -> int32},
	{"SetWindowPos", {HWND, HWND, int32, int32, int32, int32, uint32} -> int32},
	{"MonitorFromWindow", {HWND, uint32} -> HMONITOR},
	{"GetMonitorInfoW", {HMONITOR, &MONITORINFO} -> int32},
}

-- Ws2_32
WSADESCRIPTION_LEN = 256
WSASYS_STATUS_LEN = 128

struct WSADATA32 {
	wVersion: uint16;
	wHighVersion: uint16;
	szDescription: int8[WSADESCRIPTION_LEN + 1];
	szSystemStatus: int8[WSASYS_STATUS_LEN + 1];
	iMaxSockets: uint16;
	iMaxUdpDg: uint16;
	lpVendorInfo: &int8;
}
struct WSADATA64 {
	wVersion: uint16;
	wHighVersion: uint16;
	iMaxSockets: uint16;
	iMaxUdpDg: uint16;
	lpVendorInfo: &int8;
	szDescription: int8[WSADESCRIPTION_LEN + 1];
	szSystemStatus: int8[WSASYS_STATUS_LEN + 1];
}
WSADATA = CPU_BITS == 32 and WSADATA32 or WSADATA64

Ws2_32 = {
	{"WSAStartup", {uint16, &WSADATA} -> int32},
	{"WSACleanup", {} -> int32},
}

-- Dwmapi
DWMWA_USE_IMMERSIVE_DARK_MODE = 20
DWMWA_WINDOW_CORNER_PREFERENCE = 33
DWMWCP_DONOTROUND = 1

Dwmapi = {
	{"DwmSetWindowAttribute", {HWND, uint32, &opaque, uint32} -> HRESULT},
}

-- Winmm
TIMERR_NOERROR = 0

Winmm = {
	{"timeBeginPeriod", uint32 -> uint32},
}
