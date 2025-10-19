module basic.opengl;

struct gl_version {
	ubyte major;
	ubyte minor;
}

// 1.0
@gl_version(1, 0) extern(System) {
	void glEnable(uint);
	void glDisable(uint);
	void glClearColor(float, float, float, float);
	void glClear(uint);
	void glViewport(int, int, uint, uint);
}

// 4.5
@gl_version(4, 5) extern(System) {
	void glCreateFramebuffers(uint, uint*);
	void glCreateRenderbuffers(uint, uint*);
}
