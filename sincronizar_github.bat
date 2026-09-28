@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0sync_github.ps1"
echo.
echo Pressione qualquer tecla para fechar esta janela...
pause >nul
