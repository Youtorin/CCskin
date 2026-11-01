@echo off
echo CC Moonlight update
echo Save drafts in the themed window before continuing. The themed window will close.
pause
if exist "%LOCALAPPDATA%\CCMoonlight\app\Restore-Moonlight.ps1" (
  powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "%LOCALAPPDATA%\CCMoonlight\app\Restore-Moonlight.ps1"
  if errorlevel 1 goto failed
)
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "%~dp0Install-Moonlight.ps1" -Repair
if errorlevel 1 goto failed
call "%LOCALAPPDATA%\CCMoonlight\app\Start.cmd"
exit /b %errorlevel%
:failed
echo Update stopped. Review the error above. Existing profile data was preserved.
pause
exit /b 1
