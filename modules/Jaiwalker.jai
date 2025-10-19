#module_parameters(JAIWALKER_DECLARATIONS_ONLY := false);

Jaiwalker_OS_Tag :: enum u32 {
	NONE      :: 0;
	KRAMPOS   :: 1;
	WINDOWS   :: 2;
	LINUX     :: 3;
	ANDROID   :: 4;
	IOS       :: 5;
	MACOS     :: 6;
	NN_SWITCH :: 7;
	PS4       :: 8;
	PS5       :: 9;
	XBOX      :: 10;
	WASM      :: 11;
	OUNCE     :: 12;
}

Jaiwalker_CPU_Tag :: enum u32 {
	UNINITIALIZED :: 0;
	KRAMPU        :: 1;
	CUSTOM        :: 2;
	X64           :: 3;
	ARM64         :: 4;
}

Jaiwalker_Output_Type :: enum u8 {
	NO_OUTPUT       :: 0;
	EXECUTABLE      :: 1;
	DYNAMIC_LIBRARY :: 2;
	STATIC_LIBRARY  :: 3;
	OBJECT_FILE     :: 4;
}

Jai_Backend :: enum u32 {
	X64       :: 0;
	LLVM      :: 1;
	JAIWALKER :: 42;
}

Jaiwalker_Config :: struct {
	files:   [] string;
	strings: [] string;

	output_path:            string;
	intermediate_path:      string;
	output_executable_name: string;
	entry_point_name:       string;

	os_target:  Jaiwalker_OS\_Tag = xx OS;
	cpu_target: Jaiwalker_CPU_Tag = xx CPU;
	backend := Jai_Backend.JAIWALKER;

	subsystem: enum u8 {
		CNOSOLE :: 0;
		WINDOWS :: 1;
	};

	write_added_strings := true;
	text_output_flags: enum_flags u32 {
		OUTPUT_LINK\ _LINE :: 0x1;
		OUTPUT_TIMING_INFO :: 0x2;
	} = xx 3;
}

#if !JAIWALKER_DECLARATIONS_ONLY {
	compile :: (config: Jaiwalker_Config, loc := #caller_location) {
		options := get_build_options();
		options.output_type                   = .NO_OUTPUT;
		options.intermediate_path             = config.intermediate_path;
		options.write_added_strings           = config.write_added_strings;
		options.runtime_support_definitions   = .OMIT;
		options.runtime_storageless_type_info = true;
		options.temporary_storage_size        = 0;

		frontend_start := current_time_consensus();

		w := compiler_create_workspace();
		set_build_options(options, w);
		compiler_begin_intercept(w);
		remap_import(w, "", "Runtime_Support", "Minimal_Runtime_Support");
		add_constants(config, w);
		for config.strings add_build_string(it, w);
		for config.files   add_build_file(it, w, loc);

		success: bool = ---;
		global_scope: [..] *Code_Declaration;
		while true {
			message := compiler_wait_for_message();
			if !message || message.workspace != w continue;
			if message.kind == {
			case .COMPLETE;
				success = message.(*Message_Complete).error_code == xx 0;
				break;
			case .TYPECHECKED;
				tc := message.(*Message_Typechecked);
				for tc.declarations {
					decl := it.expression;
					file := get_filename(decl);
					if ends_with(file, "/Preload.jai") continue;
					if ends_with(file, "/Minimal_Runtime_Support.jai") continue;
					array_add(*global_scope, decl);
				}
			}
		}

		frontend_end := current_time_consensus();

		while success {
			entry_point_name       := ifx config.entry_point_name else "main";
			output_path            := ifx config.output_path else ".";
			intermediate_path      := ifx config.intermediate_path else ".build";
			output_executable_name := ifx config.output_executable_name else ifx config.files basename(config.files[0]) else basename(loc.fully_pathed_filename);

			// make_directory_if_it_does_not_exist(output_path); // default jai doesn't do this for some reason?
			make_directory_if_it_does_not_exist(intermediate_path);

			entry_decl := resolve_declaration_slowly_by_walking_scopes(entry_point_name, null, global_scope).code;
			if !entry_decl {
				print("I do not see the specified entry point '%'.\n", entry_point_name, to_standard_error=true);
				break;
			}
			if !entry_decl.expression || entry_decl.expression.kind != .PROCEDURE_HEADER {
				print("I see the specified entry point '%', but it is not a procedure.\n", entry_point_name, to_standard_error=true);
				break;
			}
			entry_header := entry_decl.expression.(*Code_Procedure_Header);
			if !entry_header.body_or_null {
				print("I see the specified entry point '%', but it does not have a procedure body.\n", entry_point_name, to_standard_error=true);
				break;
			}

			referenced := find_procedures_referenced_by_code(entry_header, null, global_scope);

			b: String_Builder;
			c: CPrinter;
			c.b = *b;
			c.global_scope = global_scope;

			print(*b, #string LANG_C
// Type definitions
typedef signed char s8;
typedef short s16;
typedef int s32;
typedef long long s64;

typedef unsigned char u8;
typedef unsigned short u16;
typedef unsigned int u32;
typedef unsigned long long u64;
LANG_C);
			print(*b, "\n// Declarations\n");
			for < referenced {
				print_c_procedure_declaration(*c, it);
				print(*b, "\n");
			}
			print(*b, "\n// Definitions\n");
			for < referenced {
				if !it.code.body_or_null continue;
				print_c_procedure_definition(*c, it);
				print(*b, "\n\n");
			}

			s := builder_to_string(*b);
			defer free(s);

			filepath := join(intermediate_path, "/", "generated.c");
			defer free(filepath);

			// print("%", s);
			write_entire_file(filepath, s);

			system_libraries: [..] string;
			user\ _libraries: [..] string;
			for < referenced {
				library := find_library_of_procedure(it, global_scope);
				if !library continue;
				array := ifx library.library_flags & .IS_SYSTEM_LIBRARY then *system_libraries else *user_libraries;
				array_add_if_unique(array, library.name);
			}

			cmd: [..] string;
			array_add(*cmd, "tcc");
			array_add(*cmd, "-nostdlib");
			array_add(*cmd, "-o", join(output_path, "/", output_executable_name, ".exe"));
			array_add(*cmd, join("-D", entry_point_name, "=_start"));
			array_add(*cmd, filepath);
			for system_libraries array_add(*cmd, join("-l", it));
			array_add(*cmd, ifx config.subsystem == .WINDOWS "-Wl,-subsystem,windows" else "-Wl,-subsystem,console");

			if config.text_output_flags & .OUTPUT_LINK_LINE print("%\n", join(..cmd, " "));
			status := run_command(..cmd);
			if status.exit_code != 0 break;

			backend_end := current_time_consensus();

			if config.text_output_flags & .OUTPUT_TIMING_INFO {
				frontend_ms := to_milliseconds(frontend_end - frontend_start);
				backend\_ms := to_milliseconds(backend\_end - frontend_end);
				total\  _ms := frontend_ms + backend_ms;
				print("Front-end % millisecond%.\n", FormatInt.{value=frontend_ms, minimum_digits=4, padding=#char " "}, ifx frontend_ms != 1 "s");
				print("Back-end  % millisecond%.\n", FormatInt.{value=backend\_ms, minimum_digits=4, padding=#char " "}, ifx backend\_ms != 1 "s");
				print("Total     % millisecond%.\n", FormatInt.{value=total\  _ms, minimum_digits=4, padding=#char " "}, ifx total\  _ms != 1 "s");
			}
			break;
		}

		compiler_end_intercept(w);
		compiler_destroy_workspace(w);
	}

	add_constants :: (options_or_config: $T, w: Workspace)
	#modify { return T == Build_Options || T == Jaiwalker_Config; }
	{
		s := sprint(#string LANG_JAI
#import,file "%"(JAIWALKER_DECLARATIONS_ONLY=true);
OS      :: Jaiwalker_OS\_Tag.%;
CPU     :: Jaiwalker_CPU_Tag.%;
BACKEND :: Jai\     _Backend.%;
LANG_JAI,
			#file,
			options_or_config.os_target,
			options_or_config.cpu_target,
			options_or_config.backend);
		add_build_string(s, w);
		free(s);
	}

	#scope_module

	find_declaration_slowly :: (name: string, entries: [] *$T/Code_Scope_Entry) -> *Code_Declaration {
		for entries if it.name == name {
			assert(it.kind == .DECLARATION);
			return it.(*Code_Declaration);
		}
		return null;
	}

	Scope_Entry :: struct (T: Type) {
		block: *Code_Block;
		code: T;
	}

	operator == :: (a: $T/Scope_Entry, b: T) -> bool {
		return a.block == b.block && a.code == b.code;
	}

	find_declaration_slowly_by_walking_scopes :: (name: string, block: *Code_Block, global_scope: [] *Code_Declaration) -> Scope_Entry(*Code_Declaration) {
		while block {
			decl := find_declaration_slowly(name, block.members);
			if decl return .{block, decl};
			block = block.parent;
		}
		return .{null, find_declaration_slowly(name, global_scope)};
	}

	resolve_declaration_slowly_by_walking_scopes :: (name: string, block: *Code_Block, global_scope: [] *Code_Declaration) -> Scope_Entry(*Code_Declaration) {
		entry := find_declaration_slowly_by_walking_scopes(name, block, global_scope);
		while entry.code && entry.code.expression && entry.code.expression.kind == .IDENT {
			entry = find_declaration_slowly_by_walking_scopes(entry.code.expression.(*Code_Ident).name, entry.block, global_scope);
		}
		return entry;
	}

	find_procedures_referenced_by_code :: (code: *Code_Node, block: *Code_Block, global_scope: [] *Code_Declaration) -> [..] Scope_Entry(*Code_Procedure_Header) {
		visit :: (result: *[..] Scope_Entry(*Code_Procedure_Header), code: *Code_Node, block: *Code_Block, global_scope: [] *Code_Declaration) {
			if code.kind == {
			case .LITERAL;            // nothing to do here.
			case .TYPE_INSTANTIATION; // nothing to do here.
			case .PROCEDURE_HEADER;
				header := code.(*Code_Procedure_Header);
				array_add_if_unique(result, .{block, header});
				if !(header.procedure_flags & .MACRO) && header.body_or_null
					for header.body_or_null.block.statements
						visit(result, it, header.body_or_null.block, global_scope);
			case .PROCEDURE_CALL;
				call := code.(*Code_Procedure_Call);
				header := call.resolved_procedure_expression.(*Code_Procedure_Header);
				if header.kind != .PROCEDURE_HEADER return; // we were a struct instantiation.
				if header.procedure_flags & .MACRO {
					for call.macro_expansion_block.statements
						visit(result, it, block, global_scope);
				} else {
					visit(result, header, block, global_scope);
				}
				for call.arguments_sorted visit(result, it, block, global_scope);
			case;
				print("Unhandled(%).\n", code.kind);
			}
		}

		result: [..] Scope_Entry(*Code_Procedure_Header);
		visit(*result, code, block, global_scope);
		return result;
	}

	find_library_of_procedure :: (entry: Scope_Entry(*Code_Procedure_Header), global_scope: [] *Code_Declaration) -> *Code_Directive_Library {
		if !entry.code.library_identifier return null;
		library_decl := resolve_declaration_slowly_by_walking_scopes(entry.code.library_identifier.name, entry.block, global_scope).code;
		assert(library_decl.expression.kind == .DIRECTIVE_LIBRARY);
		return library_decl.expression.(*Code_Directive_Library);
	}

	CPrinter :: struct {
		b: *String_Builder;
		global_scope: [] *Code_Declaration;
		level: s64;
	}

	print_c_type :: (using c: *CPrinter, info: *Type_Info) {
		if info.type == {
		case .VOID; print(b, "void");
		case .INTEGER; print(b, "%0%", ifx info.(*Type_Info_Integer).signed "s" else "u", info.runtime_size * 8);
		case;
			print(b, "UnhandledType(%)", info.type);
		}
	}

	print_c_block :: (using c: *CPrinter, block: *Code_Block) {
		if level != 0 for 0..level-1 print(b, "  ");
		print(b, "{\n");
		level += 1;
		for block.statements {
			if it.kind != .BLOCK for 0..level-1 print(b, "  ");
			print_c_statement(c, it, block);
			print(b, "\n");
		}
		level -= 1;
		for 0..level-1 print(b, "  ");
		print(b, "}");
	}

	print_c_expression :: (using c: *CPrinter, code: *Code_Node, block: *Code_Block) {
		if code.kind == {
		case .LITERAL;
			literal := code.(*Code_Literal);
			if literal.value_type == .NUMBER
				print(b, "%", literal._s64);
			else
				print(b, "UnhandledLiteral(%)", literal.value_type);
		case .PROCEDURE_CALL;
			call := code.(*Code_Procedure_Call);
			header := call.resolved_procedure_expression.(*Code_Procedure_Header);
			if header.kind != .PROCEDURE_HEADER {
				print(b, "/* struct instantiation. */");
				return;
			}
			print(b, "%(", header.name);
			for call.arguments_sorted {
				if it_index print(", ");
				print_c_expression(c, it, block);
			}
			print(b, ")");
		case;
			print(b, "UnhandledExpr(%)", code.kind);
		}
	}

	print_c_statement :: (using c: *CPrinter, code: *Code_Node, block: *Code_Block) {
		if code.kind == .BLOCK {
			print_c_block(c, code.(*Code_Block));
		} else {
			print_c_expression(c, code, block);
			print(b, ";");
		}
	}

	print_c_procedure_header :: (using c: *CPrinter, entry: Scope_Entry(*Code_Procedure_Header)) {
		print_c_type(c, ifx entry.code.returns entry.code.returns[0].type_inst.result else type_info(void));
		print(b, " %(", entry.code.name);
		if !entry.code.arguments print(b, "void");
		for entry.code.arguments {
			if it_index print(b, ", ");
			print_c_type(c, it.type_inst.result);
			print(b, " %", it.name);
		}
		print(b, ")");
	}

	print_c_procedure_declaration :: (using c: *CPrinter, entry: Scope_Entry(*Code_Procedure_Header)) {
		print_c_procedure_header(c, entry);
		print(b, ";");
		library := find_library_of_procedure(entry, global_scope);
		if library print(b, " // library=%", library.name);
	}

	print_c_procedure_definition :: (using c: *CPrinter, entry: Scope_Entry(*Code_Procedure_Header)) {
		print_c_procedure_header(c, entry);
		print(b, " ");
		print_c_block(c, entry.code.body_or_null.block);
	}

	using Basic :: #import "Basic";
	#import "Compiler";
	#import "Process";
	#import "File";
	#import "String";

	#poke_name Basic operator ==;
}
