DEBUG :: 0;

#import "Basic";
#import "Compiler";
#import "File";
#import "Process";
#import "String";

build :: (debug: int) {
	build_debug :: (options: *Build_Options) {
		options.output_path = "build_debug";
	}

	build_release :: (options: *Build_Options) {
		options.output_path = "build_release";
		set_optimization(options, .OPTIMIZED, false);
	}

	set_build_options_dc(.{do_output=false});

	options := get_build_options();
	options.output_type = .EXECUTABLE;
	options.output_executable_name = "OriginZero";
	options.runtime_support_definitions = .OMIT;
	options.runtime_storageless_type_info = true;
	options.temporary_storage_size = 0;
	options.use_custom_link_command = options.os_target == .WINDOWS;
	if debug build_debug(*options); else build_release(*options);

	make_directory_if_it_does_not_exist(options.output_path);

	w := compiler_create_workspace();
	set_build_options(options, w);
	compiler_begin_intercept(w, .SKIP_ALL);
	remap_import(w, "", "Runtime_Support", "Minimal_Runtime_Support");
	add_build_string(sprint(#string LANG_JAI
	Jai_Backend :: enum u32 {
		X64  :: 0;
		LLVM :: 1;
	}
	BACKEND :: Jai_Backend.%;
	DEBUG :: %;
	LANG_JAI, options.backend, debug), w);
	add_build_file("src/platform/main.jai", w);

	while true {
		message := compiler_wait_for_message();
		if !message || message.workspace != w continue;
		if message.kind == {
		case .COMPLETE; break;
		case .PHASE;
			phase := message.(*Message_Phase);
			if phase.phase == .READY_FOR_CUSTOM_LINK_COMMAND {
				#if OS == .WINDOWS {
					#import "Windows_Resources";
					library_path, linker_path := find_visual_studio_in_a_ridiculous_garbage_way();
					root := find_windows_kit_root();

					system_libraries: [..] string;
					for phase.system_libraries {
						if it == "ucrt.lib" continue;
						if it == "libcmt.lib" continue;
						if it == "kernel32.lib" continue;
						array_add(*system_libraries, it);
					}

					cmd: [..] string;
					array_add(*cmd, join(linker_path, "\\cl.exe"));
					array_add(*cmd, "-nologo", "-W4", "-WX", "-Oi", "-J", "-EHa-", "-GR-", "-GS-", "-Gs0x10000000");
					if debug array_add(*cmd, "-Z7");
					array_add(*cmd, join("-Fe", options.output_path, "\\", phase.executable_name));
					array_add(*cmd, ..phase.compiler_generated_object_files);
					array_add(*cmd, ..phase.support_object_files);
					array_add(*cmd, ..system_libraries);
					array_add(*cmd, ..phase.user\ _libraries);
					array_add(*cmd, "-link", "-ignore:4216", "-nodefaultlib", "-incremental:no", "-subsystem:windows", "-noimplib", "-noexp");
					array_add(*cmd, "-stack:0x10000000,0x10000000", "-heap:0,0");
					array_add(*cmd, join("-libpath:", library_path));
					array_add(*cmd, join("-libpath:", root, "\\um\\x64"));

					if options.text_output_flags & .OUTPUT_LINK_LINE print("%\n", join(..cmd, " "));
					status := run_command(..cmd);
					phase.linker_exit_code = status.exit_code;
				}
				compiler_custom_link_command_is_complete(w);
			}
		}
	}

	compiler_end_intercept(w);
	compiler_destroy_workspace(w);
}

#run build(DEBUG);
