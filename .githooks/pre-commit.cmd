@echo off
REM Windows Git calls this .cmd hook; invoke PowerShell (pwsh if available, fallback to powershell)
where pwsh >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0pre-commit.ps1"
  exit /b %ERRORLEVEL%
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0pre-commit.ps1"
  exit /b %ERRORLEVEL%
)
