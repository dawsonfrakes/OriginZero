module basic;

struct uda {}

@uda
struct foreign {
	string library;
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

struct Bounded_Array(size_t N, T) {
	size_t length;
	T[N] buffer;
	alias capacity = N;

	int opApply(int delegate(ref T) dg) {
		foreach (e; buffer.ptr[0..length]) {
			int result = dg(e);
			if (result) return result;
		}
		return 0;
	}
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

bool string_equal(string a, string b) {
	if (a.length != b.length) return false;
	foreach (it; 0..a.length)
		if (a.ptr[it] != b.ptr[it]) return false;
	return true;
}

extern(C) float* _memsetFloat(float* p, float value, size_t count) {
	foreach (it; 0..count) p[it] = value;
	return p;
}
