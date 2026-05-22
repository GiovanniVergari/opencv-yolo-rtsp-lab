# ==================================================================================================
# run_yolov5_light.ps1
# --------------------------------------------------------------------------------------------------
# Avvio viewer YOLOv5n Light + RTSP.
# ==================================================================================================

$VENV_NAME = ".venv_yolov5_light"
$MAIN_SCRIPT = "rtsp_yolov5_light_viewer.py"

Write-Host ""
Write-Host "=================================================================================================="
Write-Host " AVVIO YOLOv5 LIGHT - RTSP REPO STYLE V2"
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
Write-Host "Programma terminato con codice: $ExitCode"
pause
exit $ExitCode
