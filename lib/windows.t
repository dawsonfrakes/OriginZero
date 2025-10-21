HINSTANCE = &terralib.types.newstruct("HINSTANCE__")
HMODULE = HINSTANCE
PROC = &({} -> ptrdiff)

Kernel32 = {
	{"GetModuleHandleW", {&int16} -> HMODULE},
	{"LoadLibraryW", {&int16} -> HMODULE},
	{"GetProcAddress", {HMODULE, &int8} -> PROC},
	{"ExitProcess", {uint32} -> {}},
}

User32 = {
	{"SetProcessDPIAware", {} -> int32},
}
