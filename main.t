memset64 = terralib.intrinsic("llvm.memset.p0.i64", {&opaque, int8, int64, bool} -> {})

memset = macro(function(addr, c, count)
	return `memset64(addr, c, count, false)
end)

require "main_windows"

local winx64target = terralib.newtarget {
	Triple = "x86_64-pc-windows-msvc";
}

terralib.saveobj("OriginZero.exe", {WinMainCRTStartup=WinMainCRTStartup}, {"Kernel32.lib", "-debug", "-incremental:no", "-subsystem:windows"}, winx64target, false)
