#!/bin/bash

# ============================================================
# setup_vm_opencv_lab_v2.sh
# ============================================================
#
# Scopo:
# Preparare una nuova VM Ubuntu / Xubuntu / Debian per
# eseguire rapidamente progetti Python didattici basati su:
# - OpenCV
# - streaming video / webcam / IP camera
# - YOLO tramite Ultralytics
# - PyTorch
#
# File richiesti nella stessa cartella:
# - setup_vm_opencv_lab_v2.sh
# - requirements.txt
#
# Nota importante:
# La versione precedente separava le dipendenze in:
# - requirements.txt
# - requirements-advanced.txt
#
# Questa versione usa un solo file requirements.txt.
# Il file requirements-advanced.txt non è più necessario.
#
# Uso consigliato:
#   chmod +x setup_vm_opencv_lab_v2.sh
#   ./setup_vm_opencv_lab_v2.sh
#
# Opzioni:
#   ./setup_vm_opencv_lab_v2.sh --skip-upgrade
#       Salta apt upgrade per velocizzare il setup.
#
#   ./setup_vm_opencv_lab_v2.sh --advanced
#       Opzione mantenuta solo per compatibilità con vecchie istruzioni.
#       Non cambia il comportamento: tutte le librerie vengono installate
#       da requirements.txt.
#
# ============================================================

set -u

# ============================================================
# CONFIGURAZIONE PRINCIPALE
# ============================================================

VENV_DIR="venv"
PYTHON_BIN="python3"
PIP_IN_VENV="$VENV_DIR/bin/pip"
PYTHON_IN_VENV="$VENV_DIR/bin/python"
ACTIVATE_SCRIPT="attiva_ambiente.sh"
LOG_FILE="setup_vm_opencv_lab.log"
TMP_BASE_DIR="$HOME/pip_tmp"
TMP_WORK_DIR="$TMP_BASE_DIR/work"
PIP_CACHE_DIR="$TMP_BASE_DIR/cache"
REQUIREMENTS_FILE="requirements.txt"

SKIP_UPGRADE="0"
ADVANCED_FLAG_USED="0"

# ============================================================
# FUNZIONI DI SUPPORTO
# ============================================================

print_info() {
    echo "[INFO] $1"
}

print_ok() {
    echo "[OK] $1"
}

print_warn() {
    echo "[ATTENZIONE] $1"
}

print_err() {
    echo "[ERRORE] $1"
}

exit_with_error() {
    print_err "$1"
    exit 1
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

run_cmd() {
    local description="$1"
    shift

    print_info "$description"
    "$@"
    local exit_code=$?

    if [ "$exit_code" -ne 0 ]; then
        exit_with_error "Operazione fallita: $description"
    fi

    print_ok "$description completata"
}

show_help() {
    echo "Uso:"
    echo "  ./setup_vm_opencv_lab_v2.sh [opzioni]"
    echo
    echo "Opzioni disponibili:"
    echo "  --skip-upgrade  Salta apt upgrade"
    echo "  --advanced      Compatibilità: non più necessario"
    echo "  --help          Mostra questo aiuto"
    echo
    echo "File necessari:"
    echo "  requirements.txt"
}

# ============================================================
# PARSING ARGOMENTI
# ============================================================

for arg in "$@"; do
    if [ "$arg" = "--skip-upgrade" ]; then
        SKIP_UPGRADE="1"
    elif [ "$arg" = "--advanced" ]; then
        ADVANCED_FLAG_USED="1"
    elif [ "$arg" = "--help" ]; then
        show_help
        exit 0
    else
        exit_with_error "Opzione non riconosciuta: $arg"
    fi
done

# ============================================================
# VERIFICHE PRELIMINARI
# ============================================================

if ! command_exists sudo; then
    exit_with_error "Il comando sudo non è disponibile."
fi

if ! command_exists apt-get; then
    exit_with_error "Questo script richiede una distribuzione basata su APT."
fi

# ============================================================
# LOG
# ============================================================

print_info "Il log sarà salvato in: $LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

if [ "$ADVANCED_FLAG_USED" = "1" ]; then
    print_warn "L'opzione --advanced è stata mantenuta solo per compatibilità."
    print_warn "Tutte le dipendenze, comprese YOLO e PyTorch, vengono installate da $REQUIREMENTS_FILE."
fi

# ============================================================
# INFORMAZIONI DISCO
# ============================================================

print_info "Situazione iniziale dello spazio su disco"
df -h

# ============================================================
# PREPARAZIONE DIRECTORY TEMPORANEE SICURE
# ============================================================

print_info "Preparazione directory temporanee per pip"

mkdir -p "$TMP_WORK_DIR"
mkdir -p "$PIP_CACHE_DIR"

if [ ! -d "$TMP_WORK_DIR" ]; then
    exit_with_error "Impossibile creare la directory temporanea di lavoro."
fi

if [ ! -d "$PIP_CACHE_DIR" ]; then
    exit_with_error "Impossibile creare la directory cache di pip."
fi

export TMPDIR="$TMP_WORK_DIR"
export PIP_CACHE_DIR="$PIP_CACHE_DIR"

print_ok "TMPDIR impostata su: $TMPDIR"
print_ok "PIP_CACHE_DIR impostata su: $PIP_CACHE_DIR"

# ============================================================
# AGGIORNAMENTO SISTEMA
# ============================================================

run_cmd "Aggiornamento indice pacchetti" sudo apt-get update

if [ "$SKIP_UPGRADE" = "0" ]; then
    run_cmd "Aggiornamento pacchetti installati" sudo apt-get -y upgrade
else
    print_warn "apt upgrade saltato su richiesta."
fi

# ============================================================
# INSTALLAZIONE PACCHETTI DI SISTEMA
# ============================================================

SYSTEM_PACKAGES=(
    python3
    python3-venv
    python3-pip
    python3-dev
    python3-tk
    build-essential
    cmake
    pkg-config
    git
    curl
    wget
    unzip
    ffmpeg
    vlc
    net-tools
    iputils-ping
    v4l-utils
    libgl1
    libglib2.0-0
    libsm6
    libxext6
    libxrender1
    libgomp1
    libgtk-3-0
)

run_cmd "Installazione dipendenze di sistema" sudo apt-get install -y "${SYSTEM_PACKAGES[@]}"

# ============================================================
# VERIFICA PYTHON
# ============================================================

if ! command_exists "$PYTHON_BIN"; then
    exit_with_error "Python3 non risulta installato correttamente."
fi

PYTHON_VERSION=$($PYTHON_BIN --version 2>&1)
print_ok "Versione Python rilevata: $PYTHON_VERSION"

# ============================================================
# CREAZIONE AMBIENTE VIRTUALE
# ============================================================

if [ -d "$VENV_DIR" ]; then
    print_warn "La directory $VENV_DIR esiste già. Verrà riutilizzata."
else
    run_cmd "Creazione ambiente virtuale Python" "$PYTHON_BIN" -m venv "$VENV_DIR"
fi

if [ ! -f "$VENV_DIR/bin/activate" ]; then
    exit_with_error "Ambiente virtuale non creato correttamente."
fi

# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"

if [ ! -x "$PIP_IN_VENV" ]; then
    exit_with_error "pip non è disponibile nell'ambiente virtuale."
fi

if [ ! -x "$PYTHON_IN_VENV" ]; then
    exit_with_error "python non è disponibile nell'ambiente virtuale."
fi

# ============================================================
# AGGIORNAMENTO TOOLING PYTHON
# ============================================================

run_cmd "Aggiornamento pip" "$PIP_IN_VENV" install --upgrade pip --no-cache-dir
run_cmd "Aggiornamento setuptools" "$PIP_IN_VENV" install --upgrade setuptools --no-cache-dir
run_cmd "Aggiornamento wheel" "$PIP_IN_VENV" install --upgrade wheel --no-cache-dir

# ============================================================
# VERIFICA / CREAZIONE REQUIREMENTS UNICO
# ============================================================

if [ -f "$REQUIREMENTS_FILE" ]; then
    print_ok "Trovato file $REQUIREMENTS_FILE"
else
    print_warn "File $REQUIREMENTS_FILE non trovato. Verrà creato un file standard."

    cat > "$REQUIREMENTS_FILE" <<'REQEOF'
numpy
scipy
pandas
matplotlib
opencv-python
opencv-contrib-python
pillow
requests
tqdm
psutil
pyyaml
imageio
imageio-ffmpeg
pyserial
rich
jupyter
notebook
ipykernel
ultralytics
torch
torchvision
REQEOF

    print_ok "Creato file $REQUIREMENTS_FILE"
fi

# ============================================================
# INSTALLAZIONE LIBRERIE PYTHON
# ============================================================

print_info "Installazione librerie Python da $REQUIREMENTS_FILE"
print_warn "Questa fase include anche YOLO / Ultralytics e PyTorch."
print_warn "In una VM con poco spazio disco può richiedere tempo e spazio temporaneo."

run_cmd \
    "Installazione librerie Python" \
    "$PIP_IN_VENV" install --no-cache-dir --prefer-binary -r "$REQUIREMENTS_FILE"

# ============================================================
# TEST RAPIDI AMBIENTE
# ============================================================

print_info "Esecuzione test finali dell'ambiente Python"

"$PYTHON_IN_VENV" - <<'PYEOF'
import sys

print("[TEST] Python OK:", sys.version)

try:
    import cv2
    print("[TEST] OpenCV OK:", cv2.__version__)
except Exception as exc:
    print("[TEST] OpenCV ERRORE:", exc)
    raise

try:
    import numpy
    print("[TEST] NumPy OK:", numpy.__version__)
except Exception as exc:
    print("[TEST] NumPy ERRORE:", exc)
    raise

try:
    import pandas
    print("[TEST] Pandas OK:", pandas.__version__)
except Exception as exc:
    print("[TEST] Pandas ERRORE:", exc)
    raise

try:
    import requests
    print("[TEST] Requests OK:", requests.__version__)
except Exception as exc:
    print("[TEST] Requests ERRORE:", exc)
    raise

try:
    import PIL
    print("[TEST] Pillow OK")
except Exception as exc:
    print("[TEST] Pillow ERRORE:", exc)
    raise

try:
    import ultralytics
    print("[TEST] Ultralytics OK:", ultralytics.__version__)
except Exception as exc:
    print("[TEST] Ultralytics ERRORE:", exc)
    raise

try:
    import torch
    print("[TEST] Torch OK:", torch.__version__)
except Exception as exc:
    print("[TEST] Torch ERRORE:", exc)
    raise
PYEOF

if [ "$?" -ne 0 ]; then
    exit_with_error "I test Python finali non sono andati a buon fine."
fi

# ============================================================
# SCRIPT DI ATTIVAZIONE RAPIDA
# ============================================================

cat > "$ACTIVATE_SCRIPT" <<'ACTEOF'
#!/bin/bash

# ============================================================
# attiva_ambiente.sh
# ============================================================
#
# Uso:
#   source ./attiva_ambiente.sh
#
# Scopo:
# Attivare rapidamente l'ambiente virtuale Python del laboratorio.
#
# ============================================================

if [ -f "venv/bin/activate" ]; then
    # shellcheck disable=SC1091
    source "venv/bin/activate"
    echo "[OK] Ambiente virtuale attivato."
    python --version
else
    echo "[ERRORE] File venv/bin/activate non trovato."
fi
ACTEOF

chmod +x "$ACTIVATE_SCRIPT"
print_ok "Creato script rapido: $ACTIVATE_SCRIPT"

# ============================================================
# PULIZIA FINALE
# ============================================================

print_info "Pulizia file temporanei di pip"

rm -rf "$TMP_WORK_DIR"
mkdir -p "$TMP_WORK_DIR"

print_ok "Pulizia temporanei completata"

# ============================================================
# RIEPILOGO FINALE
# ============================================================

echo
echo "============================================================"
echo "SETUP COMPLETATO"
echo "============================================================"
echo "Ambiente virtuale  : $VENV_DIR"
echo "Script attivazione : $ACTIVATE_SCRIPT"
echo "Requirements       : $REQUIREMENTS_FILE"
echo "Log                : $LOG_FILE"
echo
echo "File necessari da mantenere:"
echo "  - setup_vm_opencv_lab_v2.sh"
echo "  - requirements.txt"
echo
echo "File non più necessario:"
echo "  - requirements-advanced.txt"
echo
echo "Comandi utili:"
echo "  source $ACTIVATE_SCRIPT"
echo "  python nome_script.py"
echo "  python -c \"import cv2; print(cv2.__version__)\""
echo "  python -c \"from ultralytics import YOLO; print('YOLO OK')\""
echo "============================================================"
