require "lib/windows"

local function utf8_to_utf16lez_string_literal(s)
	local function inner(s)
		local result = {}
		for i = 1, #s do
			table.insert(result, constant(int16, s:byte(i)))
		end
		table.insert(result, constant(int16, 0))
		return result
	end

	return constant(`arrayof(int16, [inner(s)]))
end

local libraries_to_load_statically = {"Kernel32"}
local libraries_to_load_dynamically = {"User32"}
for _,library in ipairs(libraries_to_load_statically) do
	for _,v in ipairs(_G[library]) do
		name, typ = v[1], v[2]
		_G[name] = terralib.externfunction(name, typ)
	end
end
for _,library in ipairs(libraries_to_load_dynamically) do
	for _,v in ipairs(_G[library]) do
		name, typ = v[1], v[2]
		_G[name] = global(typ)
	end
end

local function load_windows_procedures_from_libraries()
	local code = {}
	for _,library in ipairs(libraries_to_load_dynamically) do
		local dll = symbol(HMODULE, library.."_dll")
		table.insert(code, quote var [dll] = LoadLibraryW([utf8_to_utf16lez_string_literal(library:upper()..".DLL")]) end)
		for _,v in ipairs(_G[library]) do
			name, typ = v[1], v[2]
			table.insert(code, quote [_G[name]] = [typ](GetProcAddress([dll], name)) end)
		end
	end
	return code
end

terra WinMainCRTStartup()
	[load_windows_procedures_from_libraries()]

	SetProcessDPIAware()

	ExitProcess(0)
end
