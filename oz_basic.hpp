#if defined(__i386__) || defined(_M_IX86)
	#define CPU_X86 1
#else
	#define CPU_X86 0
#endif

#if defined(__x86_64__) || defined(_M_AMD64)
	#define CPU_X64 1
#else
	#define CPU_X64 0
#endif

#if defined(__aarch64__) || defined(_M_ARM64)
	#define CPU_ARM64 1
#else
	#define CPU_ARM64 0
#endif

#if defined(_WIN32)
	#define OS_WINDOWS 1
#else
	#define OS_WINDOWS 0
#endif

#define cast(T, V) ((T) (V))
#define size_of(T) sizeof(T)
#define type_of(X) decltype(X)
#define offset_of(T, F) cast(SSize, &cast(T*, 0)->F)

#define nil nullptr

#if CPU_X64 || CPU_ARM64
	typedef signed char S8;
	typedef short S16;
	typedef int S32;
	typedef long long S64;
	typedef S64 SSize;

	typedef unsigned char U8;
	typedef unsigned short U16;
	typedef unsigned int U32;
	typedef unsigned long long U64;
	typedef U64 USize;
#endif

struct String {
	SSize count;
	U8* data;

	template<SSize N> String(char const (&x)[N]) : count(N - 1), data(cast(U8*, x)) {}
};

struct WString {
	SSize count;
	U16* data;

	template<SSize N> WString(wchar_t const (&x)[N]) : count(N - 1), data(cast(U16*, x)) {}
};
