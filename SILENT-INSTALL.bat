@echo off
REM CloudFare v4.0 - 100% SILENT Installation
REM No user interaction, no dialogs

setlocal enabledelayedexpansion

REM Check admin rights (silently)
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo CloudFare installation requires administrator privileges.
    echo Please run Command Prompt as Administrator and try again.
    exit /b 1
)

REM Find MSI file
if not exist CloudFare-Setup-v4.0.msi (
    if exist "..\..\Desktop\JarCryptage\CloudFare-Setup-v4.0.msi" (
        set MSIPATH=..\..\Desktop\JarCryptage\CloudFare-Setup-v4.0.msi
    ) else (
        exit /b 1
    )
) else (
    set MSIPATH=CloudFare-Setup-v4.0.msi
)

REM Installation silencieuse - Aucune UI
msiexec /i "%MSIPATH%" /qn /norestart /l*v "%TEMP%\CloudFare-Install.log" ALLUSERS=1

REM Capture le code de retour
set ERRCODE=%errorlevel%

REM Attendre que l'installation soit compl?te
timeout /t 5 /nobreak >nul

REM Terminer silencieusement
exit /b %ERRCODE%
