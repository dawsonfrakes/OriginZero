DEBUG = true
CPU_BITS = 64

memset64 = terralib.intrinsic("llvm.memset.p0.i64", {&opaque, int8, int64, bool} -> {})

memset = macro(function(addr, c, count)
	return `memset64(addr, c, count, false)
end)

require "main_windows"

local winx64target = terralib.newtarget {
	Triple = "x86_64-pc-windows-msvc";
}

local objstart = terralib.currenttimeinseconds()
terralib.saveobj("OriginZero.exe", {WinMainCRTStartup=WinMainCRTStartup}, {"Kernel32.lib", "-debug", "-incremental:no", "-subsystem:windows"}, winx64target, false)
local objend = terralib.currenttimeinseconds()

local objms = (objend - objstart) * 1000
print("Compilation stats:")
print("Total        " .. string.format("%.0f", objms) .. " millisecond" .. (objms ~= 1 and "s" or ""))
