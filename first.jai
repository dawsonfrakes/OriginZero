DEBUG :: 1;
RADLINKER :: true;

#import "Basic";
#import "Compiler";
#import "File";
#import "Process";
#import "String";

build :: () {
	set_build_options_dc(.{do_output=false});

	options := get_build_options();
	options.output_type = .EXECUTABLE;
	options.output_executable_name = "OriginZero";
	options.output_path = "build_debug";
	options.runtime_support_definitions = .OMIT;
	options.use_custom_link_command = options.os_target == .WINDOWS;
	options.temporary_storage_size = 0;

	make_directory_if_it_does_not_exist(options.output_path);

	w := compiler_create_workspace();
	set_build_options(options, w);
	compiler_begin_intercept(w, .SKIP_ALL);
	if !DEBUG remap_import(w, "", "Runtime_Support", "Minimal_Runtime_Support");
	add_build_string(sprint(#string LANG_JAI
	BACKEND: enum u32 { X64; LLVM; } : .%;
	DEBUG :: %;
	Renderer :: enum u32 {
		NONE :: 0;
		OPENGL :: 1;
	}
	RENDERER :: Renderer.OPENGL;
	LANG_JAI, options.backend, DEBUG), w);
	add_build_file("main.jai", w);

	while true {
		message := compiler_wait_for_message();
		if !message || message.workspace != w continue;
		if message.kind == {
		case .COMPLETE;
			break;
		case .PHASE;
			phase := message.(*Message_Phase);
			if phase.phase == .READY_FOR_CUSTOM_LINK_COMMAND {
				#if OS == .WINDOWS {
					#import "Windows_Resources";
					library_path, linker_path := find_visual_studio_in_a_ridiculous_garbage_way();
					root := find_windows_kit_root();

					entry_suffix: string;
					for phase.compiler_generated_object_files {
						src := read_entire_file(it);
						defer free(src);
						found, remainder := contains(src, "WinMainCRTStartup_");
						if found {
							count := 0;
							while remainder[count] count += 1;
							entry_suffix = copy_string(.{count, remainder.data});
							break;
						}
					}

					system_libraries: [..]string;
					for phase.system_libraries {
						if it == "kernel32.lib" continue;
						if it == "libcmt.lib" continue;
						if it == "ucrt.lib" continue;
						array_add(*system_libraries, it);
					}

					cmd: [..]string;
					array_add(*cmd, ifx RADLINKER ".\\radlink.exe" else sprint("%\\link.exe", linker_path));
					array_add(*cmd, sprint("-libpath:%", library_path));
					array_add(*cmd, sprint("-libpath:%\\um\\x64", root));
					array_add(*cmd, sprint("-out:%\\%", options.output_path, phase.executable_name));
					if DEBUG array_add(*cmd, "-debug");
					array_add(*cmd, "-nologo", "-incremental:no", "-nodefaultlib", "-subsystem:windows", "-noexp", "-noimplib", "-stack:0x10000000,0x10000000");
					array_add(*cmd, ifx options.backend == .LLVM sprint("-entry:WinMainCRTStartup_%", entry_suffix) else "-entry:WinMainCRTStartup"); // @Cleanup This whole idea is ugly.
					array_add(*cmd, ..phase.compiler_generated_object_files);
					array_add(*cmd, ..phase.support_object_files);
					array_add(*cmd, ..system_libraries);
					array_add(*cmd, ..phase.user_libraries);

					if options.text_output_flags & .OUTPUT_LINK_LINE print("%\n", join(..cmd, " "));
					status := run_command(..cmd);
					phase.linker_exit_code = status.exit_code;
				}
				compiler_custom_link_command_is_complete(w);
			}
		}
	}

	compiler_end_intercept(w);
}

#run build();
