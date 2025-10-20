import basic;

struct Vector(size_t N, T) {
	T[N] component = 0;

	this(T spread) { component = spread; }
	this(Ts...)(Ts args) if (args.length == N) {
		static foreach (it; 0..args.length)
			component[it] = args[it];
	}

	static if (N > 0) ref T x() => component[0];
	static if (N > 1) ref T y() => component[1];
	static if (N > 2) ref T z() => component[2];
	static if (N > 3) ref T w() => component[3];

	static if (N > 0) ref T r() => component[0];
	static if (N > 1) ref T g() => component[1];
	static if (N > 2) ref T b() => component[2];
	static if (N > 3) ref T a() => component[3];
}

alias v2 = Vector!(2, float);
alias v3 = Vector!(3, float);
alias v4 = Vector!(4, float);

enum Key : ubyte {
	SPACE = ' ',
	ESCAPE = 0x1B,
	_0 = '0', _1, _2, _3, _4, _5, _6, _7, _8, _9,
	A = 'A',
	B, C, D, E, F, G, H,
	I, J, K, L, M, N, O,
	P, Q, R, S, T, U, V,
	W, X, Y, Z,
}

struct UI_Rect {
	v3 position;
	v2 size;
	v4 color;
	// v2[2] texcoords;
	// Texture_ID texture;
}

struct Input {
	float delta_time;
	bool[] keys;
	byte[] key_transitions;
}

struct Output {
	bool quit_requested;

	Bounded_Array!(4096, UI_Rect) ui_rects;
}

struct State {
	bool initted;
}

void ui_rect(Output* output, v3 position, v2 size, v4 color = v4(1.0)) {
	if (output.ui_rects.length < output.ui_rects.capacity) {
		UI_Rect* rect = &output.ui_rects.buffer.ptr[output.ui_rects.length];
		rect.position = position;
		rect.size = size;
		rect.color = color;
		output.ui_rects.length += 1;
	}
}

void update_and_render(ubyte[] memory, Input* input, Output* output) {
	State* state = cast(State*) memory.ptr;
	if (!state.initted) {
		state.initted = true;
	}

	ui_rect(output, v3(0.0), v2(0.5));

	debug if (input.keys.ptr[Key.ESCAPE]) output.quit_requested = true;
}
