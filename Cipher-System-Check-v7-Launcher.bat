@echo off
setlocal
REM Cipher System Check v7 - Quick Launcher
REM Double-click this file to launch the GUI. It will request elevation if needed.

cd /d "%~dp0"

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo.
echo =====================================
echo  Cipher System Check v7 - Launcher
echo =====================================
echo.

REM Check if GUI script exists
if not exist "%~dp0Cipher-System-Check-v7-GUI.ps1" (
    echo ERROR: GUI script not found in current directory.
    echo Make sure both files are in the same folder:
    echo   - Cipher-System-Check-v7-Launcher.bat (this file)
    echo   - Cipher-System-Check-v7-GUI.ps1
    echo   - Cipher-System-Check-v7-Core.ps1
    echo.
    pause
    exit /b 1
)

REM Launch PowerShell with GUI
echo Launching Cipher System Check GUI...
echo.

powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0Cipher-System-Check-v7-GUI.ps1"

echo.
echo GUI closed.
pause
