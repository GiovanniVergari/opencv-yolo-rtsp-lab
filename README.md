# OpenCV Lab - RTSP YOLO Viewer

Progetto didattico per l'utilizzo di **OpenCV**, **streaming RTSP** e **YOLO / Ultralytics** in ambiente Linux, pensato per attività di laboratorio con macchine virtuali Ubuntu, Xubuntu o Debian.

Il progetto consente di aprire il flusso video di una videocamera IP tramite RTSP, elaborare i frame con un modello YOLO e visualizzare in tempo reale:

- il video annotato con bounding box;
- il conteggio degli oggetti rilevati;
- un pannello laterale con il registro degli eventi;
- un'indicazione semplificata del livello di attenzione associato agli oggetti rilevati.

---

## Obiettivi didattici

Il progetto può essere utilizzato per introdurre o consolidare i seguenti argomenti:

| Area | Contenuti |
|---|---|
| OpenCV | acquisizione video, finestre grafiche, annotazione dei frame |
| Reti | flussi RTSP, videocamere IP, indirizzi IP, porte e protocolli |
| Intelligenza artificiale | object detection, modelli YOLO, soglia di confidenza |
| Python | gestione di librerie esterne, argomenti da riga di comando, strutture dati |
| Sistemi Linux | ambiente virtuale Python, installazione pacchetti, script Bash |

---

## Struttura del repository

```text
.
├── README.md
├── requirements.txt
├── rtsp_yolo_viewer_v2.py
└── setup_vm_opencv_lab_v2.sh
```

## File principali

| File | Descrizione |
|---|---|
| `setup_vm_opencv_lab_v2.sh` | Script Bash per preparare una VM Linux, creare il virtual environment e installare le dipendenze. |
| `requirements.txt` | Elenco unico delle librerie Python necessarie al progetto. |
| `rtsp_yolo_viewer_v2.py` | Programma principale per apertura del flusso RTSP, inferenza YOLO e visualizzazione dei risultati. |

---

## Requisiti

### Sistema operativo consigliato

Il progetto è pensato per una macchina virtuale basata su:

- Ubuntu;
- Xubuntu;
- Debian;
- distribuzioni derivate con gestione pacchetti tramite `apt`.

### Requisiti hardware indicativi

| Componente | Indicazione |
|---|---|
| RAM | almeno 4 GB, consigliati 8 GB |
| Spazio libero | almeno 8-10 GB |
| CPU | processore moderno multicore |
| GPU | non obbligatoria; il progetto funziona anche su CPU, ma con prestazioni inferiori |

---

## Installazione rapida

Aprire un terminale nella cartella del progetto ed eseguire:

```bash
chmod +x setup_vm_opencv_lab_v2.sh
./setup_vm_opencv_lab_v2.sh
```

Lo script esegue automaticamente le seguenti operazioni:

1. aggiorna l'indice dei pacchetti;
2. installa le dipendenze di sistema;
3. crea un ambiente virtuale Python nella cartella `venv`;
4. installa le librerie presenti in `requirements.txt`;
5. esegue alcuni test di importazione delle librerie principali;
6. crea lo script `attiva_ambiente.sh`.

---

## Installazione più veloce

Per saltare l'aggiornamento completo dei pacchetti già installati:

```bash
./setup_vm_opencv_lab_v2.sh --skip-upgrade
```

Questa opzione può essere utile in laboratorio per ridurre i tempi di preparazione della VM.

---

## Attivazione dell'ambiente virtuale

Dopo il setup, attivare l'ambiente Python con:

```bash
source ./attiva_ambiente.sh
```

In alternativa:

```bash
source venv/bin/activate
```

Per verificare che l'ambiente sia attivo:

```bash
python --version
```

---

## Esecuzione del programma

Il programma principale è:

```bash
python rtsp_yolo_viewer_v2.py
```

Il file contiene un URL RTSP predefinito modificabile all'inizio del codice:

```python
DEFAULT_RTSP_URL = "rtsp://USERNAME:PASSWORD@192.168.1.37:554/avstream/channel=1/stream=0.sdp"
```

È anche possibile indicare l'URL direttamente da terminale:

```bash
python rtsp_yolo_viewer_v2.py --url "rtsp://utente:password@192.168.1.37:554/avstream/channel=1/stream=0.sdp"
```

---

## Parametri disponibili

| Parametro | Descrizione | Valore predefinito |
|---|---|---|
| `--url` | URL RTSP completo della videocamera IP | valore di `DEFAULT_RTSP_URL` |
| `--model` | modello YOLO da utilizzare | `yolov8n.pt` |
| `--conf` | soglia minima di confidenza | `0.40` |
| `--reconnect-delay` | secondi di attesa prima di tentare una riconnessione | `3` |

Esempio:

```bash
python rtsp_yolo_viewer_v2.py \
  --url "rtsp://utente:password@192.168.1.37:554/avstream/channel=1/stream=0.sdp" \
  --model yolov8n.pt \
  --conf 0.45 \
  --reconnect-delay 5
```

---

## Comandi durante l'esecuzione

| Tasto | Azione |
|---|---|
| `q` | chiude il programma |
| `s` | salva uno screenshot della finestra corrente |

Gli screenshot vengono salvati nella cartella di esecuzione con un nome simile a:

```text
screenshot_20260519_153012.jpg
```

---

## Funzionamento generale

Il programma esegue il seguente ciclo operativo:

1. carica il modello YOLO;
2. apre il flusso RTSP tramite OpenCV e FFmpeg;
3. legge i frame della videocamera;
4. esegue l'inferenza YOLO su ciascun frame;
5. disegna bounding box ed etichette;
6. calcola il conteggio degli oggetti rilevati;
7. aggiorna il pannello laterale degli eventi;
8. mostra il risultato in una singola finestra.

---

## Livelli di sicurezza

Il programma contiene una funzione didattica denominata `get_security_level`, che associa alcune classi di oggetti a un livello di attenzione.

| Oggetto rilevato | Livello |
|---|---|
| `knife`, `scissors` | `ALTA` |
| `car`, `motorcycle`, `bus`, `truck` | `MEDIA` |
| `person` | `ATTENZIONE` |
| altri oggetti | `BASSA` |

Questa logica è volutamente semplice e può essere modificata dagli studenti per realizzare esercitazioni personalizzate.

---

## Dipendenze Python principali

Le principali librerie utilizzate sono:

| Libreria | Utilizzo |
|---|---|
| `opencv-python` | acquisizione e visualizzazione video |
| `opencv-contrib-python` | moduli aggiuntivi di OpenCV |
| `ultralytics` | utilizzo dei modelli YOLO |
| `torch` | backend di calcolo per YOLO |
| `torchvision` | supporto a PyTorch per computer vision |
| `numpy` | gestione dei frame come array |
| `pillow` | gestione immagini |
| `requests` | eventuali estensioni HTTP |
| `imageio-ffmpeg` | supporto video aggiuntivo |

---

## Verifica manuale dell'ambiente

Dopo l'installazione, è possibile verificare rapidamente alcune librerie:

```bash
python -c "import cv2; print(cv2.__version__)"
python -c "from ultralytics import YOLO; print('YOLO OK')"
python -c "import torch; print(torch.__version__)"
```

---

## Verifica del flusso RTSP

Prima di usare YOLO, è consigliabile controllare che il flusso RTSP funzioni.

Con VLC:

```bash
vlc "rtsp://utente:password@192.168.1.37:554/avstream/channel=1/stream=0.sdp"
```

Con FFmpeg / FFprobe:

```bash
ffprobe "rtsp://utente:password@192.168.1.37:554/avstream/channel=1/stream=0.sdp"
```

Se il flusso non si apre in VLC o FFprobe, il problema non dipende dal programma Python ma dalla configurazione della videocamera, dalla rete o dall'URL RTSP.

---

## Problemi comuni

| Problema | Possibile causa | Soluzione |
|---|---|---|
| Il flusso non si apre | URL RTSP errato, credenziali errate, IP non raggiungibile | Verificare con VLC o FFprobe |
| Finestra OpenCV non disponibile | ambiente senza supporto grafico | Usare una VM con desktop grafico oppure installare librerie GTK |
| Inferenza lenta | esecuzione su CPU | usare modello leggero `yolov8n.pt`, ridurre risoluzione o soglia |
| Errore nel download del modello | assenza di connessione Internet | scaricare preventivamente il modello YOLO |
| Disco insufficiente | PyTorch e Ultralytics richiedono spazio | liberare spazio o aumentare il disco della VM |

---

## Indicazioni per la pubblicazione su GitHub

Prima della pubblicazione, si consiglia di controllare i seguenti punti:

- non pubblicare password reali o indirizzi sensibili;
- lasciare nell'URL RTSP valori segnaposto come `USERNAME` e `PASSWORD`;
- non caricare la cartella `venv`;
- non caricare file di log;
- non caricare screenshot non necessari;
- mantenere un solo file `requirements.txt`;
- verificare la coerenza del nome dello script di setup.

---

## `.gitignore` consigliato

Creare un file `.gitignore` con il seguente contenuto:

```gitignore
# Ambiente virtuale Python
venv/
.venv/

# Cache Python
__pycache__/
*.pyc
*.pyo

# Log
*.log

# Screenshot generati dal programma
screenshot_*.jpg
screenshot_*.png

# File temporanei
*.tmp
*.bak

# Configurazioni locali
.env
local_config.py

# Cartelle IDE/editor
.vscode/
.idea/
```

---

## Possibile attività per gli studenti

Una possibile consegna didattica potrebbe essere:

> Modificare il programma affinché riconosca alcune classi di oggetti considerate rilevanti per uno specifico scenario di monitoraggio, personalizzando il livello di attenzione e il pannello eventi.

Esempi di estensione:

- modificare le classi considerate ad alta priorità;
- salvare su file CSV gli eventi rilevati;
- aggiungere un filtro per mostrare solo alcuni oggetti;
- confrontare le prestazioni con modelli YOLO diversi;
- realizzare una breve relazione tecnica sul funzionamento del sistema.

---

## Avvertenza didattica e privacy

Il progetto è pensato per finalità didattiche.  
L'utilizzo di videocamere e sistemi di riconoscimento automatico deve rispettare la normativa vigente, le regole dell'istituto scolastico e la privacy delle persone eventualmente riprese.

---

## Licenza

Aggiungere qui la licenza scelta per il repository.

Esempi comuni:

- MIT License;
- GNU GPLv3;
- Creative Commons per materiali prevalentemente didattici.

---

## Autore

Materiale didattico per laboratorio OpenCV, RTSP e YOLO.
