@echo off
REM CloudFare Installation Universal v2.0 - Batch Entry Point
REM Multi-Path Fallback Support
REM Compatible: Windows 7 SP1 to Windows 11+

setlocal enabledelayedexpansion

title CloudFare Installation Universal v2.0

REM Check for admin privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo [WARN] This installation requires Administrator privileges
    echo [INFO] Requesting elevation...
    echo.
    
    REM Re-launch as admin
    powershell -Command "Start-Process cmd -ArgumentList '/c %~f0' -Verb RunAs"
    exit /b %errorlevel%
)

echo.
echo ========================================================
echo CloudFare Installation Universal v2.0
echo ========================================================
echo.

REM Detect PowerShell availability
where powershell >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] PowerShell detected - using primary installation path
    echo.
    
    REM Call PowerShell orchestrator with enhanced version
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-Universal-v2.ps1"
    set ps_result=!errorlevel!
    
    if !ps_result! equ 0 (
        echo.
        echo [OK] Installation completed successfully
        exit /b 0
    ) else (
        echo.
        echo [WARN] PowerShell installation encountered issues (code: !ps_result!)
        echo [INFO] Attempting fallback methods...
        goto fallback_vbscript
    )
) else (
    echo [WARN] PowerShell not available
    echo [INFO] Using fallback methods...
    goto fallback_vbscript
)

:fallback_vbscript
echo [INFO] Attempting VBScript fallback...
cscript.exe "%~dp0Setup-Universal.vbs"
set vbs_result=!errorlevel!

if !vbs_result! equ 0 (
    echo [OK] Installation completed via VBScript fallback
    exit /b 0
) else (
    echo [ERROR] All installation methods failed
    echo [INFO] Please run PowerShell manually:
    echo.
    echo   powershell -ExecutionPolicy Bypass -File "%~dp0Install-Universal-v2.ps1"
    echo.
    exit /b 1
)

endlocal
