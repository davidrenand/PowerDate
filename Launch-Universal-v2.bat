@echo off
REM CloudFare Launcher Universal v2.0 - Batch Entry Point
REM Multi-Path Java Detection with Fallback

setlocal enabledelayedexpansion

title CloudFare Application Launcher v2.0

set INSTALL_DIR=C:\ProgramData\CloudFare
set JAR_FILE=%INSTALL_DIR%\App.jar
set LOG_DIR=%INSTALL_DIR%\Logs

echo.
echo ========================================================
echo CloudFare Application Launcher v2.0
echo ========================================================
echo.

REM Check if JAR exists
if not exist "%JAR_FILE%" (
    echo [ERROR] Application JAR not found: %JAR_FILE%
    exit /b 1
)

echo [OK] JAR found: %JAR_FILE%

REM Method 1: Try JAVA_HOME environment variable
if defined JAVA_HOME (
    if exist "%JAVA_HOME%\bin\java.exe" (
        echo [OK] Using JAVA_HOME: %JAVA_HOME%
        set JAVA_CMD=%JAVA_HOME%\bin\java.exe
        goto launch
    )
)

REM Method 2: Try CloudFare installation directory
if exist "%INSTALL_DIR%\Java\bin\java.exe" (
    echo [OK] Using CloudFare Java: %INSTALL_DIR%\Java
    set JAVA_CMD=%INSTALL_DIR%\Java\bin\java.exe
    goto launch
)

REM Method 3: Try system PATH
where java >nul 2>&1
if %errorlevel% equ 0 (
    for /f "delims=" %%i in ('where java') do set JAVA_CMD=%%i
    echo [OK] Using system Java: !JAVA_CMD!
    goto launch
)

REM Method 4: Try common installation locations
if exist "C:\Program Files\Java\jdk*\bin\java.exe" (
    for /f "delims=" %%i in ('dir /b /s "C:\Program Files\Java\jdk*\bin\java.exe" 2^>nul') do (
        set JAVA_CMD=%%i
        goto launch
    )
)

if exist "C:\Program Files (x86)\Java\jdk*\bin\java.exe" (
    for /f "delims=" %%i in ('dir /b /s "C:\Program Files (x86)\Java\jdk*\bin\java.exe" 2^>nul') do (
        set JAVA_CMD=%%i
        goto launch
    )
)

REM All methods failed
echo [ERROR] Java executable not found!
echo [INFO] Please ensure Java is installed or JAVA_HOME is set
exit /b 1

:launch
echo [INFO] Launching application...
echo [DEBUG] Command: "%JAVA_CMD%" -jar "%JAR_FILE%" %*

REM Create logs directory if it doesn't exist
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

REM Launch application
"%JAVA_CMD%" -jar "%JAR_FILE%" %*
set app_exit=%errorlevel%

echo.
echo [INFO] Application exited with code: %app_exit%
exit /b %app_exit%

endlocal
