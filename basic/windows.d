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
	noreturn ExitProcess(uint status);
}

// User32
extern(Windows) @foreign("User32") {
	int SetProcessDPIAware();
}
