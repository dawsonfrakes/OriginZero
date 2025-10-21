-- Kernel32
HINSTANCE = &terralib.types.newstruct("HINSTANCE__")
HMODULE = HINSTANCE
PROC = &({} -> ptrdiff)

Kernel32 = {
	{"GetModuleHandleW", {&int16} -> HMODULE},
	{"LoadLibraryW", {&int16} -> HMODULE},
	{"GetProcAddress", {HMODULE, &int8} -> PROC},
	{"ExitProcess", {uint32} -> {}},
}

-- User32
HDC = &terralib.types.newstruct("HDC__")
HWND = &terralib.types.newstruct("HWND__")
HMENU = &terralib.types.newstruct("HMENU__")
HICON = &terralib.types.newstruct("HICON__")
HBRUSH = &terralib.types.newstruct("HBRUSH__")
HCURSOR = &terralib.types.newstruct("HCURSOR__")
HMONITOR = &terralib.types.newstruct("HMONITOR__")
WNDPROC = &({HWND, uint32, intptr, ptrdiff} -> ptrdiff)
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

User32 = {
	{"SetProcessDPIAware", {} -> int32},
}
