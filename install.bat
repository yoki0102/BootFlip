@echo off
setlocal EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "DESKTOP=%USERPROFILE%\Desktop"
set "VBS=%SCRIPT_DIR%\BootFlip.vbs"
set "ICO=%SCRIPT_DIR%\bootflip.ico"
set "PS1=%SCRIPT_DIR%\do-switch.ps1"
set "LNK_NAME=BootFlip.lnk"

echo.
echo ============================================================
echo   BootFlip - Tray Installer
echo ============================================================
echo.
echo Install location: %SCRIPT_DIR%
echo.

if not exist "%VBS%" (echo [ERROR] BootFlip.vbs not found & pause & exit /b 1)
if not exist "%SCRIPT_DIR%\BootFlip.ps1" (echo [ERROR] BootFlip.ps1 not found & pause & exit /b 1)
if not exist "%PS1%" (echo [ERROR] do-switch.ps1 not found & pause & exit /b 1)

echo [1/4] Creating startup shortcut...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=(New-Object -COM WScript.Shell).CreateShortcut('%STARTUP%\%LNK_NAME%'); $s.TargetPath='%VBS%'; $s.WorkingDirectory='%SCRIPT_DIR%'; $s.IconLocation='%ICO%'; $s.Description='BootFlip tray tool'; $s.Save()"
if errorlevel 1 (echo     [FAIL]) else (echo     [OK])
echo.

echo [2/4] Create desktop shortcut? [Y/N]
choice /C YN /N /M ">>> "
if errorlevel 2 goto :skipdesk
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=(New-Object -COM WScript.Shell).CreateShortcut('%DESKTOP%\%LNK_NAME%'); $s.TargetPath='%VBS%'; $s.WorkingDirectory='%SCRIPT_DIR%'; $s.IconLocation='%ICO%'; $s.Description='BootFlip tray tool'; $s.Save()"
echo     [OK]
goto :afterdesk
:skipdesk
echo     [SKIP]
:afterdesk
echo.

echo [3/4] Applying dual-boot clock fix...
echo     (UAC prompt will appear - one-time fix so Windows time
echo      stays correct after switching from Ubuntu)
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-WindowStyle','Hidden','-File',[string]([char]34 + '%PS1%' + [char]34),'-Mode','fixclock') -ErrorAction Stop" 2>nul
if errorlevel 1 (
    echo     [SKIPPED] User declined UAC. Re-run install.bat anytime.
) else (
    echo     [SENT] A confirmation dialog will appear when done.
)
echo.

echo [4/4] Launch tray now? [Y/N]
choice /C YN /N /M ">>> "
if errorlevel 2 goto :skipstart
start "" wscript.exe "%VBS%"
echo     [STARTED] Check the system tray (bottom-right corner)
goto :end
:skipstart
echo     [SKIP] Will auto-start on next login
:end

echo.
echo ============================================================
echo   Installation complete
echo ============================================================
echo.
pause
