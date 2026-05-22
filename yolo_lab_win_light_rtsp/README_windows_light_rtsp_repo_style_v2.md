# OpenCV YOLO Lab - Windows Light RTSP Repo Style v2

Questa versione mantiene il collegamento RTSP funzionante e ripristina le funzionalità presenti nella repo:

- bounding box sugli oggetti riconosciuti;
- registro dei rilevamenti nella schermata principale;
- log dei rilevamenti su CSV;
- screenshot;
- frame skip regolabile;
- rilevamento attivabile/disattivabile;
- test RTSP separato;
- fallback tra main stream e substream.

## File principali

| File | Funzione |
|---|---|
| `config_camera.py` | configurazione telecamera, YOLO, registro |
| `rtsp_support.py` | apertura robusta RTSP con FFmpeg |
| `test_rtsp_camera.bat` | test telecamera senza YOLO |
| `rtsp_yolov5_light_viewer.py` | viewer principale con bounding box e registro |
| `run_yolov5_light.bat` | avvio viewer |
| `setup_windows_yolov5_light.bat` | setup ambiente leggero |

## Procedura

```bat
setup_windows_yolov5_light.bat
test_rtsp_camera.bat
run_yolov5_light.bat
```

## Configurazione telecamera

Aprire `config_camera.py`:

```python
CAMERA_IP = "192.168.1.35"
CAMERA_USERNAME = "admin"
CAMERA_PASSWORD = "admin123"
RTSP_MAIN_PATH = "/avstream/channel=1/stream=0.sdp"
RTSP_SUB_PATH = "/avstream/channel=1/stream=1.sdp"
```

## Prestazioni

Per PC poco performanti:

```python
TRY_MAIN_STREAM_FIRST = False
TRY_SUB_STREAM_AS_FALLBACK = True
DETECT_EVERY_N_FRAMES = 6
```

## Registro rilevamenti

Il registro è visibile a destra nella finestra principale.

Il file CSV viene creato automaticamente:

```text
detection_log.csv
```

Per disattivarlo:

```python
ENABLE_CSV_DETECTION_LOG = False
```

## Nota sul modello

Questa versione usa YOLOv5n ONNX con OpenCV DNN.

Rispetto a YOLOv8/Ultralytics è più leggera perché non usa:

- `torch`
- `ultralytics`
