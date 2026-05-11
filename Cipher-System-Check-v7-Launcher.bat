@echo off
setlocal
REM Cipher System Check v7 - Unified Launcher
REM Official launcher that calls the unified entry script.

cd /d "%~dp0"

echo.
echo =====================================
echo  Cipher System Check v7 - Launcher
echo =====================================
echo.

REM Check if unified script exists
if not exist "%~dp0Cipher-System-Check-v7.ps1" (
    echo ERROR: Unified script not found in current directory.
    echo Make sure both files are in the same folder:
    echo   - Cipher-System-Check-v7-Launcher.bat
    echo   - Cipher-System-Check-v7.ps1
    exit /b 1
)

REM Launch unified script (default mode = GUI)
echo Launching Cipher System Check...
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Cipher-System-Check-v7.ps1" -Mode Gui
exit /b %errorlevel%
