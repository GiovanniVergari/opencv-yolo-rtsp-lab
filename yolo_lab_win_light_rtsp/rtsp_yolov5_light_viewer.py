# ==================================================================================================
# rtsp_yolov5_light_viewer.py
# --------------------------------------------------------------------------------------------------
# Viewer leggero per telecamera IP / RTSP con YOLOv5n ONNX tramite OpenCV DNN.
#
# Versione v2:
#   - mantiene RTSP funzionante in stile repo;
#   - ripristina bounding box visibili;
#   - ripristina registro dei rilevamenti nella finestra principale;
#   - aggiunge log CSV opzionale;
#   - rende più robusto il parsing dell'output ONNX.
# ==================================================================================================

import rtsp_support

rtsp_support.configure_ffmpeg_environment()

import csv
import os
import time
from datetime import datetime

import cv2
import numpy as np

import config_camera as cfg


COCO_CLASSES = [
    "person", "bicycle", "car", "motorcycle", "airplane", "bus", "train", "truck",
    "boat", "traffic light", "fire hydrant", "stop sign", "parking meter", "bench",
    "bird", "cat", "dog", "horse", "sheep", "cow", "elephant", "bear", "zebra",
    "giraffe", "backpack", "umbrella", "handbag", "tie", "suitcase", "frisbee",
    "skis", "snowboard", "sports ball", "kite", "baseball bat", "baseball glove",
    "skateboard", "surfboard", "tennis racket", "bottle", "wine glass", "cup",
    "fork", "knife", "spoon", "bowl", "banana", "apple", "sandwich", "orange",
    "broccoli", "carrot", "hot dog", "pizza", "donut", "cake", "chair", "couch",
    "potted plant", "bed", "dining table", "toilet", "tv", "laptop", "mouse",
    "remote", "keyboard", "cell phone", "microwave", "oven", "toaster", "sink",
    "refrigerator", "book", "clock", "vase", "scissors", "teddy bear",
    "hair drier", "toothbrush"
]


# ==================================================================================================
# LOG BASE
# ==================================================================================================

def log_info(message):
    """Stampa un messaggio informativo."""

    print("[INFO]", message)


def log_warn(message):
    """Stampa un messaggio di avviso."""

    print("[WARN]", message)


def log_error(message):
    """Stampa un messaggio di errore."""

    print("[ERR ]", message)


# ==================================================================================================
# STATO REGISTRO RILEVAMENTI
# ==================================================================================================

detection_log_rows = []
last_csv_log_time = 0.0
total_detection_events = 0


# ==================================================================================================
# INIZIALIZZAZIONE
# ==================================================================================================

def print_header():
    """Stampa la configurazione principale."""

    print("")
    print("==================================================================================================")
    print(" YOLOv5n Light Viewer - RTSP Repo Style v2")
    print("==================================================================================================")
    print("")
    print("[INFO] Modalità video:", cfg.VIDEO_MODE)
    print("[INFO] Modello:", cfg.MODEL_PATH)
    print("[INFO] Input YOLO:", str(cfg.INPUT_WIDTH) + "x" + str(cfg.INPUT_HEIGHT))
    print("[INFO] Frame skip:", cfg.DETECT_EVERY_N_FRAMES)
    print("[INFO] Soglia confidenza:", cfg.CONFIDENCE_THRESHOLD)
    print("[INFO] Pannello registro:", cfg.SHOW_DETECTION_PANEL)

    if cfg.VIDEO_MODE == "rtsp":
        print("[INFO] URL RTSP candidati:")

        for url in cfg.get_rtsp_url_candidates():
            print("       ", url)

    print("")


def check_model_file():
    """Verifica la presenza del modello."""

    if os.path.exists(cfg.MODEL_PATH):
        return True

    log_error("Modello ONNX non trovato: " + cfg.MODEL_PATH)
    print("")
    print("Soluzione:")
    print("  1. Eseguire setup_windows_yolov5_light.bat")
    print("  2. Oppure copiare yolov5n.onnx nella cartella models")
    print("")

    return False


def load_network():
    """Carica la rete YOLOv5n ONNX."""

    log_info("Caricamento modello ONNX...")

    net = cv2.dnn.readNetFromONNX(cfg.MODEL_PATH)
    net.setPreferableBackend(cv2.dnn.DNN_BACKEND_OPENCV)
    net.setPreferableTarget(cv2.dnn.DNN_TARGET_CPU)

    try:
        output_names = net.getUnconnectedOutLayersNames()
        log_info("Output layer: " + str(output_names))
    except Exception:
        log_warn("Impossibile leggere i nomi degli output layer.")

    log_info("Modello caricato correttamente.")

    return net


# ==================================================================================================
# PREPROCESSING
# ==================================================================================================

def letterbox(frame, target_width, target_height):
    """Ridimensiona mantenendo proporzioni e aggiungendo bordi."""

    original_height, original_width = frame.shape[:2]

    scale_width = target_width / float(original_width)
    scale_height = target_height / float(original_height)

    scale = scale_width

    if scale_height < scale_width:
        scale = scale_height

    new_width = int(round(original_width * scale))
    new_height = int(round(original_height * scale))

    resized = cv2.resize(frame, (new_width, new_height), interpolation=cv2.INTER_LINEAR)

    pad_width = target_width - new_width
    pad_height = target_height - new_height

    pad_left = int(round(pad_width / 2.0 - 0.1))
    pad_right = int(round(pad_width / 2.0 + 0.1))
    pad_top = int(round(pad_height / 2.0 - 0.1))
    pad_bottom = int(round(pad_height / 2.0 + 0.1))

    padded = cv2.copyMakeBorder(
        resized,
        pad_top,
        pad_bottom,
        pad_left,
        pad_right,
        cv2.BORDER_CONSTANT,
        value=(114, 114, 114)
    )

    metadata = {
        "scale": scale,
        "pad_left": pad_left,
        "pad_top": pad_top,
        "original_width": original_width,
        "original_height": original_height
    }

    return padded, metadata


def is_class_enabled(class_name):
    """Verifica se una classe è abilitata."""

    if len(cfg.ENABLED_CLASSES) == 0:
        return True

    if class_name in cfg.ENABLED_CLASSES:
        return True

    return False


# ==================================================================================================
# PARSING OUTPUT ONNX
# ==================================================================================================

def normalize_network_output(outputs):
    """
    Normalizza l'output della rete.

    Gestisce diversi casi:
      - array [1, N, 85] tipico YOLOv5;
      - array [N, 85];
      - array [1, 85, N] da trasporre;
      - array [N, 6] con NMS già incluso.
    """

    predictions = outputs

    if isinstance(outputs, tuple):
        predictions = outputs[0]

    if isinstance(outputs, list):
        predictions = outputs[0]

    predictions = np.array(predictions)

    if predictions.ndim == 3:
        predictions = predictions[0]

    if predictions.ndim != 2:
        return None

    rows = predictions.shape[0]
    columns = predictions.shape[1]

    if rows < columns:
        if rows == 6 or rows == 84 or rows == 85:
            predictions = predictions.transpose()

    return predictions


def parse_yolov5_predictions(predictions, metadata):
    """Interpreta output YOLOv5 classico: cx, cy, w, h, objectness, class_scores."""

    boxes = []
    confidences = []
    class_ids = []

    for detection in predictions:
        if len(detection) < 85:
            continue

        objectness = float(detection[4])

        if objectness < cfg.CONFIDENCE_THRESHOLD:
            continue

        class_scores = detection[5:]
        class_id = int(np.argmax(class_scores))
        class_score = float(class_scores[class_id])
        confidence = objectness * class_score

        if confidence < cfg.CONFIDENCE_THRESHOLD:
            continue

        if class_id < 0 or class_id >= len(COCO_CLASSES):
            continue

        class_name = COCO_CLASSES[class_id]

        if is_class_enabled(class_name) is False:
            continue

        center_x = float(detection[0])
        center_y = float(detection[1])
        width = float(detection[2])
        height = float(detection[3])

        x = center_x - width / 2.0
        y = center_y - height / 2.0

        x = (x - metadata["pad_left"]) / metadata["scale"]
        y = (y - metadata["pad_top"]) / metadata["scale"]
        width = width / metadata["scale"]
        height = height / metadata["scale"]

        x = int(round(x))
        y = int(round(y))
        width = int(round(width))
        height = int(round(height))

        clipped_box = clip_box(x, y, width, height, metadata)

        if clipped_box is None:
            continue

        boxes.append(clipped_box)
        confidences.append(float(confidence))
        class_ids.append(class_id)

    return boxes, confidences, class_ids


def parse_nms_predictions(predictions, metadata):
    """
    Interpreta output già filtrato nel formato approssimativo:
      x1, y1, x2, y2, confidence, class_id
    """

    boxes = []
    confidences = []
    class_ids = []

    for detection in predictions:
        if len(detection) < 6:
            continue

        confidence = float(detection[4])

        if confidence < cfg.CONFIDENCE_THRESHOLD:
            continue

        class_id = int(detection[5])

        if class_id < 0 or class_id >= len(COCO_CLASSES):
            continue

        class_name = COCO_CLASSES[class_id]

        if is_class_enabled(class_name) is False:
            continue

        x1 = float(detection[0])
        y1 = float(detection[1])
        x2 = float(detection[2])
        y2 = float(detection[3])

        x = (x1 - metadata["pad_left"]) / metadata["scale"]
        y = (y1 - metadata["pad_top"]) / metadata["scale"]
        width = (x2 - x1) / metadata["scale"]
        height = (y2 - y1) / metadata["scale"]

        clipped_box = clip_box(
            int(round(x)),
            int(round(y)),
            int(round(width)),
            int(round(height)),
            metadata
        )

        if clipped_box is None:
            continue

        boxes.append(clipped_box)
        confidences.append(float(confidence))
        class_ids.append(class_id)

    return boxes, confidences, class_ids


def clip_box(x, y, width, height, metadata):
    """Limita una bounding box ai confini del frame originale."""

    if x < 0:
        width = width + x
        x = 0

    if y < 0:
        height = height + y
        y = 0

    if x + width > metadata["original_width"]:
        width = metadata["original_width"] - x

    if y + height > metadata["original_height"]:
        height = metadata["original_height"] - y

    if width <= 0:
        return None

    if height <= 0:
        return None

    return [x, y, width, height]


def run_detection(net, frame):
    """Esegue rilevamento YOLOv5n ONNX."""

    input_image, metadata = letterbox(frame, cfg.INPUT_WIDTH, cfg.INPUT_HEIGHT)

    blob = cv2.dnn.blobFromImage(
        input_image,
        scalefactor=1.0 / 255.0,
        size=(cfg.INPUT_WIDTH, cfg.INPUT_HEIGHT),
        mean=(0, 0, 0),
        swapRB=True,
        crop=False
    )

    net.setInput(blob)
    outputs = net.forward()

    predictions = normalize_network_output(outputs)

    if predictions is None:
        log_warn("Output del modello non riconosciuto.")
        return []

    if predictions.shape[1] >= 85:
        boxes, confidences, class_ids = parse_yolov5_predictions(predictions, metadata)
    elif predictions.shape[1] == 6:
        boxes, confidences, class_ids = parse_nms_predictions(predictions, metadata)
    else:
        log_warn("Formato output non gestito: " + str(predictions.shape))
        return []

    final_detections = apply_nms(boxes, confidences, class_ids)

    return final_detections


def apply_nms(boxes, confidences, class_ids):
    """Applica Non-Maximum Suppression e restituisce i rilevamenti finali."""

    final_detections = []

    if len(boxes) == 0:
        return final_detections

    indexes = cv2.dnn.NMSBoxes(
        boxes,
        confidences,
        cfg.CONFIDENCE_THRESHOLD,
        cfg.NMS_THRESHOLD
    )

    if len(indexes) > 0:
        for index in indexes.flatten():
            final_detections.append(
                {
                    "box": boxes[index],
                    "confidence": confidences[index],
                    "class_id": class_ids[index],
                    "class_name": COCO_CLASSES[class_ids[index]]
                }
            )

    return final_detections


# ==================================================================================================
# REGISTRO RILEVAMENTI
# ==================================================================================================

def ensure_csv_log_exists():
    """Crea il file CSV con intestazione, se necessario."""

    if cfg.ENABLE_CSV_DETECTION_LOG is False:
        return

    if os.path.exists(cfg.DETECTION_CSV_FILE):
        return

    with open(cfg.DETECTION_CSV_FILE, "w", newline="", encoding="utf-8") as csv_file:
        writer = csv.writer(csv_file, delimiter=";")
        writer.writerow(
            [
                "timestamp",
                "class_name",
                "confidence",
                "x",
                "y",
                "width",
                "height"
            ]
        )


def update_detection_log(detections):
    """Aggiorna il registro in memoria e, se abilitato, il CSV."""

    global detection_log_rows
    global last_csv_log_time
    global total_detection_events

    if len(detections) == 0:
        return

    now = time.time()
    timestamp = datetime.now().strftime("%H:%M:%S")

    for detection in detections:
        x, y, width, height = detection["box"]

        total_detection_events = total_detection_events + 1

        row = {
            "time": timestamp,
            "class_name": detection["class_name"],
            "confidence": detection["confidence"],
            "box": [x, y, width, height],
            "event_id": total_detection_events
        }

        detection_log_rows.insert(0, row)

    if len(detection_log_rows) > cfg.DETECTION_LOG_MAX_ROWS:
        detection_log_rows = detection_log_rows[:cfg.DETECTION_LOG_MAX_ROWS]

    if cfg.ENABLE_CSV_DETECTION_LOG is True:
        elapsed = now - last_csv_log_time

        if elapsed >= cfg.CSV_LOG_MIN_INTERVAL_SECONDS:
            append_detections_to_csv(detections)
            last_csv_log_time = now


def append_detections_to_csv(detections):
    """Aggiunge rilevamenti al file CSV."""

    ensure_csv_log_exists()

    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    with open(cfg.DETECTION_CSV_FILE, "a", newline="", encoding="utf-8") as csv_file:
        writer = csv.writer(csv_file, delimiter=";")

        for detection in detections:
            x, y, width, height = detection["box"]

            writer.writerow(
                [
                    timestamp,
                    detection["class_name"],
                    round(detection["confidence"], 4),
                    x,
                    y,
                    width,
                    height
                ]
            )


# ==================================================================================================
# DISEGNO E INTERFACCIA
# ==================================================================================================

def resize_for_display(frame):
    """Ridimensiona solo per la finestra."""

    if cfg.DISPLAY_MAX_WIDTH <= 0:
        return frame

    height, width = frame.shape[:2]

    if width <= cfg.DISPLAY_MAX_WIDTH:
        return frame

    scale = cfg.DISPLAY_MAX_WIDTH / float(width)
    new_width = int(width * scale)
    new_height = int(height * scale)

    return cv2.resize(frame, (new_width, new_height), interpolation=cv2.INTER_AREA)


def draw_detections(frame, detections):
    """Disegna bounding box e label."""

    for detection in detections:
        x, y, width, height = detection["box"]
        label = detection["class_name"] + " " + str(round(detection["confidence"] * 100.0, 1)) + "%"

        cv2.rectangle(
            frame,
            (x, y),
            (x + width, y + height),
            (0, 255, 0),
            cfg.BOX_THICKNESS
        )

        text_y = y - 8

        if text_y < 20:
            text_y = y + 20

        cv2.rectangle(
            frame,
            (x, text_y - 18),
            (x + 220, text_y + 6),
            (0, 255, 0),
            -1
        )

        cv2.putText(
            frame,
            label,
            (x + 4, text_y),
            cv2.FONT_HERSHEY_SIMPLEX,
            cfg.LABEL_FONT_SCALE,
            (0, 0, 0),
            2,
            cv2.LINE_AA
        )


def draw_status(frame, fps, detection_enabled, frame_skip, detections_count, stream_status, selected_source):
    """Disegna informazioni diagnostiche sopra il video."""

    lines = []
    lines.append("FPS: " + str(round(fps, 1)))
    lines.append("Stream: " + stream_status)
    lines.append("Detection: " + str(detection_enabled))
    lines.append("Frame skip: " + str(frame_skip))
    lines.append("Objects now: " + str(detections_count))
    lines.append("q/ESC esci | d toggle | +/- frame skip | s screenshot")

    y = 25

    for line in lines:
        cv2.putText(frame, line, (10, y), cv2.FONT_HERSHEY_SIMPLEX, 0.55, (255, 255, 255), 2, cv2.LINE_AA)
        cv2.putText(frame, line, (10, y), cv2.FONT_HERSHEY_SIMPLEX, 0.55, (0, 0, 0), 1, cv2.LINE_AA)
        y = y + 24


def build_detection_panel(video_frame, current_detections, selected_source):
    """Aggiunge un pannello laterale con registro dei rilevamenti."""

    if cfg.SHOW_DETECTION_PANEL is False:
        return video_frame

    height, width = video_frame.shape[:2]

    panel = np.zeros((height, cfg.DETECTION_PANEL_WIDTH, 3), dtype=np.uint8)
    panel[:, :] = (35, 35, 35)

    output = np.zeros((height, width + cfg.DETECTION_PANEL_WIDTH, 3), dtype=np.uint8)
    output[:, 0:width] = video_frame
    output[:, width:width + cfg.DETECTION_PANEL_WIDTH] = panel

    x0 = width + 15
    y = 28

    write_panel_text(output, "REGISTRO RILEVAMENTI", x0, y, 0.62, (255, 255, 255), 2)
    y = y + 34

    write_panel_text(output, "Oggetti attuali: " + str(len(current_detections)), x0, y, 0.55, (220, 220, 220), 1)
    y = y + 26

    write_panel_text(output, "Eventi totali: " + str(total_detection_events), x0, y, 0.55, (220, 220, 220), 1)
    y = y + 26

    if cfg.ENABLE_CSV_DETECTION_LOG is True:
        write_panel_text(output, "CSV: " + cfg.DETECTION_CSV_FILE, x0, y, 0.48, (180, 180, 180), 1)
        y = y + 26

    y = y + 8
    cv2.line(output, (width + 10, y), (width + cfg.DETECTION_PANEL_WIDTH - 10, y), (90, 90, 90), 1)
    y = y + 28

    write_panel_text(output, "Ultimi rilevamenti:", x0, y, 0.55, (255, 255, 255), 1)
    y = y + 28

    if len(detection_log_rows) == 0:
        write_panel_text(output, "Nessun oggetto rilevato", x0, y, 0.50, (180, 180, 180), 1)
    else:
        for row in detection_log_rows:
            confidence_percent = round(row["confidence"] * 100.0, 1)
            text = (
                "#"
                + str(row["event_id"])
                + " "
                + row["time"]
                + " "
                + row["class_name"]
                + " "
                + str(confidence_percent)
                + "%"
            )

            write_panel_text(output, text, x0, y, 0.47, (210, 255, 210), 1)
            y = y + 23

    bottom_y = height - 68
    cv2.line(output, (width + 10, bottom_y - 12), (width + cfg.DETECTION_PANEL_WIDTH - 10, bottom_y - 12), (90, 90, 90), 1)

    write_panel_text(output, "Sorgente:", x0, bottom_y, 0.45, (200, 200, 200), 1)
    write_panel_text(output, str(selected_source), x0, bottom_y + 22, 0.38, (180, 180, 180), 1)

    return output


def write_panel_text(frame, text, x, y, scale, color, thickness):
    """Scrive testo sul pannello laterale."""

    cv2.putText(
        frame,
        text,
        (x, y),
        cv2.FONT_HERSHEY_SIMPLEX,
        scale,
        color,
        thickness,
        cv2.LINE_AA
    )


def save_screenshot(frame):
    """Salva uno screenshot."""

    output_dir = "screenshots"

    if os.path.exists(output_dir) is False:
        os.makedirs(output_dir)

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = os.path.join(output_dir, "screenshot_" + timestamp + ".jpg")

    cv2.imwrite(filename, frame)
    log_info("Screenshot salvato: " + filename)


# ==================================================================================================
# PROGRAMMA PRINCIPALE
# ==================================================================================================

def main():
    """Programma principale."""

    print_header()
    ensure_csv_log_exists()

    if check_model_file() is False:
        return

    cap, selected_source, first_frame = rtsp_support.open_first_working_capture(cv2)

    if cap is None:
        log_error("Nessuna sorgente video funzionante.")
        rtsp_support.print_rtsp_help()
        return

    net = load_network()

    cv2.namedWindow(cfg.WINDOW_NAME, cv2.WINDOW_NORMAL)

    frame_counter = 0
    last_time = time.time()
    fps = 0.0
    last_detections = []

    detection_enabled = True
    frame_skip = cfg.DETECT_EVERY_N_FRAMES
    stream_status = "OK"

    log_info("Avvio loop video.")

    while True:
        ret, frame = cap.read()

        if ret is False or frame is None:
            stream_status = "NO FRAME"
            log_warn("Frame non disponibile. Attendo 1 secondo...")
            time.sleep(1)
            continue

        stream_status = "OK"
        frame_counter = frame_counter + 1

        now = time.time()
        delta = now - last_time

        if delta > 0:
            fps = 1.0 / delta

        last_time = now

        if detection_enabled is True:
            if frame_counter % frame_skip == 0:
                try:
                    last_detections = run_detection(net, frame)
                    update_detection_log(last_detections)
                except Exception as error:
                    log_error("Errore durante il rilevamento: " + str(error))
                    last_detections = []

            draw_detections(frame, last_detections)

        display_frame = resize_for_display(frame)
        draw_status(display_frame, fps, detection_enabled, frame_skip, len(last_detections), stream_status, selected_source)
        display_frame = build_detection_panel(display_frame, last_detections, selected_source)

        cv2.imshow(cfg.WINDOW_NAME, display_frame)

        key = cv2.waitKey(1) & 0xFF

        if key == 27 or key == ord("q"):
            break

        if key == ord("d"):
            if detection_enabled is True:
                detection_enabled = False
                log_info("Rilevamento disattivato.")
            else:
                detection_enabled = True
                log_info("Rilevamento attivato.")

        if key == ord("+"):
            frame_skip = frame_skip + 1
            log_info("Frame skip: " + str(frame_skip))

        if key == ord("-"):
            if frame_skip > 1:
                frame_skip = frame_skip - 1

            log_info("Frame skip: " + str(frame_skip))

        if key == ord("s"):
            save_screenshot(display_frame)

    log_info("Chiusura programma.")
    cap.release()
    cv2.destroyAllWindows()


if __name__ == "__main__":
    main()
