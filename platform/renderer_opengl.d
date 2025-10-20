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

	uint rect_shader;
	uint rect_vao;
	uint rect_ibo;
}

__gshared OpenGLData opengl;

struct OpenGL_Rect_Vertex {
	game.v2 position;
	game.v2 texcoord;
}
struct OpenGL_Rect_Instance {
	game.v3 offset;
	game.v2 scale;
	game.v4 color;
}

void opengl_init() {
	opengl_platform_init();

	glCreateFramebuffers(1, &opengl.main_fbo);
	glCreateRenderbuffers(1, &opengl.main_fbo_color0);
	glCreateRenderbuffers(1, &opengl.main_fbo_depth);

	{
		string vsrc =
		"#version 450

		layout(location = 0) in vec2 a_position;
		layout(location = 1) in vec2 a_texcoord;
		layout(location = 2) in vec3 i_offset;
		layout(location = 3) in vec2 i_scale;
		layout(location = 4) in vec4 i_color;

		layout(location = 1) out vec2 f_texcoord;
		layout(location = 4) out vec4 f_color;

		void main() {
			gl_Position = vec4(vec3(a_position * i_scale, 0.0) + i_offset, 1.0);
			f_texcoord = a_texcoord;
			f_color = i_color;
		}
		";
		uint vshader = glCreateShader(GL_VERTEX_SHADER);
		const(char)*[1] vsrcs = [vsrc.ptr];
		glShaderSource(vshader, vsrcs.length, vsrcs.ptr, null);
		glCompileShader(vshader);

		string fsrc =
		"#version 450

		layout(location = 1) in vec2 f_texcoord;
		layout(location = 4) in vec4 f_color;

		layout(location = 0) out vec4 color;

		void main() {
			color = f_color;
		}
		";
		uint fshader = glCreateShader(GL_FRAGMENT_SHADER);
		const(char)*[1] fsrcs = [fsrc.ptr];
		glShaderSource(fshader, fsrcs.length, fsrcs.ptr, null);
		glCompileShader(fshader);

		opengl.rect_shader = glCreateProgram();
		glAttachShader(opengl.rect_shader, vshader);
		glAttachShader(opengl.rect_shader, fshader);
		glLinkProgram(opengl.rect_shader);
		glDetachShader(opengl.rect_shader, fshader);
		glDetachShader(opengl.rect_shader, vshader);

		glDeleteShader(fshader);
		glDeleteShader(vshader);
	}

	{
		__gshared immutable OpenGL_Rect_Vertex[4] rect_vertices = [
			OpenGL_Rect_Vertex(game.v2(-0.5), game.v2(0.0)),
			OpenGL_Rect_Vertex(game.v2(+0.5, -0.5), game.v2(1.0, 0.0)),
			OpenGL_Rect_Vertex(game.v2(+0.5), game.v2(1.0)),
			OpenGL_Rect_Vertex(game.v2(-0.5, +0.5), game.v2(0.0, 1.0)),
		];
		__gshared immutable ushort[6] rect_indices = [0, 1, 2, 2, 3, 0];

		uint rect_ebo = void;
		glCreateBuffers(1, &rect_ebo);
		glNamedBufferData(rect_ebo, rect_indices.length * ushort.sizeof, rect_indices.ptr, GL_STATIC_DRAW);

		uint rect_vbo = void;
		glCreateBuffers(1, &rect_vbo);
		glNamedBufferData(rect_vbo, rect_vertices.length * OpenGL_Rect_Vertex.sizeof, rect_vertices.ptr, GL_STATIC_DRAW);

		glCreateBuffers(1, &opengl.rect_ibo);
		glNamedBufferData(opengl.rect_ibo, game.Output.ui_rects.capacity * OpenGL_Rect_Instance.sizeof, null, GL_STATIC_DRAW);

		enum vbo_binding = 0;
		enum ibo_binding = 1;
		glCreateVertexArrays(1, &opengl.rect_vao);
		glVertexArrayElementBuffer(opengl.rect_vao, rect_ebo);
		glVertexArrayVertexBuffer(opengl.rect_vao, vbo_binding, rect_vbo, 0, OpenGL_Rect_Vertex.sizeof);
		glVertexArrayVertexBuffer(opengl.rect_vao, ibo_binding, opengl.rect_ibo, 0, OpenGL_Rect_Instance.sizeof);
		glVertexArrayBindingDivisor(opengl.rect_vao, ibo_binding, 1);

		enum position_attrib = 0;
		glEnableVertexArrayAttrib(opengl.rect_vao, position_attrib);
		glVertexArrayAttribBinding(opengl.rect_vao, position_attrib, vbo_binding);
		glVertexArrayAttribFormat(opengl.rect_vao, position_attrib, 2, GL_FLOAT, false, OpenGL_Rect_Vertex.position.offsetof);

		enum texcoord_attrib = 1;
		glEnableVertexArrayAttrib(opengl.rect_vao, texcoord_attrib);
		glVertexArrayAttribBinding(opengl.rect_vao, texcoord_attrib, vbo_binding);
		glVertexArrayAttribFormat(opengl.rect_vao, texcoord_attrib, 2, GL_FLOAT, false, OpenGL_Rect_Vertex.texcoord.offsetof);

		enum offset_attrib = 2;
		glEnableVertexArrayAttrib(opengl.rect_vao, offset_attrib);
		glVertexArrayAttribBinding(opengl.rect_vao, offset_attrib, ibo_binding);
		glVertexArrayAttribFormat(opengl.rect_vao, offset_attrib, 3, GL_FLOAT, false, OpenGL_Rect_Instance.offset.offsetof);

		enum scale_attrib = 3;
		glEnableVertexArrayAttrib(opengl.rect_vao, scale_attrib);
		glVertexArrayAttribBinding(opengl.rect_vao, scale_attrib, ibo_binding);
		glVertexArrayAttribFormat(opengl.rect_vao, scale_attrib, 2, GL_FLOAT, false, OpenGL_Rect_Instance.scale.offsetof);

		enum color_attrib = 4;
		glEnableVertexArrayAttrib(opengl.rect_vao, color_attrib);
		glVertexArrayAttribBinding(opengl.rect_vao, color_attrib, ibo_binding);
		glVertexArrayAttribFormat(opengl.rect_vao, color_attrib, 4, GL_FLOAT, false, OpenGL_Rect_Instance.color.offsetof);
	}
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

	Bounded_Array!(game.Output.ui_rects.capacity, OpenGL_Rect_Instance) rect_instances;
	foreach (rect; output.ui_rects) {
		OpenGL_Rect_Instance instance;
		instance.offset = rect.position;
		instance.scale  = rect.size;
		instance.color  = rect.color;
		rect_instances.append(instance);
	}
	glNamedBufferSubData(opengl.rect_ibo, 0, rect_instances.length * OpenGL_Rect_Instance.sizeof, rect_instances.buffer.ptr);

	glBindVertexArray(opengl.rect_vao);
	glUseProgram(opengl.rect_shader);
	glDrawElementsInstanced(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, null, cast(uint) rect_instances.length);

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
