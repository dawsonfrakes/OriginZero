#if CPU_X86
	#define WINAPI __stdcall
#else
	#define WINAPI // __cdecl
#endif

// Kernel32
typedef S32 HRESULT;
typedef void* HANDLE;
typedef struct HINSTANCE__* HINSTANCE;
typedef HINSTANCE HMODULE;
typedef SSize (WINAPI* PROC)();

#define KERNEL32_PROCEDURES(X) \
	X(HMODULE, GetModuleHandleW, U16*) \
	X(HMODULE, LoadLibraryW, U16*) \
	X(PROC, GetProcAddress, HMODULE, U8*) \
	X(void, ExitProcess, U32)

// User32
#define CS_OWNDC 0x0020
#define IDI_WARNING cast(U16*, 32515)
#define IDC_CROSS cast(U16*, 32515)
#define PM_REMOVE 0x0001
#define WM_CREATE 0x0001
#define WM_DESTROY 0x0002
#define WM_SIZE 0x0005
#define WM_PAINT 0x000F
#define WM_QUIT 0x0012
#define WM_ERASEBKGND 0x0014
#define WM_ACTIVATEAPP 0x001C
#define WM_SYSCOMMAND 0x0112

typedef struct HDC__* HDC;
typedef struct HWND__* HWND;
typedef struct HMENU__* HMENU;
typedef struct HICON__* HICON;
typedef struct HBRUSH__* HBRUSH;
typedef struct HCURSOR__* HCURSOR;
typedef struct HMONITOR__* HMONITOR;
typedef SSize (WINAPI* WNDPROC)(HWND, U32, USize, SSize);
struct WNDCLASSEXW {
	U32       cbSize;
	U32       style;
	WNDPROC   lpfnWndProc;
	S32       cbClsExtra;
	S32       cbWndExtra;
	HINSTANCE hInstance;
	HICON     hIcon;
	HCURSOR   hCursor;
	HBRUSH    hbrBackground;
	U16*      lpszMenuName;
	U16*      lpszClassName;
	HICON     hIconSm;
};

#define USER32_PROCEDURES(X) \
	X(S32, SetProcessDPIAware) \
	X(HICON, LoadIconW, HINSTANCE, U16*) \
	X(HCURSOR, LoadCursorW, HINSTANCE, U16*) \
	X(U16, RegisterClassExW, WNDCLASSEXW*) \
	X(SSize, DefWindowProcW, HWND, U32, USize, SSize) \
	X(void, PostQuitMessage, S32)
