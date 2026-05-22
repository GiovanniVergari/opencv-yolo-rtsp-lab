# ==================================================================================================
# setup_windows_yolov5_light.ps1
# --------------------------------------------------------------------------------------------------
# Setup Windows leggero per OpenCV + YOLOv5n ONNX.
# Mantiene il supporto RTSP tramite FFmpeg/OpenCV.
# ==================================================================================================

$VENV_NAME = ".venv_yolov5_light"
$REQUIREMENTS_FILE = "requirements_light.txt"
$MODEL_DIR = "models"
$MODEL_FILE = "yolov5n.onnx"
$MODEL_URL = "https://github.com/ultralytics/yolov5/releases/download/v7.0/yolov5n.onnx"

Write-Host ""
Write-Host "=================================================================================================="
Write-Host " SETUP WINDOWS LIGHT - YOLOv5n ONNX + RTSP"
Write-Host "=================================================================================================="
Write-Host ""

function Test-CommandAvailable {
    param ([string]$CommandName)

    $Command = Get-Command $CommandName -ErrorAction SilentlyContinue

    if ($null -eq $Command) {
        return $false
    }

    return $true
}

if (Test-CommandAvailable "py") {
    $PYTHON = "py"
    $PYTHON_ARGS = "-3"
} elseif (Test-CommandAvailable "python") {
    $PYTHON = "python"
    $PYTHON_ARGS = ""
} else {
    Write-Host "[ERR] Python non trovato. Installare Python 3 e aggiungerlo al PATH." -ForegroundColor Red
    pause
    exit 1
}

Write-Host "[INFO] Python rilevato."
& $PYTHON $PYTHON_ARGS --version

if (-not (Test-Path $REQUIREMENTS_FILE)) {
    Write-Host "[ERR] File requirements non trovato: $REQUIREMENTS_FILE" -ForegroundColor Red
    pause
    exit 1
}

if (-not (Test-Path $VENV_NAME)) {
    Write-Host "[INFO] Creazione ambiente virtuale..."
    & $PYTHON $PYTHON_ARGS -m venv $VENV_NAME
} else {
    Write-Host "[WARN] Ambiente virtuale già presente."
}

$VENV_PYTHON = Join-Path (Get-Location) "$VENV_NAME\Scripts\python.exe"

if (-not (Test-Path $VENV_PYTHON)) {
    Write-Host "[ERR] Python del venv non trovato: $VENV_PYTHON" -ForegroundColor Red
    pause
    exit 1
}

Write-Host "[INFO] Pulizia pacchetti pesanti o incompatibili..."
& $VENV_PYTHON -m pip uninstall -y ultralytics torch torchvision torchaudio opencv-python-headless opencv-contrib-python-headless opencv-python opencv-contrib-python

Write-Host "[INFO] Aggiornamento pip..."
& $VENV_PYTHON -m pip install --upgrade pip --disable-pip-version-check --no-input

Write-Host "[INFO] Installazione dipendenze leggere..."
& $VENV_PYTHON -m pip install -r $REQUIREMENTS_FILE --disable-pip-version-check --no-input

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERR] Installazione dipendenze non riuscita." -ForegroundColor Red
    pause
    exit 1
}

if (-not (Test-Path $MODEL_DIR)) {
    New-Item -ItemType Directory -Path $MODEL_DIR | Out-Null
}

$MODEL_PATH = Join-Path $MODEL_DIR $MODEL_FILE

if (Test-Path $MODEL_PATH) {
    Write-Host "[WARN] Modello già presente: $MODEL_PATH"
} else {
    Write-Host "[INFO] Download modello YOLOv5n ONNX..."
    Write-Host "[INFO] URL: $MODEL_URL"

    $DownloadScript = "download_yolov5n_onnx_temp.py"

    @"
import pathlib
import requests
import sys

url = "$MODEL_URL"
path = pathlib.Path("$MODEL_PATH")

try:
    response = requests.get(url, stream=True, timeout=30)
    response.raise_for_status()

    total = int(response.headers.get("content-length", 0))
    downloaded = 0
    last_percent = -1

    with open(path, "wb") as output_file:
        for chunk in response.iter_content(chunk_size=1024 * 1024):
            if chunk:
                output_file.write(chunk)
                downloaded = downloaded + len(chunk)

                if total > 0:
                    percent = int((downloaded * 100) / total)

                    if percent != last_percent:
                        print("[DOWNLOAD]", str(percent) + "%")
                        last_percent = percent

    print("[INFO] Download completato.")

except Exception as error:
    print("[ERR]", error)
    sys.exit(1)
"@ | Set-Content -Path $DownloadScript -Encoding UTF8

    & $VENV_PYTHON $DownloadScript
    Remove-Item $DownloadScript -Force -ErrorAction SilentlyContinue

    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERR] Download modello non riuscito." -ForegroundColor Red
        pause
        exit 1
    }
}

Write-Host "[INFO] Verifica OpenCV..."
& $VENV_PYTHON -c "import cv2; print('OpenCV:', cv2.__version__)"

Write-Host "[INFO] Verifica modello ONNX..."
& $VENV_PYTHON -c "import cv2; net=cv2.dnn.readNetFromONNX(r'$MODEL_PATH'); print('Modello ONNX caricato correttamente')"

Write-Host ""
Write-Host "=================================================================================================="
Write-Host " SETUP COMPLETATO"
Write-Host "=================================================================================================="
Write-Host ""
Write-Host "Prima testare la telecamera con:"
Write-Host "  test_rtsp_camera.bat"
Write-Host ""
Write-Host "Poi avviare YOLO con:"
Write-Host "  run_yolov5_light.bat"
Write-Host ""

pause
