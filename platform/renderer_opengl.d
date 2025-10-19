import basic;
import platform.globals;
static import game;

version (Windows) {
	static import basic.opengl;
	static foreach (it; __traits(allMembers, basic.opengl)[1..$]) {
		static if (has_uda!(__traits(getMember, basic.opengl, it), basic.opengl.gl_version)) {
			mixin("__gshared typeof(basic.opengl."~it~")* "~it~";");
		} else {
			mixin("alias "~it~" = basic.opengl."~it~";");
		}
	}

	void opengl_platform_init() {
		HMODULE Opengl32_dll = GetModuleHandleW("OPENGL32.DLL");
		static foreach (it; __traits(allMembers, basic.opengl)[1..$]) {
			static if (has_uda!(__traits(getMember, basic.opengl, it), basic.opengl.gl_version)) {
				static if (get_uda!(__traits(getMember, basic.opengl, it), basic.opengl.gl_version).major == 1) {
					mixin(it~" = cast(typeof("~it~")) GetProcAddress(Opengl32_dll, \""~it~"\");");
				} else {
					mixin(it~" = cast(typeof("~it~")) wglGetProcAddress(\""~it~"\");");
				}
			}
		}

		PIXELFORMATDESCRIPTOR pfd;
		pfd.nSize = PIXELFORMATDESCRIPTOR.sizeof;
		pfd.nVersion = 1;
		pfd.dwFlags = PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER | PFD_DEPTH_DONTCARE;
		pfd.cColorBits = 24;
		int format = ChoosePixelFormat(platform_hdc, &pfd);
		SetPixelFormat(platform_hdc, format, &pfd);

		HGLRC temp_ctx = wglCreateContext(platform_hdc);
		wglMakeCurrent(platform_hdc, temp_ctx);
	}

	void opengl_platform_deinit() {
		// if (opengl_platform_context) wglDeleteContext(opengl_platform_context);
		// opengl_platform_context = null;
	}

	void opengl_platform_resize() {

	}

	void opengl_platform_present(game.Output* output) {
		SwapBuffers(platform_hdc);
	}
}

void opengl_init() {
	opengl_platform_init();
}

void opengl_deinit() {
	opengl_platform_deinit();
}

void opengl_resize() {
	opengl_platform_resize();
}

void opengl_present(game.Output* output) {
	opengl_platform_present(output);
}
