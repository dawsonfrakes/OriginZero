import basic;
static import game;

enum Render_Api_Flags : uint {
	NONE = 0x1,
	OPENGL = 0x2,
}

version (Windows) {
	enum RENDER_APIS = Render_Api_Flags.NONE | Render_Api_Flags.OPENGL;

	static import basic.windows;
	static foreach (it; __traits(allMembers, basic.windows)[1..$]) {
		static if (has_uda!(__traits(getMember, basic.windows, it), foreign) && !string_equal(get_uda!(__traits(getMember, basic.windows, it), foreign).library, "Kernel32")) {
			mixin("__gshared typeof(basic.windows."~it~")* "~it~";");
		} else {
			mixin("alias "~it~" = basic.windows."~it~";");
		}
	}

	__gshared {
		Render_Api_Flags platform_render_api = Render_Api_Flags.OPENGL;
		HINSTANCE platform_hinstance;
		HWND platform_hwnd;
		HDC platform_hdc;
		ushort platform_width;
		ushort platform_height;
		bool[128] platform_keys;
		byte[128] platform_key_transitions;
	}
}

version (Steam) {
	static import basic.steam;
	static foreach (it; __traits(allMembers, basic.steam)[1..$]) {
		static if (has_uda!(__traits(getMember, basic.steam, it), foreign)) {
			mixin("__gshared typeof(basic.steam."~it~")* "~it~";");
		} else {
			mixin("alias "~it~" = basic.steam."~it~";");
		}
	}
}

static if (RENDER_APIS & Render_Api_Flags.OPENGL) {
	import platform.renderer_opengl;
}

void renderer_init() {
	switch (platform_render_api) {
		case Render_Api_Flags.OPENGL:
			static if (RENDER_APIS & Render_Api_Flags.OPENGL)
				opengl_init();
			break;
		default: break;
	}
}

void renderer_deinit() {
	switch (platform_render_api) {
		case Render_Api_Flags.OPENGL:
			static if (RENDER_APIS & Render_Api_Flags.OPENGL)
				opengl_deinit();
			break;
		default: break;
	}
}

void renderer_resize() {
	switch (platform_render_api) {
		case Render_Api_Flags.OPENGL:
			static if (RENDER_APIS & Render_Api_Flags.OPENGL)
				opengl_resize();
			break;
		default: break;
	}
}

void renderer_present(game.Output* output) {
	switch (platform_render_api) {
		case Render_Api_Flags.OPENGL:
			static if (RENDER_APIS & Render_Api_Flags.OPENGL)
				opengl_present(output);
			break;
		default: break;
	}
}
