
@echo off
setlocal EnableExtensions DisableDelayedExpansion
title Podroid SSH Tunnel

REM ========================================
REM Employee Management System
REM Windows SSH Tunnel
REM ========================================

set "SSH_USER=root"
set "SSH_PORT=9922"

set "FRONTEND_LOCAL_PORT=18080"
set "FRONTEND_REMOTE_PORT=80"

set "BACKEND_LOCAL_PORT=19090"
set "BACKEND_REMOTE_PORT=9090"

echo.
echo ========================================
echo  Podroid SSH Tunnel
echo ========================================
echo.

REM Check OpenSSH Client
where ssh.exe >nul 2>&1

if errorlevel 1 (
    echo [ERROR] OpenSSH Client was not found.
    echo.
    echo Please install OpenSSH Client in Windows Settings.
    echo.
    pause
    exit /b 1
)

REM Request the Android Wi-Fi IP
:INPUT_IP
set "PODROID_IP="

set /p "PODROID_IP=Enter Android Wi-Fi IPv4: "

if not defined PODROID_IP (
    echo [ERROR] IP address cannot be empty.
    echo.
    goto INPUT_IP
)

REM Basic IPv4 syntax validation
echo(%PODROID_IP%| findstr /R /X "[0-9][0-9.]*" >nul

if errorlevel 1 (
    echo [ERROR] Please enter a valid IPv4 address.
    echo.
    goto INPUT_IP
)

REM Validate actual IPv4 address and prevent command injection
set "CHECKED_IP="
for /f "delims=" %%I in ('powershell.exe -NoProfile -Command "$s=$env:PODROID_IP; $a=$null; if ([System.Net.IPAddress]::TryParse($s,[ref]$a) -and $a.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork -and $s -match '^\d{1,3}(\.\d{1,3}){3}$') { $a.ToString() }"') do set "CHECKED_IP=%%I"

if not defined CHECKED_IP (
    echo [ERROR] Invalid IPv4 address.
    echo.
    goto INPUT_IP
)

set "PODROID_IP=%CHECKED_IP%"

echo.
echo ========================================
echo  Connection Information
echo ========================================
echo.
echo Android IP : %PODROID_IP%
echo SSH User   : %SSH_USER%
echo SSH Port   : %SSH_PORT%
echo.
echo Frontend   : http://localhost:%FRONTEND_LOCAL_PORT%/
echo Backend    : http://localhost:%BACKEND_LOCAL_PORT%/
echo.
echo Keep this window open while using the website.
echo Press Ctrl+C to disconnect.
echo.

REM Establish both SSH tunnels
ssh.exe -N -o ExitOnForwardFailure=yes -p %SSH_PORT% ^
    -L %FRONTEND_LOCAL_PORT%:127.0.0.1:%FRONTEND_REMOTE_PORT% ^
    -L %BACKEND_LOCAL_PORT%:127.0.0.1:%BACKEND_REMOTE_PORT% ^
    %SSH_USER%@%PODROID_IP%

set "EXIT_CODE=%ERRORLEVEL%"

echo.
echo SSH Tunnel disconnected. Exit Code: %EXIT_CODE%
echo.

pause
exit /b %EXIT_CODE%
