import std.array : split;
import std.process : spawnProcess, wait;
import std.stdio : writeln;

void main(string[] args) {
	auto exit_code = "dmd -o- -of=.build/OriginZero.exe -betterC -g -debug -version=Steam -i platform/main_windows.d -L=Kernel32.lib -L=-subsystem:windows -L=-incremental:no".split.spawnProcess.wait;
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
			"dmd -O -release -o- -of=build_release/OriginZero.exe -betterC -version=Steam -i platform/main_windows.d -L=Kernel32.lib -L=-subsystem:windows -L=-incremental:no".split.spawnProcess.wait;
			break;
		default:
			writeln("Unknown command '", args[1], "'");
	}
}
