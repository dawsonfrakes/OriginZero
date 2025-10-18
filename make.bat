@echo off

if not exist .build mkdir .build

where /q cl || call vcvars64.bat || goto :error

cl -Fe.build\OriginZero.exe -DDEBUG=1 -DSTEAM=1^
 -nologo -W4 -WX -Z7 -Oi -J -EHa- -GR- -GS- -Gs0x10000000^
 main.cpp Kernel32.lib^
 -link -nodefaultlib -incremental:no -subsystem:windows^
 -stack:0x10000000,0x10000000 -heap:0,0 || goto :error

if "%1"=="run"          ( start .build\OriginZero.exe
) else if "%1"=="debug" ( start windbgx .build\OriginZero.exe
) else if "%1"=="doc"   ( start qrenderdoc .build\OriginZero.exe
) else if not "%1"==""  ( echo command '%1' not found. & goto :error )

:end
del *.obj 2>nul
exit /b
:error
call :end
exit /b 1
