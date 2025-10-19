module basic.windows;

import basic : foreign;

// Kernel32
enum MEM_COMMIT = 0x00001000;
enum MEM_RESERVE = 0x00002000;
enum PAGE_READWRITE = 0x04;

alias HRESULT = int;
alias HANDLE = void*;
struct HINSTANCE__; alias HINSTANCE = HINSTANCE__*;
alias HMODULE = HINSTANCE;
alias PROC = extern(Windows) ptrdiff_t function();

@foreign("Kernel32") extern(Windows) {
	HMODULE GetModuleHandleW(const(wchar)*);
	HMODULE LoadLibraryW(const(wchar)*);
	PROC GetProcAddress(HMODULE, const(char)*);
	int QueryPerformanceCounter(long*);
	int QueryPerformanceFrequency(long*);
	void Sleep(uint);
	void* VirtualAlloc(void*, size_t, uint, uint);
	noreturn ExitProcess(uint);
}

// User32
enum CS_OWNDC = 0x0020;
enum IDI_WARNING = cast(const(wchar)*) 32515;
enum IDC_CROSS = cast(const(wchar)*) 32515;
enum WS_MAXIMIZEBOX = 0x00010000;
enum WS_MINIMIZEBOX = 0x00020000;
enum WS_THICKFRAME = 0x00040000;
enum WS_SYSMENU = 0x00080000;
enum WS_CAPTION = 0x00C00000;
enum WS_VISIBLE = 0x10000000;
enum WS_OVERLAPPEDWINDOW = WS_CAPTION | WS_SYSMENU | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX;
enum CW_USEDEFAULT = 0x80000000;
enum PM_REMOVE = 0x0001;
enum WM_CREATE = 0x0001;
enum WM_DESTROY = 0x0002;
enum WM_SIZE = 0x0005;
enum WM_PAINT = 0x000F;
enum WM_QUIT = 0x0012;
enum WM_ERASEBKGND = 0x0014;
enum WM_ACTIVATEAPP = 0x001C;
enum WM_KEYDOWN = 0x0100;
enum WM_KEYUP = 0x0101;
enum WM_SYSKEYDOWN = 0x0104;
enum WM_SYSKEYUP = 0x0105;
enum WM_SYSCOMMAND = 0x0112;
enum SC_KEYMENU = 0xF100;
enum VK_RETURN = 0x0D;
enum VK_MENU = 0x12;
enum VK_ESCAPE = 0x1B;
enum VK_F4 = 0x73;
enum VK_F10 = 0x79;
enum VK_F11 = 0x7A;

struct HDC__; alias HDC = HDC__*;
struct HWND__; alias HWND = HWND__*;
struct HMENU__; alias HMENU = HMENU__*;
struct HICON__; alias HICON = HICON__*;
struct HBRUSH__; alias HBRUSH = HBRUSH__*;
struct HCURSOR__; alias HCURSOR = HCURSOR__*;
struct HMONITOR__; alias HMONITOR = HMONITOR__*;
alias WNDPROC = extern(Windows) ptrdiff_t function(HWND, uint, size_t, ptrdiff_t);
struct POINT {
	int x;
	int y;
}
struct RECT {
	int left;
	int top;
	int right;
	int bottom;
}
struct WNDCLASSEXW {
  uint          cbSize;
  uint          style;
  WNDPROC       lpfnWndProc;
  int           cbClsExtra;
  int           cbWndExtra;
  HINSTANCE     hInstance;
  HICON         hIcon;
  HCURSOR       hCursor;
  HBRUSH        hbrBackground;
  const(wchar)* lpszMenuName;
  const(wchar)* lpszClassName;
  HICON         hIconSm;
}
struct MSG {
  HWND      hwnd;
  uint      message;
  size_t    wParam;
  ptrdiff_t lParam;
  uint      time;
  POINT     pt;
  uint      lPrivate;
}

@foreign("User32") extern(Windows) {
	int SetProcessDPIAware();
	HICON LoadIconW(HINSTANCE, const(wchar)*);
	HCURSOR LoadCursorW(HINSTANCE, const(wchar)*);
	ushort RegisterClassExW(const(WNDCLASSEXW)*);
	HWND CreateWindowExW(uint, const(wchar)*, const(wchar)*, uint, int, int, int, int, HWND, HMENU, HINSTANCE, void*);
	int PeekMessageW(MSG*, HWND, uint, uint, uint);
	int TranslateMessage(const(MSG)*);
	ptrdiff_t DispatchMessageW(const(MSG)*);
	ptrdiff_t DefWindowProcW(HWND, uint, size_t, ptrdiff_t);
	void PostQuitMessage(int);
	HDC GetDC(HWND);
	int ValidateRect(HWND, const(RECT)*);
	int DestroyWindow(HWND);
}

// Ws2_32
enum WSADESCRIPTION_LEN = 256;
enum WSASYS_STATUS_LEN = 128;

struct WSADATA32 {
	ushort wVersion;
	ushort wHighVersion;
	char[WSADESCRIPTION_LEN + 1] szDescription;
	char[WSASYS_STATUS_LEN + 1] szSystemStatus;
	ushort iMaxSockets;
	ushort iMaxUdpDg;
	char* lpVendorInfo;
}
struct WSADATA64 {
	ushort wVersion;
	ushort wHighVersion;
	ushort iMaxSockets;
	ushort iMaxUdpDg;
	char* lpVendorInfo;
	char[WSADESCRIPTION_LEN + 1] szDescription;
	char[WSASYS_STATUS_LEN + 1] szSystemStatus;
}
version (Win32) alias WSADATA = WSADATA32;
version (Win64) alias WSADATA = WSADATA64;

@foreign("Ws2_32") extern(Windows) {
	int WSAStartup(ushort, WSADATA*);
	int WSACleanup();
}

// Dwmapi
enum DWMWA_USE_IMMERSIVE_DARK_MODE = 20;
enum DWMWA_WINDOW_CORNER_PREFERENCE = 33;
enum DWMWCP_DONOTROUND = 1;

@foreign("Dwmapi") extern(Windows) {
	HRESULT DwmSetWindowAttribute(HWND, uint, const(void)*, uint);
}

// Winmm
enum TIMERR_NOERROR = 0;

@foreign("Winmm") extern(Windows) {
	uint timeBeginPeriod(uint);
}
