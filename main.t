require "main_windows"

local winx64target = terralib.newtarget {
	Triple = "x86_64-pc-windows-msvc";
}

terralib.saveobj("OriginZero.exe", {WinMainCRTStartup=WinMainCRTStartup}, {"Kernel32.lib", "-debug", "-incremental:no", "-subsystem:windows"}, winx64target, false)
