# OpenCV YOLO RTSP Lab

Laboratorio didattico per configurare un ambiente Python ed eseguire il riconoscimento oggetti in tempo reale su flussi video RTSP, utilizzando OpenCV e Ultralytics YOLO.

Il progetto è pensato per attività di laboratorio scolastico su:

- acquisizione video da IP camera tramite protocollo RTSP;
- uso di OpenCV per visualizzare ed elaborare immagini;
- uso di YOLO per il riconoscimento automatico degli oggetti;
- preparazione guidata dell'ambiente Python su Linux e Windows;
- esecuzione semplificata tramite script di setup e script di avvio;
- confronto tra una configurazione Windows completa e una configurazione Windows leggera dedicata al solo uso RTSP.

---

## Obiettivo didattico

Il repository consente agli studenti di sperimentare un flusso completo di visione artificiale:

1. collegamento a una sorgente video RTSP;
2. apertura dello stream con OpenCV;
3. caricamento di un modello YOLO;
4. riconoscimento degli oggetti presenti nel video;
5. visualizzazione del risultato con riquadri, etichette e informazioni laterali;
6. gestione pratica di ambienti virtuali Python, dipendenze e script di automazione.

Il progetto non ha l'obiettivo di essere un sistema di videosorveglianza professionale, ma un laboratorio didattico per comprendere il funzionamento di una pipeline base di computer vision.

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
├── yolo_lab_win/
│   ├── requirements.txt
│   ├── rtsp_yolo_viewer_v2.py
│   ├── run_yolo_windows.bat
│   ├── run_yolo_windows.ps1
│   ├── setup_windows_opencv_lab_v3.bat
│   └── setup_windows_opencv_lab_v3.ps1
│
└── yolo_lab_win_light_rtsp/
    └── versione Windows leggera dedicata all'uso RTSP
```

> Nota: la cartella `yolo_lab_win_light_rtsp` è pensata come variante più essenziale per Windows, utile quando si vuole ridurre il numero di dipendenze e concentrarsi sull'apertura del flusso RTSP e sull'esecuzione del programma.

---

## Versioni disponibili

| Cartella | Sistema | Scopo |
|---|---|---|
| `yolo_lab_linux` | Linux / VM Linux | Ambiente completo per laboratorio su Ubuntu, Xubuntu o Debian |
| `yolo_lab_win` | Windows | Ambiente Windows completo con setup PowerShell, log e script batch |
| `yolo_lab_win_light_rtsp` | Windows | Variante leggera dedicata soprattutto al test e all'uso di flussi RTSP |

---

## Funzionamento generale

Il programma principale della versione completa è:

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
| RAM | Almeno 8 GB, consigliati 12 GB o più per la versione completa |
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

Lo script:

- installa le dipendenze di sistema;
- crea l'ambiente virtuale Python `venv`;
- installa le librerie presenti in `requirements.txt`;
- esegue alcuni test finali sulle librerie principali;
- crea lo script rapido `attiva_ambiente.sh`.

Per saltare l'aggiornamento completo dei pacchetti di sistema:

```bash
./setup_vm_opencv_lab_v2.sh --skip-upgrade
```

L'opzione `--advanced` è mantenuta solo per compatibilità con vecchie istruzioni:

```bash
./setup_vm_opencv_lab_v2.sh --advanced
```

### 4. Avviare il programma su Linux

Dopo il setup:

```bash
source ./attiva_ambiente.sh
python rtsp_yolo_viewer_v2.py
```

In alternativa, se si lavora sulla Scrivania della VM, è disponibile:

```bash
chmod +x avvia_yolo.sh
./avvia_yolo.sh
```

Lo script `avvia_yolo.sh` cerca il file Python principale, propone gli ambienti virtuali disponibili e avvia il programma.

---

## Utilizzo su Windows - versione completa

La cartella di riferimento è:

```text
yolo_lab_win/
```

Questa versione è indicata quando si vuole predisporre un ambiente Windows più completo, con setup dettagliato, log, timeout e installazione controllata delle dipendenze.

### 1. Entrare nella cartella Windows

```powershell
cd yolo_lab_win
```

### 2. Eseguire il setup tramite file batch

Metodo consigliato per un uso semplice:

```bat
setup_windows_opencv_lab_v3.bat
```

Il file batch avvia automaticamente lo script PowerShell di setup.

### 3. Eseguire il setup direttamente da PowerShell

Metodo alternativo:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup_windows_opencv_lab_v3.ps1
```

Se l'aggiornamento di pip crea problemi:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup_windows_opencv_lab_v3.ps1 -SkipPipUpgrade
```

Per proseguire anche se una singola dipendenza genera errore:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup_windows_opencv_lab_v3.ps1 -ContinueOnPackageError
```

Lo script PowerShell:

- crea l'ambiente virtuale `.venv_yolo_windows`;
- installa le dipendenze presenti in `requirements.txt`;
- mostra l'avanzamento pacchetto per pacchetto;
- genera file di log;
- usa timeout per ridurre il rischio di blocchi indefiniti durante l'installazione.

### 4. Avviare il programma su Windows

Metodo semplificato:

```bat
run_yolo_windows.bat
```

Metodo PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\run_yolo_windows.ps1
```

Lo script di avvio:

- individua gli ambienti virtuali disponibili nella cartella;
- permette di scegliere il venv da usare;
- verifica la presenza del programma Python principale;
- avvia `rtsp_yolo_viewer_v2.py`.

---

## Utilizzo su Windows - versione leggera RTSP

La cartella di riferimento è:

```text
yolo_lab_win_light_rtsp/
```

Questa variante è pensata per un uso più leggero e mirato, soprattutto quando l'obiettivo principale è:

- verificare rapidamente il funzionamento di un flusso RTSP;
- ridurre il numero di pacchetti installati;
- evitare un setup troppo pesante su computer scolastici o macchine con risorse limitate;
- semplificare l'esecuzione in laboratorio.

### Quando usare la versione leggera

| Situazione | Versione consigliata |
|---|---|
| Primo test di una IP camera RTSP | `yolo_lab_win_light_rtsp` |
| Computer Windows poco potente | `yolo_lab_win_light_rtsp` |
| Installazione rapida per sola visualizzazione RTSP | `yolo_lab_win_light_rtsp` |
| Laboratorio completo con YOLO e dipendenze più ampie | `yolo_lab_win` |
| VM Linux preparata per attività didattiche estese | `yolo_lab_linux` |

### Procedura generale

Entrare nella cartella:

```powershell
cd yolo_lab_win_light_rtsp
```

Poi seguire gli script presenti nella cartella, ad esempio eventuali file:

```text
setup_*.bat
setup_*.ps1
run_*.bat
run_*.ps1
```

La logica consigliata è:

1. eseguire prima lo script di setup;
2. attendere la creazione dell'ambiente virtuale;
3. avviare lo script di esecuzione;
4. verificare l'apertura del flusso RTSP.

> Nota operativa: se nella cartella leggera sono presenti nomi di file diversi, usare i nomi effettivi presenti nella repository. La sezione è stata predisposta per documentare la variante `yolo_lab_win_light_rtsp` senza confonderla con la versione Windows completa.

---

## Configurazione dell'URL RTSP

Nel file `rtsp_yolo_viewer_v2.py` della versione completa è presente un URL RTSP di esempio:

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

### Windows completo

Il file `yolo_lab_win/requirements.txt` contiene un ambiente più essenziale rispetto a Linux, ma sufficiente per eseguire il laboratorio YOLO su Windows:

- `opencv-python`
- `ultralytics`
- `numpy`
- `pillow`
- `requests`

Nota importante: su Windows viene usato `opencv-python` e non `opencv-python-headless`, perché la versione headless non supporta correttamente le finestre grafiche di OpenCV come `cv2.namedWindow()` e `cv2.imshow()`.

### Windows leggero RTSP

La variante `yolo_lab_win_light_rtsp` dovrebbe mantenere solo le dipendenze realmente necessarie per il test e l'uso del flusso RTSP.

In generale, per una versione leggera RTSP sono sufficienti:

- `opencv-python`
- `numpy`

Se la variante leggera include anche riconoscimento YOLO, allora sono necessari anche:

- `ultralytics`
- eventuali dipendenze installate automaticamente da Ultralytics, come PyTorch.

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

Possibili cause:

- URL RTSP errato;
- username o password non corretti;
- IP camera non raggiungibile dalla rete;
- firewall o rete scolastica che bloccano la comunicazione;
- percorso RTSP diverso da quello indicato nell'esempio.

Controlli consigliati:

```bash
ping indirizzo_ip_camera
```

Verificare inoltre lo stream con VLC:

```text
Media -> Apri flusso di rete -> inserire URL RTSP
```

Se lo stream non funziona in VLC, il problema non dipende dal codice Python.

---

### L'installazione di PyTorch o Ultralytics è lenta

È normale: alcune dipendenze possono essere grandi e richiedere tempo.

Nella versione Windows completa lo script PowerShell mostra il pacchetto in corso, il tempo trascorso e genera log per capire se l'installazione è realmente bloccata o solo lenta.

Per computer con poche risorse, usare prima la variante:

```text
yolo_lab_win_light_rtsp/
```

---

### Il modello YOLO viene scaricato al primo avvio

Il modello predefinito:

```text
yolov8n.pt
```

può essere scaricato automaticamente al primo utilizzo da Ultralytics.

Il primo avvio può quindi richiedere più tempo.

---

## Sicurezza e privacy

Prima di pubblicare modifiche o screenshot:

- non inserire credenziali reali nel codice;
- non pubblicare URL RTSP contenenti username e password reali;
- non caricare screenshot con dati sensibili;
- non pubblicare indirizzi IP privati se collegati a contesti riconoscibili;
- usare sempre valori di esempio nei file pubblici.

Esempio sicuro:

```text
rtsp://USERNAME:PASSWORD@192.168.1.37:554/percorso_stream
```

---

## File da non pubblicare

È consigliabile aggiungere o mantenere un file `.gitignore` con esclusioni simili:

```gitignore
# Ambienti virtuali
venv/
.venv/
.venv_yolo_windows/
env/

# Cache Python
__pycache__/
*.pyc
*.pyo
*.pyd

# Log
*.log

# Screenshot e immagini generate
screenshot_*.jpg
screenshot_*.png

# Modelli YOLO scaricati automaticamente
*.pt

# File temporanei
pip_tmp/
tmp/
temp/

# File specifici di sistema
.DS_Store
Thumbs.db
desktop.ini
```

---

## Suggerimento per il flusso di lavoro didattico

Una possibile sequenza per gli studenti:

| Fase | Attività |
|---|---|
| 1 | Verificare che la IP camera sia raggiungibile |
| 2 | Testare lo stream RTSP con VLC |
| 3 | Preparare l'ambiente con lo script di setup |
| 4 | Avviare il programma Python |
| 5 | Osservare il comportamento di OpenCV |
| 6 | Analizzare il ruolo di YOLO nel riconoscimento oggetti |
| 7 | Modificare soglia di confidenza e modello |
| 8 | Discutere limiti, falsi positivi e prestazioni |

---

## Licenza

Il progetto è distribuito con licenza Apache 2.0.

Consultare il file:

```text
LICENSE
```

per i dettagli completi.

---

## Autore

Repository didattica realizzata da Giovanni Vergari per attività di laboratorio su OpenCV, YOLO e flussi RTSP.
