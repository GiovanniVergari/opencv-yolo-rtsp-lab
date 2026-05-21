# OpenCV YOLO RTSP Lab

Laboratorio didattico per configurare un ambiente Python ed eseguire il riconoscimento oggetti in tempo reale su flussi video RTSP, utilizzando OpenCV, Ultralytics YOLO e PyTorch.

Il progetto è pensato per attività di laboratorio scolastico su:

- acquisizione video da IP camera tramite RTSP;
- uso di OpenCV per visualizzare ed elaborare immagini;
- uso di YOLO per il riconoscimento automatico degli oggetti;
- preparazione automatizzata dell'ambiente Python su Linux e Windows;
- esecuzione guidata del programma tramite script di avvio.

---

## Struttura della repository

```text
opencv-yolo-rtsp-lab/
│
├── LICENSE
│
├── yolo_lab_linux/
│   ├── avvia_yolo.sh
│   ├── requirements.txt
│   ├── rtsp_yolo_viewer_v2.py
│   └── setup_vm_opencv_lab_v2.sh
│
└── yolo_lab_win/
    ├── requirements.txt
    ├── rtsp_yolo_viewer_v2.py
    ├── run_yolo_windows.bat
    ├── run_yolo_windows.ps1
    ├── setup_windows_opencv_lab_v3.bat
    └── setup_windows_opencv_lab_v3.ps1
```

---

## Funzionamento generale

Il programma principale è:

```text
rtsp_yolo_viewer_v2.py
```

Lo script Python:

- apre un flusso video RTSP;
- carica un modello YOLO, di default `yolov8n.pt`;
- esegue il riconoscimento degli oggetti sul video;
- disegna sul frame i riquadri degli oggetti rilevati;
- mostra il conteggio degli oggetti riconosciuti;
- affianca al video un pannello laterale con gli ultimi rilevamenti;
- consente il salvataggio di screenshot;
- tenta la riconnessione in caso di perdita temporanea del flusso.

Comandi da tastiera durante l'esecuzione:

| Tasto | Azione |
|---|---|
| `q` | Chiude il programma |
| `s` | Salva uno screenshot della finestra corrente |

---

## Requisiti generali

### Hardware consigliato

| Componente | Requisito consigliato |
|---|---|
| CPU | Processore multicore recente |
| RAM | Almeno 8 GB, consigliati 12 GB o più |
| Disco | Almeno 10 GB liberi per ambiente, librerie e modelli |
| Rete | Accesso alla stessa rete della IP camera |
| Camera | IP camera con flusso RTSP funzionante |

### Software richiesto

| Sistema | Requisiti |
|---|---|
| Linux | Ubuntu, Xubuntu, Debian o distribuzione compatibile con `apt` |
| Windows | Windows 10 o Windows 11 |
| Python | Python 3 recente |
| Rete | URL RTSP già verificato |

---

## Utilizzo su Linux / VM Linux

La cartella di riferimento è:

```text
yolo_lab_linux/
```

### 1. Entrare nella cartella Linux

```bash
cd yolo_lab_linux
```

### 2. Rendere eseguibile lo script di setup

```bash
chmod +x setup_vm_opencv_lab_v2.sh
```

### 3. Eseguire il setup

```bash
./setup_vm_opencv_lab_v2.sh
```

Lo script installa le dipendenze di sistema, crea l'ambiente virtuale Python `venv`, installa le librerie presenti in `requirements.txt` ed esegue alcuni test finali sulle librerie principali.

Per saltare l'aggiornamento completo dei pacchetti di sistema:

```bash
./setup_vm_opencv_lab_v2.sh --skip-upgrade
```

L'opzione `--advanced` è mantenuta solo per compatibilità con vecchie istruzioni:

```bash
./setup_vm_opencv_lab_v2.sh --advanced
```

### 4. Avviare il programma

Dopo il setup, è possibile eseguire direttamente:

```bash
source ./attiva_ambiente.sh
python rtsp_yolo_viewer_v2.py
```

In alternativa, se si lavora sulla Scrivania della VM, è disponibile lo script:

```bash
chmod +x avvia_yolo.sh
./avvia_yolo.sh
```

Lo script `avvia_yolo.sh` cerca il file Python principale, propone gli ambienti virtuali disponibili e avvia il programma.

---

## Utilizzo su Windows

La cartella di riferimento è:

```text
yolo_lab_win/
```

### 1. Aprire PowerShell nella cartella Windows

Entrare nella cartella:

```powershell
cd yolo_lab_win
```

### 2. Eseguire il setup PowerShell

```powershell
powershell -ExecutionPolicy Bypass -File .\setup_windows_opencv_lab_v3.ps1
```

Lo script crea l'ambiente virtuale `.venv_yolo_windows`, installa le dipendenze presenti in `requirements.txt`, genera file di log e mostra l'avanzamento dell'installazione pacchetto per pacchetto.

Se l'aggiornamento di pip crea problemi:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup_windows_opencv_lab_v3.ps1 -SkipPipUpgrade
```

Per proseguire anche se una singola dipendenza genera errore:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup_windows_opencv_lab_v3.ps1 -ContinueOnPackageError
```

### 3. Avviare il programma su Windows

Metodo PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\run_yolo_windows.ps1
```

Metodo semplificato tramite file batch:

```bat
run_yolo_windows.bat
```

Il file batch richiama automaticamente lo script PowerShell di avvio.

---

## Configurazione dell'URL RTSP

Nel file `rtsp_yolo_viewer_v2.py` è presente un URL RTSP di esempio:

```python
DEFAULT_RTSP_URL = "rtsp://USERNAME:PASSWORD@192.168.1.37:554/avstream/channel=1/stream=0.sdp"
```

Prima di usare il programma, modificare questo valore inserendo l'URL corretto della propria IP camera.

Esempio generico:

```text
rtsp://utente:password@indirizzo_ip:porta/percorso_stream
```

È anche possibile passare l'URL da riga di comando:

```bash
python rtsp_yolo_viewer_v2.py --url "rtsp://utente:password@192.168.1.37:554/percorso"
```

Su Windows:

```powershell
python .\rtsp_yolo_viewer_v2.py --url "rtsp://utente:password@192.168.1.37:554/percorso"
```

---

## Parametri principali dello script Python

```bash
python rtsp_yolo_viewer_v2.py --url "URL_RTSP" --model yolov8n.pt --conf 0.40 --reconnect-delay 3
```

| Parametro | Significato | Valore predefinito |
|---|---|---|
| `--url` | URL RTSP della camera | valore impostato in `DEFAULT_RTSP_URL` |
| `--model` | Modello YOLO da usare | `yolov8n.pt` |
| `--conf` | Soglia minima di confidenza | `0.40` |
| `--reconnect-delay` | Secondi prima di tentare la riconnessione | `3` |

---

## Dipendenze principali

### Linux

Il file `yolo_lab_linux/requirements.txt` contiene un ambiente più completo, utile anche per attività didattiche estese, notebook e analisi dati.

Dipendenze principali:

- `opencv-python`
- `opencv-contrib-python`
- `ultralytics`
- `torch`
- `torchvision`
- `numpy`
- `pandas`
- `matplotlib`
- `jupyter`
- `notebook`

### Windows

Il file `yolo_lab_win/requirements.txt` contiene un ambiente più essenziale:

- `opencv-python`
- `ultralytics`
- `numpy`
- `pillow`
- `requests`

Nota importante: su Windows viene usato `opencv-python` e non `opencv-python-headless`, perché la versione headless non supporta correttamente le finestre grafiche di OpenCV come `cv2.namedWindow()` e `cv2.imshow()`.

---

## Problemi frequenti

### Errore OpenCV con `cv2.namedWindow()` o `cv2.imshow()`

Possibile causa:

- è installata una versione headless di OpenCV;
- l'ambiente grafico non è disponibile;
- il programma viene eseguito in un contesto senza supporto alle finestre.

Soluzioni consigliate:

```bash
pip uninstall opencv-python-headless
pip install opencv-python
```

Su Linux verificare inoltre che siano installate le librerie grafiche richieste dallo script di setup.

---

### Il flusso RTSP non si apre

Verificare:

- che la camera sia accesa;
- che il PC sia nella stessa rete della camera;
- che indirizzo IP, porta, utente e password siano corretti;
- che il percorso RTSP sia quello corretto per il modello di camera utilizzato;
- che lo stream funzioni con VLC prima di usarlo in Python.

Test consigliato con VLC:

```text
Media -> Apri flusso di rete -> inserire URL RTSP
```

---

### YOLO scarica il modello al primo avvio

Il modello `yolov8n.pt` può essere scaricato automaticamente al primo avvio. Per questo motivo, al primo utilizzo può essere necessaria una connessione Internet.

---

## Sicurezza e privacy

Non pubblicare mai nella repository:

- password reali delle IP camera;
- indirizzi IP pubblici sensibili;
- screenshot contenenti persone riconoscibili senza autorizzazione;
- video o flussi di sorveglianza privati;
- file di log contenenti credenziali o informazioni personali.

Per pubblicare esempi, usare sempre valori fittizi:

```text
rtsp://USERNAME:PASSWORD@192.168.1.37:554/percorso_stream
```

---

## File da non pubblicare

Si consiglia di usare un file `.gitignore` simile al seguente:

```gitignore
# Ambienti virtuali
venv/
.venv/
.venv_yolo_windows/

# Cache Python
__pycache__/
*.pyc
*.pyo
*.pyd

# Log
*.log
setup_vm_opencv_lab.log
setup_windows_opencv_lab.log
setup_windows_opencv_lab_pip.log

# Screenshot generati dal programma
screenshot_*.jpg
screenshot_*.png

# Modelli YOLO scaricati localmente
*.pt
*.onnx

# File temporanei di sistema
.DS_Store
Thumbs.db

# Configurazioni locali non pubbliche
.env
config.local.*
```

---

## Licenza

Il progetto è distribuito con licenza Apache 2.0.

---

## Destinazione didattica

Questo laboratorio può essere utilizzato per introdurre gli studenti a:

- visione artificiale;
- streaming video su rete IP;
- uso pratico di OpenCV;
- riconoscimento oggetti con YOLO;
- gestione di ambienti virtuali Python;
- differenze operative tra ambiente Linux e Windows;
- analisi di errori reali in un progetto software.

---

## Avvertenza

Il progetto ha finalità didattiche. La classificazione di sicurezza mostrata nel pannello laterale è semplificata e non deve essere considerata un sistema professionale di videosorveglianza, sicurezza o allarme.
