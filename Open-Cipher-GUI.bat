@echo off
setlocal
REM Simple one-click GUI launcher

cd /d "%~dp0"

net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

if not exist "%~dp0Cipher-System-Check-v7-GUI.ps1" (
    echo ERROR: Cipher-System-Check-v7-GUI.ps1 was not found in this folder.
    pause
    exit /b 1
)

powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0Cipher-System-Check-v7-GUI.ps1"

if errorlevel 1 (
    echo.
    echo GUI exited with an error.
)

pause