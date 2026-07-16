@echo off
chcp 65001 >nul
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Desinstalar-Actualizacion-Kiwix.ps1"
if errorlevel 1 (
  echo.
  echo Se produjo un error durante la desinstalación.
  pause
)
