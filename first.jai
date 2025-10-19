#import "Compiler";
Jaiwalker :: #import "Jaiwalker";

build :: () {
	set_build_options_dc(.{do_output=false});
	Jaiwalker.compile(.{
		files=.["main.jai"],
		strings=.["DEBUG :: 1;"],
		output_path="build_debug",
		output_executable_name="OriginZero",
		entry_point_name="WinMainCRTStartup",
		os_target=.WINDOWS,
		cpu_target=.X64,
		subsystem=.WINDOWS,
	});
}

#run build();
