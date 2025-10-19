struct Input {
	float delta_time;
}

struct Output {

}

struct State {
	bool initted;
}

void update_and_render(ubyte[] memory, Input* input, Output* output) {
	State* state = cast(State*) memory.ptr;
	if (!state.initted) {
		state.initted = true;
	}
}
