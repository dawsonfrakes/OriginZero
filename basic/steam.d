module basic.steam;

import basic : foreign;

version (Win32) enum SteamAPI = "steam_api";
version (Win64) enum SteamAPI = "steam_api64";

enum ESteamAPIInitResult : int {
	OK = 0,
	FailedGeneric = 1,
	NoSteamClient = 2,
	VersionMismatch = 3,
};

@foreign(SteamAPI) extern(System) {
	ESteamAPIInitResult SteamAPI_InitFlat(char[1024]*);
	void SteamAPI_Shutdown();
}
