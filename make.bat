@echo off

dmd -of=.build\OriginZero.exe^
 -betterC -g -debug -version=Steam^
 main.d^
 -L=Kernel32.lib -L=-subsystem:windows -L=-incremental:no || goto :error

if "%1"=="run" ( start .build\OriginZero.exe )

:end
exit /b
:error
call :end
exit /b 1
