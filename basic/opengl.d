module basic.opengl;

struct gl_version {
	ubyte major;
	ubyte minor;
}

// 1.0
enum GL_COLOR_BUFFER_BIT = 0x00004000;
enum GL_TRIANGLES = 0x0004;
enum GL_GEQUAL = 0x0206;
enum GL_SRC_ALPHA = 0x0302;
enum GL_ONE_MINUS_SRC_ALPHA = 0x0303;
enum GL_FRONT_AND_BACK = 0x0408;
enum GL_DEPTH_TEST = 0x0B71;
enum GL_TEXTURE_2D = 0x0DE1;
enum GL_UNSIGNED_BYTE = 0x1401;
enum GL_UNSIGNED_SHORT = 0x1403;
enum GL_UNSIGNED_INT = 0x1405;
enum GL_FLOAT = 0x1406;
enum GL_COLOR = 0x1800;
enum GL_DEPTH = 0x1801;
enum GL_RED = 0x1903;
enum GL_RGB = 0x1907;
enum GL_RGBA = 0x1908;
enum GL_POINT = 0x1B00;
enum GL_LINE = 0x1B01;
enum GL_FILL = 0x1B02;
enum GL_VENDOR = 0x1F00;
enum GL_RENDERER = 0x1F01;
enum GL_VERSION = 0x1F02;
enum GL_EXTENSIONS = 0x1F03;
enum GL_NEAREST = 0x2600;
enum GL_LINEAR = 0x2601;
enum GL_NEAREST_MIPMAP_NEAREST = 0x2700;
enum GL_LINEAR_MIPMAP_NEAREST = 0x2701;
enum GL_NEAREST_MIPMAP_LINEAR = 0x2702;
enum GL_LINEAR_MIPMAP_LINEAR = 0x2703;
enum GL_TEXTURE_MAG_FILTER = 0x2800;
enum GL_TEXTURE_MIN_FILTER = 0x2801;
enum GL_TEXTURE_WRAP_S = 0x2802;
enum GL_TEXTURE_WRAP_T = 0x2803;
enum GL_REPEAT = 0x2901;

@gl_version(1, 0) extern(System) {
	void glEnable(uint);
	void glDisable(uint);
	void glGetIntegerv(uint, int*);
	void glClearColor(float, float, float, float);
	void glClear(uint);
	void glViewport(int, int, uint, uint);
}

// 2.0
@gl_version(2, 0) extern(System) {
	uint glCreateProgram();
	uint glCreateShader(uint);
}

// 3.0
enum GL_RGBA16F = 0x881A;
enum GL_DEPTH_COMPONENT32F = 0x8CAC;
enum GL_READ_FRAMEBUFFER = 0x8CA8;
enum GL_DRAW_FRAMEBUFFER = 0x8CA9;
enum GL_COLOR_ATTACHMENT0 = 0x8CE0;
enum GL_COLOR_ATTACHMENT1 = 0x8CE1;
enum GL_DEPTH_ATTACHMENT = 0x8D00;
enum GL_FRAMEBUFFER = 0x8D40;
enum GL_RENDERBUFFER = 0x8D41;
enum GL_FRAMEBUFFER_SRGB = 0x8DB9;

@gl_version(3, 0) extern(System) {
	void glBindFramebuffer(uint, uint);
	void glBindVertexArray(uint);
}

// 3.2
enum GL_MAX_COLOR_TEXTURE_SAMPLES = 0x910E;
enum GL_MAX_DEPTH_TEXTURE_SAMPLES = 0x910F;

// 4.5
@gl_version(4, 5) extern(System) {
	void glCreateFramebuffers(uint, uint*);
	void glNamedFramebufferRenderbuffer(uint, uint, uint, uint);
	void glClearNamedFramebufferfv(uint, uint, int, const(float)*);
	void glBlitNamedFramebuffer(uint, uint, int, int, int, int, int, int, int, int, uint, uint);
	void glCreateRenderbuffers(uint, uint*);
	void glNamedRenderbufferStorageMultisample(uint, uint, uint, uint, uint);
	void glCreateVertexArrays(uint, uint*);
	void glCreateBuffers(uint, uint*);
	void glCreateTextures(uint, uint, uint*);
}
