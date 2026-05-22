# ==================================================================================================
# rtsp_support.py
# --------------------------------------------------------------------------------------------------
# Funzioni comuni per aprire sorgenti video RTSP/Webcam/File con OpenCV.
#
# Nota fondamentale:
#   OPENCV_FFMPEG_CAPTURE_OPTIONS deve essere impostata prima dell'import di cv2.
#   Per questo motivo questo modulo NON importa cv2 in testa al file.
# ==================================================================================================

import os
import time

import config_camera as cfg


def configure_ffmpeg_environment():
    """Configura le opzioni FFmpeg usate da OpenCV."""

    if cfg.VIDEO_MODE.strip().lower() != "rtsp":
        return

    options = cfg.get_ffmpeg_capture_options()
    os.environ["OPENCV_FFMPEG_CAPTURE_OPTIONS"] = options

    print("[INFO] OPENCV_FFMPEG_CAPTURE_OPTIONS =", options)


def get_video_sources():
    """Restituisce le sorgenti video da provare."""

    mode = cfg.VIDEO_MODE.strip().lower()

    if mode == "webcam":
        return [cfg.WEBCAM_INDEX]

    if mode == "file":
        return [cfg.VIDEO_FILE_PATH]

    if mode == "rtsp":
        return cfg.get_rtsp_url_candidates()

    print("[WARN] VIDEO_MODE non riconosciuto. Uso webcam locale.")
    return [cfg.WEBCAM_INDEX]


def create_capture(cv2_module, source, force_ffmpeg):
    """
    Crea una VideoCapture robusta.

    Per RTSP viene usato cv2.CAP_FFMPEG, coerentemente con l'impostazione originale della repo.
    """

    api_preference = 0

    if force_ffmpeg is True:
        api_preference = cv2_module.CAP_FFMPEG

    params = [
        cv2_module.CAP_PROP_OPEN_TIMEOUT_MSEC,
        cfg.CAPTURE_OPEN_TIMEOUT_MS,
        cv2_module.CAP_PROP_READ_TIMEOUT_MSEC,
        cfg.CAPTURE_READ_TIMEOUT_MS,
    ]

    try:
        if api_preference != 0:
            cap = cv2_module.VideoCapture(source, api_preference, params)
        else:
            cap = cv2_module.VideoCapture(source, params)
    except Exception:
        if api_preference != 0:
            cap = cv2_module.VideoCapture(source, api_preference)
        else:
            cap = cv2_module.VideoCapture(source)

        try:
            cap.set(cv2_module.CAP_PROP_OPEN_TIMEOUT_MSEC, cfg.CAPTURE_OPEN_TIMEOUT_MS)
            cap.set(cv2_module.CAP_PROP_READ_TIMEOUT_MSEC, cfg.CAPTURE_READ_TIMEOUT_MS)
        except Exception:
            pass

    return cap


def test_capture_read(cap):
    """Prova a leggere frame validi dalla sorgente."""

    for attempt in range(1, cfg.STREAM_TEST_ATTEMPTS + 1):
        ret, frame = cap.read()

        if ret is True and frame is not None:
            height, width = frame.shape[:2]
            print("[INFO] Frame valido ricevuto:", str(width) + "x" + str(height))
            return True, frame

        print(
            "[WARN] Tentativo lettura frame",
            str(attempt) + "/" + str(cfg.STREAM_TEST_ATTEMPTS),
            "non riuscito."
        )

        time.sleep(cfg.STREAM_TEST_WAIT_SECONDS)

    return False, None


def open_first_working_capture(cv2_module):
    """
    Prova le sorgenti configurate fino a trovare quella funzionante.

    Per RTSP:
      - usa CAP_FFMPEG;
      - prova stream principale;
      - poi stream secondario, se configurato.
    """

    sources = get_video_sources()
    mode = cfg.VIDEO_MODE.strip().lower()

    for source_index in range(0, len(sources)):
        source = sources[source_index]

        print("")
        print("--------------------------------------------------------------------------------------------------")
        print("[INFO] Provo sorgente", str(source_index + 1), "di", str(len(sources)))
        print("[INFO]", source)
        print("--------------------------------------------------------------------------------------------------")

        force_ffmpeg = False

        if mode == "rtsp":
            force_ffmpeg = True

        cap = create_capture(cv2_module, source, force_ffmpeg)

        if cap is None:
            print("[WARN] VideoCapture non creata.")
            continue

        if cap.isOpened() is False:
            print("[WARN] Sorgente non aperta.")
            cap.release()
            continue

        print("[INFO] Sorgente aperta. Test lettura frame...")

        success, first_frame = test_capture_read(cap)

        if success is True:
            print("[INFO] Sorgente funzionante selezionata.")
            return cap, source, first_frame

        print("[WARN] Sorgente aperta ma senza frame validi.")
        cap.release()

    return None, None, None


def print_rtsp_help():
    """Mostra suggerimenti diagnostici."""

    print("")
    print("==================================================================================================")
    print(" DIAGNOSTICA RTSP")
    print("==================================================================================================")
    print("")
    print("1. Verificare che PC e telecamera siano nella stessa rete.")
    print("2. Verificare indirizzo IP, username e password in config_camera.py.")
    print("3. Provare con VLC lo stesso URL RTSP.")
    print("4. Provare stream principale e secondario:")
    print("   - /avstream/channel=1/stream=0.sdp")
    print("   - /avstream/channel=1/stream=1.sdp")
    print("5. Verificare che Python/OpenCV non siano bloccati da firewall o antivirus.")
    print("6. Se VLC funziona ma OpenCV no, controllare che sia installato opencv-python e non opencv-python-headless.")
    print("")
