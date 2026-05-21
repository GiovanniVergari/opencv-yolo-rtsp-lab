# ==================================================================================================
# run_yolo_windows.ps1
# --------------------------------------------------------------------------------------------------
# Script di esecuzione per il laboratorio OpenCV + YOLO in ambiente Windows.
#
# Funzioni principali:
#   1. Individua gli ambienti virtuali disponibili nella cartella del progetto.
#   2. Consente di scegliere il venv da usare.
#   3. Verifica la presenza del programma Python principale.
#   4. Avvia rtsp_yolo_viewer_v2.py con il Python dell'ambiente virtuale.
#
# Uso consigliato:
#   powershell -ExecutionPolicy Bypass -File .\run_yolo_windows.ps1
# ==================================================================================================

# --------------------------------------------------------------------------------------------------
# Impostazioni modificabili
# --------------------------------------------------------------------------------------------------

$DEFAULT_VENV_NAME = ".venv_yolo_windows"
$MAIN_SCRIPT = "rtsp_yolo_viewer_v2.py"

# Parametri opzionali da passare allo script Python.
# Lasciare stringa vuota se il programma non richiede parametri.
$PYTHON_ARGUMENTS = ""

# --------------------------------------------------------------------------------------------------
# Funzioni di utilità
# --------------------------------------------------------------------------------------------------

function Write-Info {
    param (
        [string]$Message
    )

    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Warn {
    param (
        [string]$Message
    )

    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Err {
    param (
        [string]$Message
    )

    Write-Host "[ERR ] $Message" -ForegroundColor Red
}

function Get-VenvPythonPath {
    param (
        [string]$VenvDirectory
    )

    $Candidate = Join-Path $VenvDirectory "Scripts\python.exe"

    if (Test-Path $Candidate) {
        return $Candidate
    }

    return ""
}

# --------------------------------------------------------------------------------------------------
# Avvio procedura
# --------------------------------------------------------------------------------------------------

Write-Host ""
Write-Host "=================================================================================================="
Write-Host " AVVIO WINDOWS - OpenCV / YOLO Lab"
Write-Host "=================================================================================================="
Write-Host ""

$PROJECT_DIR = Get-Location
Write-Info "Cartella progetto: $PROJECT_DIR"

# --------------------------------------------------------------------------------------------------
# Controllo script principale
# --------------------------------------------------------------------------------------------------

if (-not (Test-Path $MAIN_SCRIPT)) {
    Write-Err "File principale '$MAIN_SCRIPT' non trovato nella cartella corrente."
    Write-Host ""
    Write-Host "Soluzione:"
    Write-Host "  Copiare questo script nella stessa cartella di $MAIN_SCRIPT."
    Write-Host ""
    pause
    exit 1
}

# --------------------------------------------------------------------------------------------------
# Ricerca ambienti virtuali
# --------------------------------------------------------------------------------------------------

$VenvCandidates = @()

if (Test-Path $DEFAULT_VENV_NAME) {
    $DefaultPythonPath = Get-VenvPythonPath $DEFAULT_VENV_NAME

    if ($DefaultPythonPath -ne "") {
        $VenvCandidates += [PSCustomObject]@{
            Name = $DEFAULT_VENV_NAME
            PythonPath = $DefaultPythonPath
        }
    }
}

$Directories = Get-ChildItem -Directory -ErrorAction SilentlyContinue

foreach ($Directory in $Directories) {
    $CandidatePythonPath = Get-VenvPythonPath $Directory.FullName

    if ($CandidatePythonPath -ne "") {
        $AlreadyAdded = $false

        foreach ($Existing in $VenvCandidates) {
            if ($Existing.PythonPath -eq $CandidatePythonPath) {
                $AlreadyAdded = $true
            }
        }

        if ($AlreadyAdded -eq $false) {
            $VenvCandidates += [PSCustomObject]@{
                Name = $Directory.Name
                PythonPath = $CandidatePythonPath
            }
        }
    }
}

if ($VenvCandidates.Count -eq 0) {
    Write-Err "Nessun ambiente virtuale trovato nella cartella del progetto."
    Write-Host ""
    Write-Host "Prima eseguire:"
    Write-Host "  powershell -ExecutionPolicy Bypass -File .\setup_windows_opencv_lab.ps1"
    Write-Host ""
    pause
    exit 1
}

# --------------------------------------------------------------------------------------------------
# Selezione ambiente virtuale
# --------------------------------------------------------------------------------------------------

$SelectedVenv = $null

if ($VenvCandidates.Count -eq 1) {
    $SelectedVenv = $VenvCandidates[0]
    Write-Info "Ambiente virtuale selezionato automaticamente: $($SelectedVenv.Name)"
} else {
    Write-Host "Ambienti virtuali disponibili:"
    Write-Host ""

    for ($Index = 0; $Index -lt $VenvCandidates.Count; $Index++) {
        $Number = $Index + 1
        Write-Host "  $Number) $($VenvCandidates[$Index].Name)"
    }

    Write-Host ""
    $Choice = Read-Host "Selezionare il numero dell'ambiente da usare"

    $ParsedChoice = 0
    $IsNumber = [int]::TryParse($Choice, [ref]$ParsedChoice)

    if ($IsNumber -eq $false) {
        Write-Err "Scelta non valida."
        pause
        exit 1
    }

    if ($ParsedChoice -lt 1 -or $ParsedChoice -gt $VenvCandidates.Count) {
        Write-Err "Scelta fuori intervallo."
        pause
        exit 1
    }

    $SelectedVenv = $VenvCandidates[$ParsedChoice - 1]
}

$PythonExe = $SelectedVenv.PythonPath

# --------------------------------------------------------------------------------------------------
# Verifica Python selezionato
# --------------------------------------------------------------------------------------------------

if (-not (Test-Path $PythonExe)) {
    Write-Err "Python non trovato: $PythonExe"
    pause
    exit 1
}

Write-Info "Python usato: $PythonExe"

# --------------------------------------------------------------------------------------------------
# Verifica importazioni principali
# --------------------------------------------------------------------------------------------------

Write-Info "Controllo rapido delle librerie principali..."

& $PythonExe -c "import cv2; print('OpenCV:', cv2.__version__)"

if ($LASTEXITCODE -ne 0) {
    Write-Err "OpenCV non importabile. Eseguire nuovamente lo script di setup."
    pause
    exit 1
}

& $PythonExe -c "from ultralytics import YOLO; print('Ultralytics YOLO: OK')"

if ($LASTEXITCODE -ne 0) {
    Write-Warn "Ultralytics non importabile. Il programma potrebbe non avviarsi correttamente."
}

# --------------------------------------------------------------------------------------------------
# Avvio programma
# --------------------------------------------------------------------------------------------------

Write-Host ""
Write-Host "--------------------------------------------------------------------------------------------------"
Write-Host " Avvio programma"
Write-Host "--------------------------------------------------------------------------------------------------"
Write-Host ""

if ($PYTHON_ARGUMENTS.Trim() -eq "") {
    & $PythonExe $MAIN_SCRIPT
} else {
    & $PythonExe $MAIN_SCRIPT $PYTHON_ARGUMENTS
}

$ExitCode = $LASTEXITCODE

Write-Host ""
Write-Host "--------------------------------------------------------------------------------------------------"
Write-Host " Programma terminato con codice: $ExitCode"
Write-Host "--------------------------------------------------------------------------------------------------"
Write-Host ""

pause
exit $ExitCode
