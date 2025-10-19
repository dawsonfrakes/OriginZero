enum STEAM = true;

import std.array : split;
import std.file : copy, dirEntries, mkdirRecurse, SpanMode, write;
import std.path : baseName;
import std.process : spawnProcess, wait;
import std.stdio : writeln;

void copy_foreign_dlls_to_folder(string folder) {
	foreach (string name; dirEntries("foreign", "*.dll", SpanMode.shallow))
		name.copy(folder~"/"~name.baseName);
}

void main(string[] args) {
	".build".mkdirRecurse;
	if (STEAM) {
		".build/steam_appid.txt".write("480");
		copy_foreign_dlls_to_folder(".build");
	}

	auto exit_code = split("dmd -g -debug -of=.build/OriginZero.exe -betterC "~(STEAM ? "-version=Steam" : "")~" -i platform/main_windows.d -L=Kernel32.lib -L=-subsystem:windows -L=-incremental:no").spawnProcess.wait;
	if (exit_code) return;

	if (args.length <= 1) return;
	switch (args[1]) {
		case "run":
			".build/OriginZero.exe".spawnProcess.wait;
			break;
		case "debug":
			"raddbg .build/OriginZero.exe".split.spawnProcess.wait;
			break;
		case "release":
			"build_release".mkdirRecurse;
			if (STEAM) {
				"build_release/steam_appid.txt".write("480");
				copy_foreign_dlls_to_folder("build_release");
			}
			split("dmd -O -release -of=build_release/OriginZero.exe -betterC "~(STEAM ? "-version=Steam" : "")~" -i platform/main_windows.d -L=Kernel32.lib -L=-subsystem:windows -L=-incremental:no").spawnProcess.wait;
			break;
		default:
			writeln("Unknown command '", args[1], "'");
	}
}
