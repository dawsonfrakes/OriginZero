module basic;

struct foreign {
	string library;
}

auto min(Ts...)(Ts args) if (args.length >= 2) {
	auto result = args[0];
	static foreach (it; args[1..$])
		result = result < it ? result : it;
	return result;
}

auto max(Ts...)(Ts args) if (args.length >= 2) {
	auto result = args[0];
	static foreach (it; args[1..$])
		result = result > it ? result : it;
	return result;
}

bool has_uda(alias x, T)() {
	static foreach (it; __traits(getAttributes, x))
		static if (is(typeof(it) == T)) return true;
	return false;
}

T get_uda(alias x, T)() {
	static foreach (it; __traits(getAttributes, x))
		static if (is(typeof(it) == T)) return it;
}

bool string_equal(string a, string b) {
	if (a.length != b.length) return false;
	foreach (it; 0..a.length)
		if (a.ptr[it] != b.ptr[it]) return false;
	return true;
}
