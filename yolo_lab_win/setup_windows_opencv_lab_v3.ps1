# ==================================================================================================
# setup_windows_opencv_lab_v3.ps1
# --------------------------------------------------------------------------------------------------
# Setup Windows per OpenCV / YOLO Lab con avanzamento dettagliato delle dipendenze.
#
# Migliorie principali:
#   1. Installa i pacchetti di requirements.txt uno alla volta.
#   2. Mostra chiaramente il pacchetto corrente: [2/5] Installazione ultralytics...
#   3. Mostra il tempo trascorso per ogni pacchetto.
#   4. Genera un log generale e un log dedicato a pip.
#   5. Evita blocchi indefiniti usando timeout per ogni pacchetto.
#   6. Permette di saltare l'aggiornamento di pip.
#   7. Permette di continuare anche se un pacchetto fallisce, ma segnala il problema.
#
# Uso standard:
#   powershell -ExecutionPolicy Bypass -File .\setup_windows_opencv_lab_v3.ps1
#
# Uso se l'aggiornamento pip crea problemi:
#   powershell -ExecutionPolicy Bypass -File .\setup_windows_opencv_lab_v3.ps1 -SkipPipUpgrade
#
# Uso più tollerante, utile per diagnostica:
#   powershell -ExecutionPolicy Bypass -File .\setup_windows_opencv_lab_v3.ps1 -ContinueOnPackageError
# ==================================================================================================

param (
    [switch]$SkipPipUpgrade,
    [switch]$ContinueOnPackageError
)

# --------------------------------------------------------------------------------------------------
# Impostazioni modificabili
# --------------------------------------------------------------------------------------------------

$VENV_NAME = ".venv_yolo_windows"
$REQUIREMENTS_FILE = "requirements.txt"

# Timeout massimo per ogni singolo pacchetto.
# In laboratorio, 600 secondi per pacchetto sono generalmente sufficienti.
$PACKAGE_TIMEOUT_SECONDS = 600

# Timeout per l'aggiornamento di pip.
$PIP_UPGRADE_TIMEOUT_SECONDS = 300

# Timeout per comandi brevi di diagnostica.
$SHORT_COMMAND_TIMEOUT_SECONDS = 60

# Ogni quanti secondi indicare che il processo è ancora attivo.
$HEARTBEAT_SECONDS = 10

# File di log.
$LOG_FILE = "setup_windows_opencv_lab.log"
$PIP_LOG_FILE = "setup_windows_opencv_lab_pip.log"

# Opzioni aggiuntive per pip.
# Utile in ambienti scolastici con proxy o certificati particolari.
# Esempi:
#   $PIP_EXTRA_OPTIONS = "--trusted-host pypi.org --trusted-host files.pythonhosted.org"
#   $PIP_EXTRA_OPTIONS = "--index-url https://pypi.org/simple"
$PIP_EXTRA_OPTIONS = ""

# Se True, forza reinstallazione dei pacchetti anche se già presenti.
# Normalmente conviene lasciarlo False.
$FORCE_REINSTALL_PACKAGES = $false

# --------------------------------------------------------------------------------------------------
# Funzioni di output
# --------------------------------------------------------------------------------------------------

function Write-LogLine {
    param (
        [string]$Level,
        [string]$Message
    )

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Line = "[$Timestamp] [$Level] $Message"

    Add-Content -Path $LOG_FILE -Value $Line -Encoding UTF8
}

function Write-Info {
    param (
        [string]$Message
    )

    Write-Host "[INFO] $Message" -ForegroundColor Cyan
    Write-LogLine -Level "INFO" -Message $Message
}

function Write-Warn {
    param (
        [string]$Message
    )

    Write-Host "[WARN] $Message" -ForegroundColor Yellow
    Write-LogLine -Level "WARN" -Message $Message
}

function Write-Err {
    param (
        [string]$Message
    )

    Write-Host "[ERR ] $Message" -ForegroundColor Red
    Write-LogLine -Level "ERR " -Message $Message
}

function Write-StepTitle {
    param (
        [string]$Message
    )

    Write-Host ""
    Write-Host "=================================================================================================="
    Write-Host " $Message"
    Write-Host "=================================================================================================="
    Write-Host ""

    Write-LogLine -Level "STEP" -Message $Message
}

function Format-Duration {
    param (
        [TimeSpan]$Duration
    )

    $Minutes = [int]$Duration.TotalMinutes
    $Seconds = $Duration.Seconds

    return "$Minutes min $Seconds sec"
}

# --------------------------------------------------------------------------------------------------
# Funzioni di controllo
# --------------------------------------------------------------------------------------------------

function Test-CommandAvailable {
    param (
        [string]$CommandName
    )

    $Command = Get-Command $CommandName -ErrorAction SilentlyContinue

    if ($null -eq $Command) {
        return $false
    }

    return $true
}

function Get-PythonCommand {
    if (Test-CommandAvailable "py") {
        return "py -3"
    }

    if (Test-CommandAvailable "python") {
        return "python"
    }

    return ""
}

function Convert-CommandLineToExecutableAndArguments {
    param (
        [string]$CommandLine
    )

    $Result = [PSCustomObject]@{
        Executable = ""
        Arguments = ""
    }

    $TrimmedCommand = $CommandLine.Trim()

    if ($TrimmedCommand.StartsWith('"')) {
        $SecondQuoteIndex = $TrimmedCommand.IndexOf('"', 1)

        if ($SecondQuoteIndex -gt 0) {
            $Result.Executable = $TrimmedCommand.Substring(1, $SecondQuoteIndex - 1)
            $Result.Arguments = $TrimmedCommand.Substring($SecondQuoteIndex + 1).Trim()
            return $Result
        }
    }

    $FirstSpaceIndex = $TrimmedCommand.IndexOf(" ")

    if ($FirstSpaceIndex -lt 0) {
        $Result.Executable = $TrimmedCommand
        $Result.Arguments = ""
        return $Result
    }

    $Result.Executable = $TrimmedCommand.Substring(0, $FirstSpaceIndex)
    $Result.Arguments = $TrimmedCommand.Substring($FirstSpaceIndex + 1).Trim()

    return $Result
}

function Invoke-CommandWithHeartbeat {
    param (
        [string]$CommandLine,
        [string]$StepName,
        [int]$TimeoutSeconds,
        [string]$ExtraLogFile = ""
    )

    Write-Info "Avvio: $StepName"
    Write-LogLine -Level "CMD " -Message $CommandLine

    if ($ExtraLogFile -ne "") {
        Add-Content -Path $ExtraLogFile -Value "" -Encoding UTF8
        Add-Content -Path $ExtraLogFile -Value "==================================================================================================" -Encoding UTF8
        Add-Content -Path $ExtraLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $StepName" -Encoding UTF8
        Add-Content -Path $ExtraLogFile -Value "$CommandLine" -Encoding UTF8
        Add-Content -Path $ExtraLogFile -Value "==================================================================================================" -Encoding UTF8
    }

    $ParsedCommand = Convert-CommandLineToExecutableAndArguments -CommandLine $CommandLine

    if ($ParsedCommand.Executable -eq "") {
        Write-Err "Comando non valido."
        return 1
    }

    $ProcessStartInfo = New-Object System.Diagnostics.ProcessStartInfo
    $ProcessStartInfo.FileName = $ParsedCommand.Executable
    $ProcessStartInfo.Arguments = $ParsedCommand.Arguments
    $ProcessStartInfo.UseShellExecute = $false
    $ProcessStartInfo.RedirectStandardOutput = $true
    $ProcessStartInfo.RedirectStandardError = $true
    $ProcessStartInfo.CreateNoWindow = $true
    $ProcessStartInfo.WorkingDirectory = (Get-Location).Path

    $Process = New-Object System.Diagnostics.Process
    $Process.StartInfo = $ProcessStartInfo

    try {
        $Started = $Process.Start()
    } catch {
        Write-Err "Impossibile avviare il comando."
        Write-Err $_.Exception.Message
        return 1
    }

    if ($Started -eq $false) {
        Write-Err "Il processo non è partito."
        return 1
    }

    $StartTime = Get-Date
    $LastHeartbeat = Get-Date
    $TimedOut = $false

    while ($Process.HasExited -eq $false) {
        Start-Sleep -Seconds 1

        $Now = Get-Date
        $ElapsedSeconds = [int]($Now - $StartTime).TotalSeconds
        $HeartbeatElapsedSeconds = [int]($Now - $LastHeartbeat).TotalSeconds

        if ($HeartbeatElapsedSeconds -ge $HEARTBEAT_SECONDS) {
            $ElapsedText = Format-Duration -Duration ($Now - $StartTime)
            Write-Host "[WAIT] $StepName ancora in corso. Tempo trascorso: $ElapsedText" -ForegroundColor DarkYellow
            Write-LogLine -Level "WAIT" -Message "$StepName ancora in corso. Tempo trascorso: $ElapsedText"
            $LastHeartbeat = Get-Date
        }

        if ($ElapsedSeconds -ge $TimeoutSeconds) {
            $TimedOut = $true
            Write-Err "Timeout raggiunto per: $StepName"
            Write-Err "Il processo verrà terminato per evitare un blocco indefinito."

            try {
                $Process.Kill()
            } catch {
                Write-Warn "Impossibile terminare il processo in modo controllato."
            }

            break
        }
    }

    $StandardOutput = $Process.StandardOutput.ReadToEnd()
    $StandardError = $Process.StandardError.ReadToEnd()

    if ($StandardOutput.Trim() -ne "") {
        Write-Host $StandardOutput
        Add-Content -Path $LOG_FILE -Value $StandardOutput -Encoding UTF8

        if ($ExtraLogFile -ne "") {
            Add-Content -Path $ExtraLogFile -Value $StandardOutput -Encoding UTF8
        }
    }

    if ($StandardError.Trim() -ne "") {
        Write-Host $StandardError -ForegroundColor DarkYellow
        Add-Content -Path $LOG_FILE -Value $StandardError -Encoding UTF8

        if ($ExtraLogFile -ne "") {
            Add-Content -Path $ExtraLogFile -Value $StandardError -Encoding UTF8
        }
    }

    if ($TimedOut -eq $true) {
        if ($ExtraLogFile -ne "") {
            Add-Content -Path $ExtraLogFile -Value "[TIMEOUT] Processo interrotto per superamento timeout." -Encoding UTF8
        }

        return 124
    }

    $ExitCode = $Process.ExitCode
    Write-Info "Terminato: $StepName - codice $ExitCode"

    if ($ExtraLogFile -ne "") {
        Add-Content -Path $ExtraLogFile -Value "[EXIT CODE] $ExitCode" -Encoding UTF8
    }

    return $ExitCode
}

# --------------------------------------------------------------------------------------------------
# Funzioni requirements
# --------------------------------------------------------------------------------------------------

function Get-RequirementPackages {
    param (
        [string]$Path
    )

    $Packages = @()
    $Lines = Get-Content -Path $Path -Encoding UTF8

    foreach ($Line in $Lines) {
        $CleanLine = $Line.Trim()

        if ($CleanLine -eq "") {
            continue
        }

        if ($CleanLine.StartsWith("#")) {
            continue
        }

        if ($CleanLine.StartsWith("-r ")) {
            Write-Warn "Riga requirements ignorata perché include un altro file: $CleanLine"
            continue
        }

        if ($CleanLine.StartsWith("--")) {
            Write-Warn "Opzione globale pip ignorata in lettura pacchetti: $CleanLine"
            continue
        }

        $Packages += $CleanLine
    }

    return $Packages
}

function Get-PackageDisplayName {
    param (
        [string]$RequirementLine
    )

    # ----------------------------------------------------------------------------------------------
    # Estrae un nome leggibile da righe come:
    #   opencv-python
    #   numpy>=1.26
    #   ultralytics==8.3.0
    # ----------------------------------------------------------------------------------------------

    $Name = $RequirementLine

    $Separators = @("==", ">=", "<=", "~=", "!=", ">", "<")

    foreach ($Separator in $Separators) {
        $Index = $Name.IndexOf($Separator)

        if ($Index -gt 0) {
            $Name = $Name.Substring(0, $Index)
        }
    }

    $Name = $Name.Trim()

    return $Name
}

# --------------------------------------------------------------------------------------------------
# Avvio
# --------------------------------------------------------------------------------------------------

Clear-Host

if (Test-Path $LOG_FILE) {
    Remove-Item $LOG_FILE -Force
}

if (Test-Path $PIP_LOG_FILE) {
    Remove-Item $PIP_LOG_FILE -Force
}

Write-Host ""
Write-Host "=================================================================================================="
Write-Host " SETUP WINDOWS - OpenCV / YOLO Lab - versione 3 con avanzamento pacchetti"
Write-Host "=================================================================================================="
Write-Host ""

Write-LogLine -Level "INFO" -Message "Avvio setup Windows v3."

$PROJECT_DIR = Get-Location
Write-Info "Cartella progetto: $PROJECT_DIR"
Write-Info "Log generale: $PROJECT_DIR\$LOG_FILE"
Write-Info "Log pip:      $PROJECT_DIR\$PIP_LOG_FILE"

# --------------------------------------------------------------------------------------------------
# Controllo file
# --------------------------------------------------------------------------------------------------

Write-StepTitle "1. Controllo file di progetto"

if (-not (Test-Path $REQUIREMENTS_FILE)) {
    Write-Err "File '$REQUIREMENTS_FILE' non trovato nella cartella corrente."
    Write-Host ""
    Write-Host "Soluzione:"
    Write-Host "  Copiare questo script nella stessa cartella del file requirements.txt."
    Write-Host ""
    exit 1
}

Write-Info "Trovato file: $REQUIREMENTS_FILE"

$Packages = Get-RequirementPackages -Path $REQUIREMENTS_FILE

if ($Packages.Count -eq 0) {
    Write-Err "Il file requirements.txt non contiene pacchetti installabili."
    exit 1
}

Write-Info "Pacchetti individuati in requirements.txt: $($Packages.Count)"

for ($Index = 0; $Index -lt $Packages.Count; $Index++) {
    $Number = $Index + 1
    Write-Host "  [$Number/$($Packages.Count)] $($Packages[$Index])"
}

# --------------------------------------------------------------------------------------------------
# Controllo Python
# --------------------------------------------------------------------------------------------------

Write-StepTitle "2. Controllo Python"

$PYTHON_CMD = Get-PythonCommand

if ($PYTHON_CMD -eq "") {
    Write-Err "Python non trovato."
    Write-Host ""
    Write-Host "Installare Python 3 da:"
    Write-Host "  https://www.python.org/downloads/windows/"
    Write-Host ""
    Write-Host "Durante l'installazione selezionare:"
    Write-Host "  [x] Add python.exe to PATH"
    Write-Host ""
    exit 1
}

Write-Info "Comando Python rilevato: $PYTHON_CMD"

$PythonVersionExitCode = Invoke-CommandWithHeartbeat `
    -CommandLine "$PYTHON_CMD --version" `
    -StepName "Verifica versione Python" `
    -TimeoutSeconds $SHORT_COMMAND_TIMEOUT_SECONDS

if ($PythonVersionExitCode -ne 0) {
    Write-Err "La verifica Python non è riuscita."
    exit 1
}

# --------------------------------------------------------------------------------------------------
# Creazione venv
# --------------------------------------------------------------------------------------------------

Write-StepTitle "3. Creazione / verifica ambiente virtuale"

if (Test-Path $VENV_NAME) {
    Write-Warn "Ambiente virtuale '$VENV_NAME' già presente. Non verrà ricreato."
} else {
    $CreateVenvExitCode = Invoke-CommandWithHeartbeat `
        -CommandLine "$PYTHON_CMD -m venv `"$VENV_NAME`"" `
        -StepName "Creazione ambiente virtuale $VENV_NAME" `
        -TimeoutSeconds 180

    if ($CreateVenvExitCode -ne 0) {
        Write-Err "Creazione ambiente virtuale non riuscita."
        exit 1
    }
}

$VENV_PYTHON = Join-Path $PROJECT_DIR "$VENV_NAME\Scripts\python.exe"
$VENV_PIP = Join-Path $PROJECT_DIR "$VENV_NAME\Scripts\pip.exe"

if (-not (Test-Path $VENV_PYTHON)) {
    Write-Err "Python del venv non trovato: $VENV_PYTHON"
    exit 1
}

if (-not (Test-Path $VENV_PIP)) {
    Write-Err "pip del venv non trovato: $VENV_PIP"
    exit 1
}

Write-Info "Python venv: $VENV_PYTHON"
Write-Info "pip venv:    $VENV_PIP"

# --------------------------------------------------------------------------------------------------
# Diagnostica pip
# --------------------------------------------------------------------------------------------------

Write-StepTitle "4. Diagnostica pip"

$PipVersionExitCode = Invoke-CommandWithHeartbeat `
    -CommandLine "`"$VENV_PYTHON`" -m pip --version" `
    -StepName "Verifica pip nel venv" `
    -TimeoutSeconds $SHORT_COMMAND_TIMEOUT_SECONDS `
    -ExtraLogFile $PIP_LOG_FILE

if ($PipVersionExitCode -ne 0) {
    Write-Err "pip non risponde correttamente nell'ambiente virtuale."
    Write-Host ""
    Write-Host "Possibile soluzione:"
    Write-Host "  Eliminare la cartella $VENV_NAME e rieseguire il setup."
    Write-Host ""
    exit 1
}

# --------------------------------------------------------------------------------------------------
# Aggiornamento pip
# --------------------------------------------------------------------------------------------------

Write-StepTitle "5. Aggiornamento pip"

if ($SkipPipUpgrade -eq $true) {
    Write-Warn "Aggiornamento pip saltato per parametro -SkipPipUpgrade."
} else {
    $UpgradeCommand = "`"$VENV_PYTHON`" -m pip install --upgrade pip --disable-pip-version-check --no-input $PIP_EXTRA_OPTIONS"

    $PipUpgradeExitCode = Invoke-CommandWithHeartbeat `
        -CommandLine $UpgradeCommand `
        -StepName "Aggiornamento pip" `
        -TimeoutSeconds $PIP_UPGRADE_TIMEOUT_SECONDS `
        -ExtraLogFile $PIP_LOG_FILE

    if ($PipUpgradeExitCode -eq 124) {
        Write-Warn "Aggiornamento pip interrotto per timeout."
        Write-Warn "Il setup continuerà usando la versione attuale di pip."
    } elseif ($PipUpgradeExitCode -ne 0) {
        Write-Warn "Aggiornamento pip non riuscito."
        Write-Warn "Il setup continuerà usando la versione attuale di pip."
    } else {
        Write-Info "Aggiornamento pip completato."
    }
}

# --------------------------------------------------------------------------------------------------
# Installazione pacchetti uno alla volta
# --------------------------------------------------------------------------------------------------

Write-StepTitle "6. Installazione dipendenze una alla volta"

$SuccessfulPackages = @()
$FailedPackages = @()
$TotalStartTime = Get-Date

for ($Index = 0; $Index -lt $Packages.Count; $Index++) {
    $Package = $Packages[$Index]
    $PackageNumber = $Index + 1
    $PackageName = Get-PackageDisplayName -RequirementLine $Package
    $PackageStartTime = Get-Date

    Write-Host ""
    Write-Host "--------------------------------------------------------------------------------------------------"
    Write-Host " Pacchetto [$PackageNumber/$($Packages.Count)]: $Package"
    Write-Host "--------------------------------------------------------------------------------------------------"
    Write-Host ""

    Write-Info "Inizio installazione pacchetto [$PackageNumber/$($Packages.Count)]: $Package"

    $ForceOption = ""

    if ($FORCE_REINSTALL_PACKAGES -eq $true) {
        $ForceOption = "--force-reinstall"
    }

    $PackageCommand = "`"$VENV_PYTHON`" -m pip install `"$Package`" --disable-pip-version-check --no-input $ForceOption $PIP_EXTRA_OPTIONS"

    $PackageExitCode = Invoke-CommandWithHeartbeat `
        -CommandLine $PackageCommand `
        -StepName "Pacchetto [$PackageNumber/$($Packages.Count)] $Package" `
        -TimeoutSeconds $PACKAGE_TIMEOUT_SECONDS `
        -ExtraLogFile $PIP_LOG_FILE

    $PackageDuration = Get-Date -Date (Get-Date)
    $ElapsedText = Format-Duration -Duration ((Get-Date) - $PackageStartTime)

    if ($PackageExitCode -eq 0) {
        $SuccessfulPackages += $Package
        Write-Info "Pacchetto completato: $Package - durata: $ElapsedText"
    } elseif ($PackageExitCode -eq 124) {
        $FailedPackages += "$Package [TIMEOUT]"
        Write-Err "Timeout durante l'installazione di: $Package"
        Write-Err "Durata prima dell'interruzione: $ElapsedText"

        if ($ContinueOnPackageError -eq $false) {
            Write-Err "Installazione interrotta. Per continuare anche in caso di errore usare -ContinueOnPackageError."
            break
        }
    } else {
        $FailedPackages += "$Package [ERRORE $PackageExitCode]"
        Write-Err "Installazione fallita per: $Package"
        Write-Err "Codice errore: $PackageExitCode"
        Write-Err "Durata: $ElapsedText"

        if ($ContinueOnPackageError -eq $false) {
            Write-Err "Installazione interrotta. Per continuare anche in caso di errore usare -ContinueOnPackageError."
            break
        }
    }

    $Completed = $Index + 1
    $Remaining = $Packages.Count - $Completed

    Write-Host ""
    Write-Host "[PROGRESSO] Completati: $Completed / $($Packages.Count) - Rimanenti: $Remaining" -ForegroundColor Green
    Write-Host ""
}

$TotalElapsedText = Format-Duration -Duration ((Get-Date) - $TotalStartTime)

# --------------------------------------------------------------------------------------------------
# Riepilogo installazione pacchetti
# --------------------------------------------------------------------------------------------------

Write-StepTitle "7. Riepilogo installazione dipendenze"

Write-Host "Tempo totale fase dipendenze: $TotalElapsedText"
Write-Host ""

Write-Host "Pacchetti completati: $($SuccessfulPackages.Count)"
foreach ($Item in $SuccessfulPackages) {
    Write-Host "  [OK] $Item" -ForegroundColor Green
}

Write-Host ""

Write-Host "Pacchetti con problemi: $($FailedPackages.Count)"
foreach ($Item in $FailedPackages) {
    Write-Host "  [NO] $Item" -ForegroundColor Red
}

if ($FailedPackages.Count -gt 0) {
    Write-Host ""
    Write-Err "Alcuni pacchetti non sono stati installati correttamente."
    Write-Host ""
    Write-Host "Consultare:"
    Write-Host "  $LOG_FILE"
    Write-Host "  $PIP_LOG_FILE"
    Write-Host ""

    if ($ContinueOnPackageError -eq $false) {
        exit 1
    }
}

# --------------------------------------------------------------------------------------------------
# Verifiche finali
# --------------------------------------------------------------------------------------------------

Write-StepTitle "8. Verifica OpenCV"

$OpenCvExitCode = Invoke-CommandWithHeartbeat `
    -CommandLine "`"$VENV_PYTHON`" -c `"import cv2; print('OpenCV:', cv2.__version__)`"" `
    -StepName "Importazione OpenCV" `
    -TimeoutSeconds $SHORT_COMMAND_TIMEOUT_SECONDS

if ($OpenCvExitCode -ne 0) {
    Write-Err "OpenCV non risulta importabile."
    Write-Host ""
    Write-Host "Se nel log compare opencv-python-headless, sostituirlo con opencv-python."
    Write-Host ""
    exit 1
}

Write-StepTitle "9. Verifica Ultralytics YOLO"

$YoloExitCode = Invoke-CommandWithHeartbeat `
    -CommandLine "`"$VENV_PYTHON`" -c `"from ultralytics import YOLO; print('Ultralytics YOLO: OK')`"" `
    -StepName "Importazione Ultralytics YOLO" `
    -TimeoutSeconds 120

if ($YoloExitCode -ne 0) {
    Write-Warn "Ultralytics non risulta importabile."
    Write-Warn "Se il programma usa YOLO, verificare il pacchetto ultralytics nel log."
}

# --------------------------------------------------------------------------------------------------
# Controllo FFmpeg
# --------------------------------------------------------------------------------------------------

Write-StepTitle "10. Controllo FFmpeg"

if (Test-CommandAvailable "ffmpeg") {
    Write-Info "ffmpeg trovato nel PATH."
} else {
    Write-Warn "ffmpeg non trovato nel PATH."
}

if (Test-CommandAvailable "ffprobe") {
    Write-Info "ffprobe trovato nel PATH."
} else {
    Write-Warn "ffprobe non trovato nel PATH."
}

if (-not (Test-CommandAvailable "ffmpeg") -or -not (Test-CommandAvailable "ffprobe")) {
    Write-Host ""
    Write-Warn "Per gli stream RTSP è consigliato installare FFmpeg e aggiungerlo al PATH."
    Write-Host ""
    Write-Host "Variabile d'ambiente da modificare:"
    Write-Host "  Path"
    Write-Host ""
    Write-Host "Cartella da aggiungere, esempio:"
    Write-Host "  C:\ffmpeg\bin"
    Write-Host ""
}

# --------------------------------------------------------------------------------------------------
# Fine
# --------------------------------------------------------------------------------------------------

Write-Host ""
Write-Host "=================================================================================================="
Write-Host " SETUP COMPLETATO"
Write-Host "=================================================================================================="
Write-Host ""
Write-Host "Log generale:"
Write-Host "  $LOG_FILE"
Write-Host ""
Write-Host "Log pip dettagliato:"
Write-Host "  $PIP_LOG_FILE"
Write-Host ""
Write-Host "Per avviare il programma:"
Write-Host "  powershell -ExecutionPolicy Bypass -File .\run_yolo_windows.ps1"
Write-Host ""
Write-Host "Oppure:"
Write-Host "  run_yolo_windows.bat"
Write-Host ""

Write-LogLine -Level "INFO" -Message "Setup completato."
