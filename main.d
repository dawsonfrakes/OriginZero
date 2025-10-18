import basic;

version (Windows) {
	static import basic.windows;
	static foreach (it; __traits(allMembers, basic.windows)[1..$]) {
		static if (has_uda!(__traits(getMember, basic.windows, it), foreign) && !string_equal(get_uda!(__traits(getMember, basic.windows, it), foreign).library, "Kernel32")) {
			mixin("__gshared typeof(basic.windows."~it~")* "~it~";");
		} else {
			mixin("alias "~it~" = basic.windows."~it~";");
		}
	}

	__gshared {
		HINSTANCE platform_hinstance;
	}

	extern(Windows) noreturn WinMainCRTStartup() {
		HMODULE User32_dll = LoadLibraryW("USER32.DLL");

		static foreach (it; __traits(allMembers, basic.windows)[1..$]) {
			static if (has_uda!(__traits(getMember, basic.windows, it), foreign) && !string_equal(get_uda!(__traits(getMember, basic.windows, it), foreign).library, "Kernel32")) {
				mixin(it~" = cast(typeof("~it~")) GetProcAddress("~get_uda!(__traits(getMember, basic.windows, it), foreign).library~"_dll, \""~it~"\");");
			}
		}

		platform_hinstance = GetModuleHandleW(null);

		ExitProcess(0);
	}
}
