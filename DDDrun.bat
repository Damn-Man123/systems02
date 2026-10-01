@echo off
REM Set the directory of the script relative to this batch file
SET SCRIPT_DIR=%~dp0

echo --- Starting Deployment Script ---

REM Execute PowerShell with elevated rights and pass the script path
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%DDD.ps1"

echo.
echo --- Deployment Finished ---
pause