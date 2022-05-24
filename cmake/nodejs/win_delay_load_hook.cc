#ifdef _MSC_VER

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif

#include <windows.h>
#include <Shlwapi.h>
#include <delayimp.h>
#include <string.h>

static FARPROC WINAPI load_exe_hook(unsigned int event, DelayLoadInfo *info) {
	HMODULE m;
	if (event != dliNotePreLoadLibrary)
		return NULL;

	if (_stricmp(info->szDll, "NODE.EXE") != 0)
		return NULL;

	m = GetModuleHandle(NULL);
	return (FARPROC)m;
}

static FARPROC WINAPI load_failure_hook(unsigned int event, DelayLoadInfo* info) {
	if (event == dliFailGetProc) {
		HMODULE m = GetModuleHandle("msvcp140.dll");
		if (m != NULL) {
			TCHAR mPath[_MAX_PATH];
			GetModuleFileName(m, mPath, _MAX_PATH);
			FARPROC fp = GetProcAddress(m, info->dlp.szProcName);
			return fp;
		}
	}
}

decltype(__pfnDliNotifyHook2) __pfnDliNotifyHook2 = load_exe_hook;
decltype(__pfnDliFailureHook2) __pfnDliFailureHook2 = load_failure_hook;

#endif