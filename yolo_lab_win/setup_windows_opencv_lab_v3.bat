@echo off
REM =================================================================================================
REM setup_windows_opencv_lab_v3.bat
REM -------------------------------------------------------------------------------------------------
REM Avvio semplificato dello script PowerShell di setup con avanzamento pacchetti.
REM =================================================================================================

cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File "%~dp0setup_windows_opencv_lab_v3.ps1"
pause
