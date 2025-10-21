struct Game_Input {
	delta_time: float
}

struct Game_Output {

}

struct Game_State {
	initted: bool
}

terra game_update_and_render(memory: Slice(uint8), input: &Game_Input, output: &Game_Output)
	var state = [&Game_State](memory.data)
	if not state.initted then
		state.initted = true
	end
end
