@echo off
REM =================================================================================================
REM run_yolo_windows.bat
REM -------------------------------------------------------------------------------------------------
REM Avvio semplificato dello script PowerShell di esecuzione.
REM =================================================================================================

cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File "%~dp0run_yolo_windows.ps1"
