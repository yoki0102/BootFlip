@echo off
echo ============================================================
echo   BootFlip - Debug mode (visible window)
echo ============================================================
echo.
echo This launches a PowerShell window running BootFlip.ps1.
echo If the script errors, the red message stays in the window.
echo Otherwise, check the system tray overflow (up-arrow icon).
echo.
pause

cd /d "%~dp0"
powershell.exe -NoExit -ExecutionPolicy Bypass -Command "Write-Host '--- starting BootFlip.ps1 ---' -ForegroundColor Cyan; try { & '.\BootFlip.ps1' } catch { Write-Host ''; Write-Host '!!! ERROR !!!' -ForegroundColor Red; Write-Host $_.Exception.Message -ForegroundColor Red; Write-Host $_.ScriptStackTrace -ForegroundColor Yellow }; Write-Host '--- script returned ---' -ForegroundColor Cyan"
