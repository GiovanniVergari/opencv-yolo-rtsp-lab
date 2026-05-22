# ==================================================================================================
# test_rtsp_camera.py
# --------------------------------------------------------------------------------------------------
# Test diagnostico della telecamera IP / RTSP senza YOLO.
# Usa la stessa logica del viewer:
#   - OPENCV_FFMPEG_CAPTURE_OPTIONS impostato prima di cv2;
#   - cv2.CAP_FFMPEG;
#   - prova main stream e substream.
# ==================================================================================================

import rtsp_support

rtsp_support.configure_ffmpeg_environment()

import time

import cv2

import config_camera as cfg


def draw_status(frame, frame_count, valid_count, selected_source):
    """Disegna informazioni diagnostiche nella finestra."""

    lines = []
    lines.append("TEST RTSP CAMERA")
    lines.append("Frame validi: " + str(valid_count) + " / " + str(frame_count))
    lines.append("Source: " + str(selected_source))
    lines.append("q/ESC esci")

    y = 30

    for line in lines:
        cv2.putText(frame, line, (10, y), cv2.FONT_HERSHEY_SIMPLEX, 0.65, (255, 255, 255), 2, cv2.LINE_AA)
        cv2.putText(frame, line, (10, y), cv2.FONT_HERSHEY_SIMPLEX, 0.65, (0, 0, 0), 1, cv2.LINE_AA)
        y = y + 28


def main():
    """Esegue il test dello stream."""

    print("")
    print("==================================================================================================")
    print(" TEST TELECAMERA IP / RTSP - REPO STYLE")
    print("==================================================================================================")
    print("")

    cap, selected_source, first_frame = rtsp_support.open_first_working_capture(cv2)

    if cap is None:
        print("[ERR] Nessuna sorgente funzionante.")
        rtsp_support.print_rtsp_help()
        return

    print("[INFO] Sorgente selezionata:", selected_source)
    print("[INFO] Avvio finestra di test. Premere q o ESC per uscire.")

    cv2.namedWindow("Test RTSP Camera", cv2.WINDOW_NORMAL)

    frame_count = 0
    valid_count = 0
    start_time = time.time()

    while frame_count < 300:
        ret, frame = cap.read()
        frame_count = frame_count + 1

        if ret is False or frame is None:
            print("[WARN] Frame", frame_count, "non valido.")
            time.sleep(0.2)
            continue

        valid_count = valid_count + 1

        draw_status(frame, frame_count, valid_count, selected_source)
        cv2.imshow("Test RTSP Camera", frame)

        key = cv2.waitKey(1) & 0xFF

        if key == ord("q") or key == 27:
            break

    elapsed = time.time() - start_time

    print("")
    print("[INFO] Test terminato.")
    print("[INFO] Frame letti:", frame_count)
    print("[INFO] Frame validi:", valid_count)
    print("[INFO] Durata:", round(elapsed, 2), "secondi")
    print("")

    cap.release()
    cv2.destroyAllWindows()


if __name__ == "__main__":
    main()
