module basic.windows;

import basic : foreign;

// Kernel32
struct HINSTANCE__; alias HINSTANCE = HINSTANCE__*;
alias HMODULE = HINSTANCE;
alias PROC = extern(Windows) ptrdiff_t function();

extern(Windows) @foreign("Kernel32") {
	HMODULE GetModuleHandleW(const(wchar)*);
	HMODULE LoadLibraryW(const(wchar)*);
	PROC GetProcAddress(HMODULE, const(char)*);
	noreturn ExitProcess(uint);
}

// User32
enum CS_OWNDC = 0x0020;
enum IDI_WARNING = cast(const(wchar)*) 32515;
enum IDC_CROSS = cast(const(wchar)*) 32515;
enum PM_REMOVE = 0x0001;
enum WM_CREATE = 0x0001;
enum WM_DESTROY = 0x0002;

struct HDC__; alias HDC = HDC__*;
struct HWND__; alias HWND = HWND__*;
struct HMENU__; alias HMENU = HMENU__*;
struct HICON__; alias HICON = HICON__*;
struct HBRUSH__; alias HBRUSH = HBRUSH__*;
struct HCURSOR__; alias HCURSOR = HCURSOR__*;
struct HMONITOR__; alias HMONITOR = HMONITOR__*;
alias WNDPROC = extern(Windows) ptrdiff_t function(HWND, uint, size_t, ptrdiff_t);
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

extern(Windows) @foreign("User32") {
	int SetProcessDPIAware();
	HICON LoadIconW(HINSTANCE, const(wchar)*);
	HCURSOR LoadCursorW(HINSTANCE, const(wchar)*);
	ushort RegisterClassExW(const(WNDCLASSEXW)*);
	ptrdiff_t DefWindowProcW(HWND, uint, size_t, ptrdiff_t);
	void PostQuitMessage(int);
	HDC GetDC(HWND);
}

// Winmm
enum TIMERR_NOERROR = 0;

extern(Windows) @foreign("Winmm") {
	uint timeBeginPeriod(uint);
}
