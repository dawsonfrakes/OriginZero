#if OS == .WINDOWS {
	Kernel32 :: #library,system "Kernel32";

	ExitProcess :: (status: u32) #foreign Kernel32;

	WinMainCRTStartup :: () #c_call {
		ExitProcess(0);
	}
}
