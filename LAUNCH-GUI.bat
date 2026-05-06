@echo off
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Cipher-System-Check-v7-GUI.ps1"
exit /b 0
