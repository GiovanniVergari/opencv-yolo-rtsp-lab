#!/bin/bash

# ============================================================
#  AVVIO YOLO / RTSP - VM LABORATORIO
# ============================================================
#
#  Questo script serve per:
#  - cercare il programma Python nella Scrivania;
#  - selezionare l'ambiente virtuale Python;
#  - correggere eventuali fine riga Windows;
#  - avviare il programma YOLO.
#
#  Uso consigliato:
#      cd ~/Scrivania
#      chmod +x avvia_yolo.sh
#      ./avvia_yolo.sh
#
# ============================================================


# ------------------------------------------------------------
#  VARIABILI MODIFICABILI
# ------------------------------------------------------------

# Cartella principale di lavoro.
PROJECT_DIR="$HOME/Scrivania"

# Nome del file Python da avviare.
# Se il file cambia nome, modificare solo questa riga.
MAIN_SCRIPT_NAME="rtsp_yolo_viewer_v2.py"

# Percorso completo del file Python.
MAIN_SCRIPT="$PROJECT_DIR/$MAIN_SCRIPT_NAME"

# Percorsi possibili degli ambienti virtuali.
# Lo script proporrà quelli realmente presenti.
VENV_1="$PROJECT_DIR/venv"
VENV_2="$HOME/venv"
VENV_3="$PROJECT_DIR/.venv"
VENV_4="$HOME/.venv"


# ------------------------------------------------------------
#  FUNZIONI DI STAMPA
# ------------------------------------------------------------

print_info() {
    echo "[INFO] $1"
}

print_ok() {
    echo "[OK] $1"
}

print_warning() {
    echo "[ATTENZIONE] $1"
}

print_error() {
    echo "[ERRORE] $1"
}

print_separator() {
    echo "------------------------------------------------------------"
}


# ------------------------------------------------------------
#  INTESTAZIONE
# ------------------------------------------------------------

clear

echo "============================================================"
echo "  AVVIO YOLO / RTSP"
echo "============================================================"
echo


# ------------------------------------------------------------
#  CONTROLLO CARTELLA DI LAVORO
# ------------------------------------------------------------

print_info "Controllo della cartella di lavoro..."

if [ ! -d "$PROJECT_DIR" ]; then
    print_error "La cartella di lavoro non esiste:"
    echo "$PROJECT_DIR"
    echo
    print_error "Modificare PROJECT_DIR all'inizio dello script."
    exit 1
fi

cd "$PROJECT_DIR" || exit 1

print_ok "Cartella di lavoro:"
echo "$PROJECT_DIR"
echo


# ------------------------------------------------------------
#  CONTROLLO DEL FILE PYTHON
# ------------------------------------------------------------

print_info "Controllo del file Python principale..."

if [ ! -f "$MAIN_SCRIPT" ]; then
    print_error "File Python non trovato:"
    echo "$MAIN_SCRIPT"
    echo
    print_info "File Python presenti nella cartella:"
    ls -1 "$PROJECT_DIR"/*.py 2>/dev/null
    echo
    print_error "Modificare MAIN_SCRIPT_NAME all'inizio dello script."
    exit 1
fi

print_ok "File Python trovato:"
echo "$MAIN_SCRIPT"
echo


# ------------------------------------------------------------
#  CORREZIONE FINE RIGA WINDOWS
# ------------------------------------------------------------

print_info "Correzione eventuali fine riga Windows..."

sed -i 's/\r$//' "$MAIN_SCRIPT"

print_ok "Formato del file Python controllato."
echo


# ------------------------------------------------------------
#  PREPARAZIONE ELENCO AMBIENTI VIRTUALI
# ------------------------------------------------------------

AVAILABLE_VENVS=()

if [ -f "$VENV_1/bin/activate" ]; then
    AVAILABLE_VENVS+=("$VENV_1")
fi

if [ -f "$VENV_2/bin/activate" ]; then
    AVAILABLE_VENVS+=("$VENV_2")
fi

if [ -f "$VENV_3/bin/activate" ]; then
    AVAILABLE_VENVS+=("$VENV_3")
fi

if [ -f "$VENV_4/bin/activate" ]; then
    AVAILABLE_VENVS+=("$VENV_4")
fi


# ------------------------------------------------------------
#  SELEZIONE DELL'AMBIENTE
# ------------------------------------------------------------

echo "Selezionare l'ambiente Python da usare:"
echo

OPTION_NUMBER=1

for VENV_PATH in "${AVAILABLE_VENVS[@]}"; do
    echo "  $OPTION_NUMBER) Ambiente virtuale: $VENV_PATH"
    OPTION_NUMBER=$((OPTION_NUMBER + 1))
done

SYSTEM_OPTION=$OPTION_NUMBER
echo "  $SYSTEM_OPTION) Python di sistema"

echo

read -p "Scelta: " SCELTA

echo


# ------------------------------------------------------------
#  VALIDAZIONE DELLA SCELTA
# ------------------------------------------------------------

if ! [[ "$SCELTA" =~ ^[0-9]+$ ]]; then
    print_error "Scelta non valida."
    exit 1
fi

if [ "$SCELTA" -lt 1 ]; then
    print_error "Scelta non valida."
    exit 1
fi

if [ "$SCELTA" -gt "$SYSTEM_OPTION" ]; then
    print_error "Scelta non valida."
    exit 1
fi


# ------------------------------------------------------------
#  ATTIVAZIONE AMBIENTE VIRTUALE
# ------------------------------------------------------------

if [ "$SCELTA" -lt "$SYSTEM_OPTION" ]; then

    SELECTED_INDEX=$((SCELTA - 1))
    SELECTED_VENV="${AVAILABLE_VENVS[$SELECTED_INDEX]}"

    print_info "Attivazione ambiente virtuale:"
    echo "$SELECTED_VENV"
    echo

    source "$SELECTED_VENV/bin/activate"

    if [ $? -ne 0 ]; then
        print_error "Impossibile attivare l'ambiente virtuale selezionato."
        exit 1
    fi

    print_ok "Ambiente virtuale attivato."
    echo

else

    print_warning "Uso di Python di sistema."
    print_warning "Questa opzione può non funzionare se le librerie sono installate nel venv."
    echo

fi


# ------------------------------------------------------------
#  CONTROLLO PYTHON DISPONIBILE
# ------------------------------------------------------------

print_info "Controllo interprete Python..."

PYTHON_CMD=""

if command -v python > /dev/null 2>&1; then
    PYTHON_CMD="python"
fi

if [ "$PYTHON_CMD" = "" ]; then
    if command -v python3 > /dev/null 2>&1; then
        PYTHON_CMD="python3"
    fi
fi

if [ "$PYTHON_CMD" = "" ]; then
    print_error "Nessun interprete Python trovato."
    exit 1
fi

print_ok "Interprete selezionato:"
which "$PYTHON_CMD"
"$PYTHON_CMD" --version
echo


# ------------------------------------------------------------
#  CONTROLLO LIBRERIE PRINCIPALI
# ------------------------------------------------------------

print_info "Controllo rapido delle librerie principali..."

"$PYTHON_CMD" - <<'PYTHON_CHECK'
import sys

required_modules = [
    "cv2",
    "numpy"
]

missing_modules = []

for module_name in required_modules:
    try:
        __import__(module_name)
    except Exception:
        missing_modules.append(module_name)

if len(missing_modules) > 0:
    print("[ATTENZIONE] Alcune librerie non risultano disponibili:")
    for module_name in missing_modules:
        print(" - " + module_name)
    print("[ATTENZIONE] Il programma verrà avviato comunque.")
else:
    print("[OK] Librerie principali disponibili.")
PYTHON_CHECK

echo


# ------------------------------------------------------------
#  AVVIO DEL PROGRAMMA
# ------------------------------------------------------------

print_separator
print_info "Avvio del programma YOLO..."
print_separator
echo

"$PYTHON_CMD" "$MAIN_SCRIPT"

EXIT_CODE=$?

echo
print_separator

if [ $EXIT_CODE -eq 0 ]; then
    print_ok "Programma terminato correttamente."
else
    print_error "Programma terminato con codice:"
    echo "$EXIT_CODE"
fi

print_separator
echo

exit $EXIT_CODE
