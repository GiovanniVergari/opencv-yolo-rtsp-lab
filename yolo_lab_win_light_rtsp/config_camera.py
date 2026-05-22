# ==================================================================================================
# config_camera.py
# --------------------------------------------------------------------------------------------------
# Configurazione della sorgente video per il laboratorio OpenCV + YOLOv5 Light.
#
# Questa configurazione mantiene l'impostazione RTSP funzionante della repo:
#   - telecamera IP tramite RTSP;
#   - path /avstream/channel=1/stream=0.sdp;
#   - fallback su stream secondario;
#   - apertura con backend FFmpeg;
#   - trasporto RTSP via TCP.
# ==================================================================================================


# ==================================================================================================
# 1. MODALITÀ VIDEO
# ==================================================================================================
#
# Valori possibili:
#   "rtsp"   -> telecamera IP
#   "webcam" -> webcam locale
#   "file"   -> file video locale
# ==================================================================================================

VIDEO_MODE = "rtsp"


# ==================================================================================================
# 2. PARAMETRI TELECAMERA IP
# ==================================================================================================

CAMERA_IP = "192.168.1.35"
CAMERA_PORT = 554
CAMERA_USERNAME = "admin"
CAMERA_PASSWORD = "admin123"

RTSP_MAIN_PATH = "/avstream/channel=1/stream=0.sdp"
RTSP_SUB_PATH = "/avstream/channel=1/stream=1.sdp"

# Se i PC sono poco performanti, impostare TRY_MAIN_STREAM_FIRST = False
# per usare direttamente lo stream secondario.
TRY_MAIN_STREAM_FIRST = True
TRY_SUB_STREAM_AS_FALLBACK = True

# URL manuali aggiuntivi.
RTSP_EXTRA_URLS = [
    # "rtsp://admin:admin123@192.168.1.35:554/cam/realmonitor?channel=1&subtype=0",
    # "rtsp://admin:admin123@192.168.1.35:554/h264Preview_01_main",
]


# ==================================================================================================
# 3. OPZIONI RTSP / FFMPEG
# ==================================================================================================

RTSP_TRANSPORT = "tcp"
FFMPEG_STIMEOUT_MICROSECONDS = 5000000
FFMPEG_MAX_DELAY_MICROSECONDS = 500000

CAPTURE_OPEN_TIMEOUT_MS = 10000
CAPTURE_READ_TIMEOUT_MS = 10000

STREAM_TEST_ATTEMPTS = 30
STREAM_TEST_WAIT_SECONDS = 0.2


# ==================================================================================================
# 4. WEBCAM / FILE VIDEO
# ==================================================================================================

WEBCAM_INDEX = 0
VIDEO_FILE_PATH = "video_test.mp4"


# ==================================================================================================
# 5. MODELLO YOLO LEGGERO
# ==================================================================================================

MODEL_PATH = "models/yolov5n.onnx"

# Nota:
#   Il modello yolov5n.onnx ufficiale è normalmente esportato a 640x640.
#   Per massima compatibilità lascio 640.
#   Se il PC è troppo lento e il modello accetta input dinamico, si può provare 320.
INPUT_WIDTH = 640
INPUT_HEIGHT = 640

# Analizza un frame ogni N.
# Aumentare questo valore riduce il carico.
DETECT_EVERY_N_FRAMES = 5

# Soglie più tolleranti rispetto alla versione precedente.
# Se vengono mostrati troppi falsi positivi, aumentare CONFIDENCE_THRESHOLD.
CONFIDENCE_THRESHOLD = 0.25
NMS_THRESHOLD = 0.45


# ==================================================================================================
# 6. VISUALIZZAZIONE E REGISTRO
# ==================================================================================================

WINDOW_NAME = "YOLOv5n Light - RTSP Camera"
DISPLAY_MAX_WIDTH = 960

# Pannello laterale con registro dei rilevamenti.
SHOW_DETECTION_PANEL = True
DETECTION_PANEL_WIDTH = 420
DETECTION_LOG_MAX_ROWS = 14

# Salvataggio log rilevamenti su CSV.
ENABLE_CSV_DETECTION_LOG = True
DETECTION_CSV_FILE = "detection_log.csv"

# Per evitare log eccessivi, registra su CSV al massimo una volta ogni N secondi.
CSV_LOG_MIN_INTERVAL_SECONDS = 1.0

# Disegno bounding box.
BOX_THICKNESS = 2
LABEL_FONT_SCALE = 0.55

# Lista vuota = tutte le classi.
# Esempio:
#   ENABLED_CLASSES = ["person", "car", "cat", "dog"]
ENABLED_CLASSES = []


# ==================================================================================================
# 7. FUNZIONI DI CONFIGURAZIONE
# ==================================================================================================

def build_rtsp_url(path):
    """Costruisce un URL RTSP completo partendo dal path della telecamera."""

    clean_path = path

    if clean_path.startswith("/") is False:
        clean_path = "/" + clean_path

    return (
        "rtsp://"
        + CAMERA_USERNAME
        + ":"
        + CAMERA_PASSWORD
        + "@"
        + CAMERA_IP
        + ":"
        + str(CAMERA_PORT)
        + clean_path
    )


def get_rtsp_url_candidates():
    """Restituisce la lista ordinata degli URL RTSP da provare."""

    urls = []

    if TRY_MAIN_STREAM_FIRST is True:
        urls.append(build_rtsp_url(RTSP_MAIN_PATH))

    if TRY_SUB_STREAM_AS_FALLBACK is True:
        urls.append(build_rtsp_url(RTSP_SUB_PATH))

    for extra_url in RTSP_EXTRA_URLS:
        if extra_url not in urls:
            urls.append(extra_url)

    return urls


def get_ffmpeg_capture_options():
    """Restituisce la stringa per OPENCV_FFMPEG_CAPTURE_OPTIONS."""

    transport = RTSP_TRANSPORT.strip().lower()

    if transport != "tcp" and transport != "udp":
        transport = "tcp"

    return (
        "rtsp_transport;"
        + transport
        + "|stimeout;"
        + str(FFMPEG_STIMEOUT_MICROSECONDS)
        + "|max_delay;"
        + str(FFMPEG_MAX_DELAY_MICROSECONDS)
    )
