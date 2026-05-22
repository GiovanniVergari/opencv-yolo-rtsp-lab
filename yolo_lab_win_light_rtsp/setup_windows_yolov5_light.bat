@echo off
REM =================================================================================================
REM setup_windows_yolov5_light.bat
REM -------------------------------------------------------------------------------------------------
REM Setup Windows leggero per YOLOv5n ONNX + RTSP.
REM =================================================================================================

cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File "%~dp0setup_windows_yolov5_light.ps1"
