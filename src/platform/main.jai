#load "../oz_basic.jai";

#load "../game/game.jai";

Render_Api_Flags :: enum_flags u32 {
	NONE   :: 0x1;
	OPENGL :: 0x2;
}

#if OS == .WINDOWS {
	RENDER_APIS :: Render_Api_Flags.NONE | .OPENGL;

	#load "oz_windows.jai";
	#load "main_windows.jai";
}

#if RENDER_APIS & .OPENGL {
	#load "oz_opengl.jai";
	#load "renderer_opengl.jai";
}
