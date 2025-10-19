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

struct Input {
	float delta_time;
	bool[] keys;
	byte[] key_transitions;
}

struct Output {
	bool quit_requested;
}

struct State {
	bool initted;
}

void update_and_render(ubyte[] memory, Input* input, Output* output) {
	State* state = cast(State*) memory.ptr;
	if (!state.initted) {
		state.initted = true;
	}

	debug if (input.keys.ptr[Key.ESCAPE]) output.quit_requested = true;
}
