#include "oz_basic.hpp"

#if STEAM
	#include "oz_steam.hpp"
#endif

#if OS_WINDOWS
	#define RENDER_APIS (RENDER_API_NONE | RENDER_API_SOFTWARE)
	#include "oz_windows.hpp"
	#include "main_windows.cpp"
#endif
