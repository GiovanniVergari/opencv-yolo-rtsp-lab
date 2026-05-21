#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
============================================================
RTSP YOLO Viewer con pannello eventi laterale
============================================================

Scopo:
- Aprire un flusso RTSP
- Visualizzarlo in una finestra
- Eseguire il riconoscimento oggetti con YOLO
- Disegnare box, etichette e conteggio classi rilevate
- Mostrare accanto al video un pannello testuale a colonne:
    timestamp | oggetto | sicurezza

Note:
- Il flusso RTSP deve essere già stato verificato come funzionante.
- Il modello predefinito è YOLOv8 nano.
- Il pannello laterale mostra gli eventi più recenti.
- La logica di classificazione "sicurezza" è semplificata e modificabile.
"""

import sys
import time
import argparse
from datetime import datetime

import cv2
import numpy as np
from ultralytics import YOLO


# ============================================================
# CONFIGURAZIONE DI DEFAULT
# ============================================================

DEFAULT_RTSP_URL = "rtsp://USERNAME:PASSWORD@192.168.1.37:554/avstream/channel=1/stream=0.sdp"
DEFAULT_MODEL = "yolov8n.pt"
DEFAULT_CONFIDENCE = 0.40
DEFAULT_WINDOW_NAME = "RTSP + YOLO Object Detection"
DEFAULT_RECONNECT_DELAY = 3

PANEL_WIDTH = 520
MAX_EVENT_ROWS = 22
EVENT_COOLDOWN_SECONDS = 2.0


# ============================================================
# FUNZIONI DI SUPPORTO
# ============================================================

def print_info(message):
    """
    Stampa un messaggio informativo.
    """
    print("[INFO] " + message)


def print_error(message):
    """
    Stampa un messaggio di errore.
    """
    print("[ERRORE] " + message)


def create_capture(rtsp_url):
    """
    Crea e restituisce un oggetto VideoCapture configurato per FFmpeg.
    """
    print_info("Tentativo di apertura del flusso RTSP...")
    print_info("URL: " + rtsp_url)

    cap = cv2.VideoCapture(rtsp_url, cv2.CAP_FFMPEG)

    return cap


def load_yolo_model(model_path):
    """
    Carica il modello YOLO.
    """
    print_info("Caricamento modello YOLO: " + model_path)

    try:
        model = YOLO(model_path)
    except Exception as exc:
        print_error("Impossibile caricare il modello YOLO.")
        print_error(str(exc))
        sys.exit(1)

    print_info("Modello caricato correttamente.")

    return model


def build_counts_dict(result, class_names):
    """
    Costruisce un dizionario con il conteggio degli oggetti rilevati.
    """
    counts = {}

    if result.boxes is None:
        return counts

    for box in result.boxes:
        cls_index = int(box.cls[0])

        if cls_index in class_names:
            class_name = class_names[cls_index]
        else:
            class_name = "classe_" + str(cls_index)

        if class_name not in counts:
            counts[class_name] = 0

        counts[class_name] = counts[class_name] + 1

    return counts


def draw_counts_panel(frame, counts):
    """
    Disegna sul frame un pannello con il conteggio degli oggetti rilevati.
    """
    x_start = 10
    y_start = 25
    line_height = 25

    cv2.putText(
        frame,
        "Oggetti rilevati:",
        (x_start, y_start),
        cv2.FONT_HERSHEY_SIMPLEX,
        0.7,
        (0, 255, 255),
        2,
        cv2.LINE_AA
    )

    current_line = 1

    if len(counts) == 0:
        cv2.putText(
            frame,
            "nessun oggetto",
            (x_start, y_start + current_line * line_height),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.6,
            (200, 200, 200),
            2,
            cv2.LINE_AA
        )
    else:
        for class_name in sorted(counts.keys()):
            text = class_name + ": " + str(counts[class_name])

            cv2.putText(
                frame,
                text,
                (x_start, y_start + current_line * line_height),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.6,
                (0, 255, 0),
                2,
                cv2.LINE_AA
            )

            current_line = current_line + 1

    return frame


def save_screenshot(frame):
    """
    Salva uno screenshot del frame corrente.
    """
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = "screenshot_" + timestamp + ".jpg"

    success = cv2.imwrite(filename, frame)

    if success is True:
        print_info("Screenshot salvato: " + filename)
    else:
        print_error("Salvataggio screenshot non riuscito.")


def get_security_level(class_name):
    """
    Restituisce una valutazione sintetica di sicurezza associata alla classe rilevata.

    La logica è volutamente semplice e facilmente modificabile.
    """
    high_risk_classes = ["knife", "scissors"]
    medium_risk_classes = ["car", "motorcycle", "bus", "truck"]
    attention_classes = ["person"]

    if class_name in high_risk_classes:
        return "ALTA"

    if class_name in medium_risk_classes:
        return "MEDIA"

    if class_name in attention_classes:
        return "ATTENZIONE"

    return "BASSA"


def get_security_color(security_level):
    """
    Restituisce il colore BGR da usare per la riga di sicurezza.
    """
    if security_level == "ALTA":
        return (0, 0, 255)

    if security_level == "MEDIA":
        return (0, 165, 255)

    if security_level == "ATTENZIONE":
        return (0, 255, 255)

    return (180, 180, 180)


def process_frame_with_yolo(model, frame, confidence):
    """
    Esegue l'inferenza YOLO sul frame e restituisce:
    - frame annotato
    - counts
    - events_in_frame
    """
    results = model.predict(
        source=frame,
        conf=confidence,
        verbose=False
    )

    if len(results) == 0:
        return frame, {}, []

    result = results[0]
    annotated_frame = result.plot()

    class_names = model.names
    counts = build_counts_dict(result, class_names)

    events_in_frame = []

    if result.boxes is not None:
        for box in result.boxes:
            cls_index = int(box.cls[0])

            if cls_index in class_names:
                class_name = class_names[cls_index]
            else:
                class_name = "classe_" + str(cls_index)

            security_level = get_security_level(class_name)

            event_record = {
                "timestamp": datetime.now().strftime("%H:%M:%S"),
                "object": class_name,
                "security": security_level
            }

            events_in_frame.append(event_record)

    annotated_frame = draw_counts_panel(annotated_frame, counts)

    return annotated_frame, counts, events_in_frame


def append_new_events(event_log, events_in_frame, last_seen_times, cooldown_seconds):
    """
    Aggiunge nuovi eventi al registro limitando duplicati troppo ravvicinati.

    La chiave di filtro è composta da:
    - nome oggetto
    - livello sicurezza
    """
    current_time = time.time()

    for event in events_in_frame:
        key = event["object"] + "|" + event["security"]

        if key not in last_seen_times:
            last_seen_times[key] = 0.0

        elapsed = current_time - last_seen_times[key]

        if elapsed >= cooldown_seconds:
            event_log.insert(0, event)
            last_seen_times[key] = current_time

    if len(event_log) > MAX_EVENT_ROWS:
        del event_log[MAX_EVENT_ROWS:]


def create_side_panel(height, width, event_log):
    """
    Crea il pannello laterale contenente:
    - titolo
    - intestazioni di colonna
    - righe eventi
    """
    panel = np.zeros((height, width, 3), dtype=np.uint8)

    panel[:] = (28, 28, 28)

    title_y = 35
    header_y = 75
    first_row_y = 110
    row_height = 28

    col1_x = 15
    col2_x = 125
    col3_x = 315

    cv2.putText(
        panel,
        "Registro rilevamenti",
        (15, title_y),
        cv2.FONT_HERSHEY_SIMPLEX,
        0.9,
        (255, 255, 255),
        2,
        cv2.LINE_AA
    )

    cv2.line(panel, (10, 48), (width - 10, 48), (90, 90, 90), 1)

    cv2.putText(
        panel,
        "Timestamp",
        (col1_x, header_y),
        cv2.FONT_HERSHEY_SIMPLEX,
        0.55,
        (0, 255, 255),
        2,
        cv2.LINE_AA
    )

    cv2.putText(
        panel,
        "Oggetto",
        (col2_x, header_y),
        cv2.FONT_HERSHEY_SIMPLEX,
        0.55,
        (0, 255, 255),
        2,
        cv2.LINE_AA
    )

    cv2.putText(
        panel,
        "Sicurezza",
        (col3_x, header_y),
        cv2.FONT_HERSHEY_SIMPLEX,
        0.55,
        (0, 255, 255),
        2,
        cv2.LINE_AA
    )

    cv2.line(panel, (10, 88), (width - 10, 88), (90, 90, 90), 1)

    if len(event_log) == 0:
        cv2.putText(
            panel,
            "Nessun evento registrato",
            (15, first_row_y),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.6,
            (180, 180, 180),
            1,
            cv2.LINE_AA
        )
        return panel

    row_index = 0

    for event in event_log:
        y = first_row_y + row_index * row_height

        if y > height - 15:
            break

        security_color = get_security_color(event["security"])

        cv2.putText(
            panel,
            event["timestamp"],
            (col1_x, y),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.50,
            (220, 220, 220),
            1,
            cv2.LINE_AA
        )

        cv2.putText(
            panel,
            event["object"],
            (col2_x, y),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.50,
            (220, 220, 220),
            1,
            cv2.LINE_AA
        )

        cv2.putText(
            panel,
            event["security"],
            (col3_x, y),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.50,
            security_color,
            1,
            cv2.LINE_AA
        )

        cv2.line(
            panel,
            (10, y + 8),
            (width - 10, y + 8),
            (55, 55, 55),
            1
        )

        row_index = row_index + 1

    return panel


def compose_output_frame(video_frame, event_log):
    """
    Compone il frame finale affiancando:
    - video annotato
    - pannello laterale eventi
    """
    video_height = video_frame.shape[0]
    side_panel = create_side_panel(video_height, PANEL_WIDTH, event_log)

    composed_frame = np.hstack((video_frame, side_panel))

    return composed_frame


# ============================================================
# CICLO PRINCIPALE
# ============================================================

def run(rtsp_url, model_path, confidence, reconnect_delay):
    """
    Esegue il programma principale.
    """
    model = load_yolo_model(model_path)

    cv2.namedWindow(DEFAULT_WINDOW_NAME, cv2.WINDOW_NORMAL)

    cap = None
    frame_counter = 0
    last_fps_update_time = time.time()
    fps_counter = 0
    current_fps = 0.0

    event_log = []
    last_seen_times = {}

    while True:
        if cap is None:
            cap = create_capture(rtsp_url)

            if cap.isOpened() is False:
                print_error("Impossibile aprire il flusso video.")
                print_info("Nuovo tentativo tra " + str(reconnect_delay) + " secondi...")
                cap.release()
                cap = None
                time.sleep(reconnect_delay)
                continue

            print_info("Flusso aperto correttamente.")

        ret, frame = cap.read()

        if ret is False:
            print_error("Frame non letto. Tentativo di riconnessione...")
            cap.release()
            cap = None
            time.sleep(reconnect_delay)
            continue

        frame_counter = frame_counter + 1
        fps_counter = fps_counter + 1

        annotated_frame, counts, events_in_frame = process_frame_with_yolo(
            model=model,
            frame=frame,
            confidence=confidence
        )

        append_new_events(
            event_log=event_log,
            events_in_frame=events_in_frame,
            last_seen_times=last_seen_times,
            cooldown_seconds=EVENT_COOLDOWN_SECONDS
        )

        current_time = time.time()
        elapsed = current_time - last_fps_update_time

        if elapsed >= 1.0:
            current_fps = fps_counter / elapsed
            fps_counter = 0
            last_fps_update_time = current_time

        fps_text = "FPS: {:.2f}".format(current_fps)

        cv2.putText(
            annotated_frame,
            fps_text,
            (10, annotated_frame.shape[0] - 20),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.7,
            (255, 255, 0),
            2,
            cv2.LINE_AA
        )

        final_frame = compose_output_frame(annotated_frame, event_log)

        cv2.imshow(DEFAULT_WINDOW_NAME, final_frame)

        key = cv2.waitKey(1) & 0xFF

        if key == ord("q"):
            print_info("Chiusura richiesta dall'utente.")
            break

        if key == ord("s"):
            save_screenshot(final_frame)

    if cap is not None:
        cap.release()

    cv2.destroyAllWindows()


# ============================================================
# ARGOMENTI DA RIGA DI COMANDO
# ============================================================

def parse_arguments():
    """
    Legge gli argomenti da riga di comando.
    """
    parser = argparse.ArgumentParser(
        description="Visualizzazione RTSP con rilevamento oggetti YOLO e pannello eventi"
    )

    parser.add_argument(
        "--url",
        type=str,
        default=DEFAULT_RTSP_URL,
        help="URL RTSP completo"
    )

    parser.add_argument(
        "--model",
        type=str,
        default=DEFAULT_MODEL,
        help="Modello YOLO da usare, ad esempio yolov8n.pt"
    )

    parser.add_argument(
        "--conf",
        type=float,
        default=DEFAULT_CONFIDENCE,
        help="Soglia di confidenza, ad esempio 0.40"
    )

    parser.add_argument(
        "--reconnect-delay",
        type=int,
        default=DEFAULT_RECONNECT_DELAY,
        help="Secondi di attesa prima della riconnessione"
    )

    return parser.parse_args()


# ============================================================
# ENTRY POINT
# ============================================================

def main():
    """
    Punto di ingresso del programma.
    """
    args = parse_arguments()

    run(
        rtsp_url=args.url,
        model_path=args.model,
        confidence=args.conf,
        reconnect_delay=args.reconnect_delay
    )


if __name__ == "__main__":
    main()
