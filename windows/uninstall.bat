@echo off
setlocal

set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "DESKTOP=%USERPROFILE%\Desktop"

echo.
echo ============================================================
echo   BootFlip - Uninstaller
echo ============================================================
echo.

for %%F in ("BootFlip.lnk") do (
    if exist "%STARTUP%\%%~F" (
        del /f /q "%STARTUP%\%%~F"
        echo [REMOVED] %STARTUP%\%%~F
    )
    if exist "%DESKTOP%\%%~F" (
        del /f /q "%DESKTOP%\%%~F"
        echo [REMOVED] %DESKTOP%\%%~F
    )
)

echo.
echo NOTE: If the tray icon is still visible, right-click it and choose Exit.
echo Program files were not deleted - delete this folder manually if desired.
echo.
echo The dual-boot clock fix (registry RealTimeIsUniversal=1) is NOT reverted by
echo this uninstaller. To revert: bcdedit-style registry edit or reset the value to 0.
echo.
pause
