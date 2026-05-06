@echo off
REM Cipher System Check v7 - GUI Launcher
REM Run the WPF dashboard with proper PowerShell settings

setlocal enabledelayedexpansion
cd /d "%~dp0"

REM Check if PowerShell is available
where powershell >nul 2>&1
if errorlevel 1 (
    echo Error: PowerShell not found. Please ensure PowerShell is installed.
    pause
    exit /b 1
)

REM Launch GUI without profile to avoid interference
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Cipher-System-Check-v7-GUI.ps1"

REM Capture exit code
set GUI_EXIT_CODE=!ERRORLEVEL!

REM Exit with the same code
exit /b !GUI_EXIT_CODE!
