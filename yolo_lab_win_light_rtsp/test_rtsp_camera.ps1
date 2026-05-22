# ==================================================================================================
# test_rtsp_camera.ps1
# --------------------------------------------------------------------------------------------------
# Test telecamera IP / RTSP senza YOLO.
# ==================================================================================================

$VENV_NAME = ".venv_yolov5_light"
$MAIN_SCRIPT = "test_rtsp_camera.py"

Write-Host ""
Write-Host "=================================================================================================="
Write-Host " TEST TELECAMERA IP / RTSP - REPO STYLE"
Write-Host "=================================================================================================="
Write-Host ""

$VENV_PYTHON = Join-Path (Get-Location) "$VENV_NAME\Scripts\python.exe"

if (-not (Test-Path $VENV_PYTHON)) {
    Write-Host "[ERR] Ambiente virtuale non trovato. Eseguire setup_windows_yolov5_light.bat" -ForegroundColor Red
    pause
    exit 1
}

& $VENV_PYTHON $MAIN_SCRIPT
$ExitCode = $LASTEXITCODE

Write-Host ""
Write-Host "Test terminato con codice: $ExitCode"
pause
exit $ExitCode
