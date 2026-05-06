@echo off
REM Cipher System Check v7 - Setup Verification
REM Run this to verify all files are present and correct

echo.
echo =====================================
echo  Cipher System Check v7
echo  Setup Verification
echo =====================================
echo.

setlocal enabledelayedexpansion

set "ERROR=0"

REM Check for each required file
set "FILES[0]=Cipher-System-Check-v7-Launcher.bat"
set "FILES[1]=Cipher-System-Check-v7-GUI.ps1"
set "FILES[2]=Cipher-System-Check-v7-Core.ps1"
set "FILES[3]=Cipher-System-Check-v7-README.md"
set "FILES[4]=Cipher-System-Check-v7-SUMMARY.txt"
set "FILES[5]=QUICK-REFERENCE.txt"

echo Checking for required files...
echo.

for /L %%i in (0,1,5) do (
    if exist "!FILES[%%i]!" (
        echo ✓ Found: !FILES[%%i]!
    ) else (
        echo ✗ MISSING: !FILES[%%i]!
        set "ERROR=1"
    )
)

echo.

if !ERROR! equ 1 (
    echo.
    echo ERROR: Not all files are present.
    echo Make sure all files are in the same directory:
    echo %CD%
    echo.
    pause
    exit /b 1
)

REM Check for PowerShell
echo Checking PowerShell availability...
powershell.exe -NoProfile -Command "Write-Host '✓ PowerShell 5.0+' -ForegroundColor Green" >nul 2>&1
if !errorlevel! neq 0 (
    echo ✗ PowerShell not available or too old
    set "ERROR=1"
)

if !ERROR! equ 0 (
    echo.
    echo =====================================
    echo  ✓ Setup Verification PASSED
    echo =====================================
    echo.
    echo All required files are present and ready.
    echo.
    echo Next steps:
    echo   1. Read Cipher-System-Check-v7-README.md for full guide
    echo   2. Review QUICK-REFERENCE.txt for quick start
    echo   3. Run Cipher-System-Check-v7-Launcher.bat to begin
    echo.
    echo.
    pause
    exit /b 0
) else (
    echo.
    echo =====================================
    echo  ✗ Setup Verification FAILED
    echo =====================================
    echo.
    pause
    exit /b 1
)
