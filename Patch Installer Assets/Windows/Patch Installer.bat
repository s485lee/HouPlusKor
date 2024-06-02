@echo off
setlocal

:: Check if PowerShell is available
where powershell >nul 2>nul
if %errorlevel% neq 0 (
    echo PowerShell is not installed. Please install PowerShell and try again.
    pause
    exit /b 1
)

:: Run the PowerShell script
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Patch_Installer.ps1"

endlocal
pause
