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

	__gshared HGLRC opengl_platform_context;

	void opengl_platform_init() {
		PIXELFORMATDESCRIPTOR pfd;
		pfd.nSize = PIXELFORMATDESCRIPTOR.sizeof;
		pfd.nVersion = 1;
		pfd.dwFlags = PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER | PFD_DEPTH_DONTCARE;
		pfd.cColorBits = 24;
		int format = ChoosePixelFormat(platform_hdc, &pfd);
		SetPixelFormat(platform_hdc, format, &pfd);

		HGLRC temp_ctx = wglCreateContext(platform_hdc);
		wglMakeCurrent(platform_hdc, temp_ctx);

		alias PFN_wglCreateContextAttribsARB = extern(Windows) HGLRC function(HDC, HGLRC, const(int)*);
		PFN_wglCreateContextAttribsARB wglCreateContextAttribsARB =
			cast(PFN_wglCreateContextAttribsARB)
			wglGetProcAddress("wglCreateContextAttribsARB");

		debug enum flags = WGL_CONTEXT_DEBUG_BIT_ARB;
		else  enum flags = 0;
		__gshared immutable int[9] attributes = [
			WGL_CONTEXT_MAJOR_VERSION_ARB, 4,
			WGL_CONTEXT_MINOR_VERSION_ARB, 5,
			WGL_CONTEXT_FLAGS_ARB, flags,
			WGL_CONTEXT_PROFILE_MASK_ARB, WGL_CONTEXT_CORE_PROFILE_BIT_ARB,
			0,
		];
		opengl_platform_context = wglCreateContextAttribsARB(platform_hdc, null, attributes.ptr);
		wglMakeCurrent(platform_hdc, opengl_platform_context);

		wglDeleteContext(temp_ctx);

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
	}

	void opengl_platform_deinit() {
		if (opengl_platform_context) wglDeleteContext(opengl_platform_context);
		opengl_platform_context = null;
	}

	void opengl_platform_present(game.Output* output) {
		SwapBuffers(platform_hdc);
	}
}

struct OpenGLData {
	uint main_fbo;
	uint main_fbo_color0;
	uint main_fbo_depth;
}

__gshared OpenGLData opengl;

void opengl_init() {
	opengl_platform_init();

	glCreateFramebuffers(1, &opengl.main_fbo);
	glCreateRenderbuffers(1, &opengl.main_fbo_color0);
	glCreateRenderbuffers(1, &opengl.main_fbo_depth);
}

void opengl_deinit() {
	opengl_platform_deinit();
	opengl = opengl.init;
}

void opengl_resize() {
	int color_samples_max = void;
	glGetIntegerv(GL_MAX_COLOR_TEXTURE_SAMPLES, &color_samples_max);
	int depth_samples_max = void;
	glGetIntegerv(GL_MAX_DEPTH_TEXTURE_SAMPLES, &depth_samples_max);
	uint fbo_samples = max(1, min(color_samples_max, depth_samples_max));

	glNamedRenderbufferStorageMultisample(opengl.main_fbo_color0,
		fbo_samples, GL_RGBA16F, platform_width, platform_height);
	glNamedFramebufferRenderbuffer(opengl.main_fbo, GL_COLOR_ATTACHMENT0,
		GL_RENDERBUFFER, opengl.main_fbo_color0);

	glNamedRenderbufferStorageMultisample(opengl.main_fbo_depth,
		fbo_samples, GL_DEPTH_COMPONENT32F, platform_width, platform_height);
	glNamedFramebufferRenderbuffer(opengl.main_fbo, GL_DEPTH_ATTACHMENT,
		GL_RENDERBUFFER, opengl.main_fbo_depth);
}

void opengl_present(game.Output* output) {
	__gshared immutable float[4] clear_color0 = [0.6, 0.2, 0.2, 1.0];
	glClearNamedFramebufferfv(opengl.main_fbo, GL_COLOR, 0, clear_color0.ptr);
	__gshared immutable float clear_depth = 0.0;
	glClearNamedFramebufferfv(opengl.main_fbo, GL_DEPTH, 0, &clear_depth);

	glViewport(0, 0, platform_width, platform_height);
	glBindFramebuffer(GL_FRAMEBUFFER, opengl.main_fbo);

	// @Hack for intel default framebuffer resize bug.
	glBindFramebuffer(GL_FRAMEBUFFER, 0);
	glClear(0);

	glEnable(GL_FRAMEBUFFER_SRGB);
	glBlitNamedFramebuffer(opengl.main_fbo, 0,
		0, 0, platform_width, platform_height,
		0, 0, platform_width, platform_height,
		GL_COLOR_BUFFER_BIT, GL_NEAREST);
	glDisable(GL_FRAMEBUFFER_SRGB);

	opengl_platform_present(output);
}
