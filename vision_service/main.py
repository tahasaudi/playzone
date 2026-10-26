"""PlayZone — خدمة رصد الثلاجة بالكاميرا."""

from __future__ import annotations

import argparse
import logging
import os
import signal
import sys
import threading
import time
from pathlib import Path

os.environ.setdefault("OPENCV_FFMPEG_CAPTURE_OPTIONS", "rtsp_transport;tcp")

import cv2  # noqa: E402
import numpy as np  # noqa: E402

from core.alerts import AlertManager  # noqa: E402
from core.config import load_config, resolve_path, service_root  # noqa: E402
from core.detector import FridgeDetector  # noqa: E402
from core.pos_client import PosClient  # noqa: E402
from core.tracker import ZoneTracker  # noqa: E402

LOG = logging.getLogger("vision")
_stop = False
_MODEL_LOCK = threading.Lock()

FRIDGE_CAMERAS = {"كاميرا 3", "3", "camera 3", "ch3", "301"}
FRIDGE_CAMERAS.update({"كاميرا 7", "7", "camera 7", "ch7", "701"})

_person_state = {}
_person_lock = threading.Lock()


def _handle_signal(signum, _frame):
    global _stop
    _stop = True
    LOG.info("وصلت إشارة إيقاف (%s) — بستنى الدورة الحالية تخلص", signum)


def _sleep(seconds: float) -> None:
    deadline = time.monotonic() + max(0.0, seconds)
    while not _stop and time.monotonic() < deadline:
        time.sleep(min(0.2, max(0.0, deadline - time.monotonic())))


def load_env(base_dir: str) -> None:
    env_file = Path(base_dir) / ".env"
    if not env_file.exists():
        return
    try:
        from dotenv import load_dotenv
    except ImportError:
        LOG.warning("python-dotenv مش متسطّبة — .env مش هيتقرا")
        return
    load_dotenv(env_file)


def setup_logging(base_dir: str, verbose: bool = False) -> None:
    logs_dir = Path(base_dir) / "logs"
    logs_dir.mkdir(parents=True, exist_ok=True)

    root = logging.getLogger()
    root.setLevel(logging.DEBUG if verbose else logging.INFO)
    root.handlers.clear()

    formatter = logging.Formatter(
        "%(asctime)s | %(levelname)-7s | %(name)s | %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )

    console = logging.StreamHandler(sys.stdout)
    console.setFormatter(formatter)
    root.addHandler(console)

    file_handler = logging.FileHandler(
        logs_dir / "vision.log", encoding="utf-8"
    )
    file_handler.setFormatter(formatter)
    root.addHandler(file_handler)

    for noisy in ("ultralytics", "urllib3", "matplotlib"):
        logging.getLogger(noisy).setLevel(logging.WARNING)


def is_video_file(source) -> bool:
    if not isinstance(source, str):
        return False
    if source.lower().startswith(("rtsp://", "http://", "https://")):
        return False
    return Path(source).is_file()


def open_camera(source):
    if isinstance(source, int):
        if os.name == "nt":
            return cv2.VideoCapture(source, cv2.CAP_DSHOW)
        return cv2.VideoCapture(source)
    text = str(source)
    backend = cv2.CAP_FFMPEG if text.lower().startswith(("rtsp://", "http://", "https://")) else cv2.CAP_ANY
    return cv2.VideoCapture(text, backend)


def roi_mask(shape, roi):
    mask = np.zeros(shape[:2], dtype=np.uint8)
    if roi and len(roi) >= 3:
        cv2.fillPoly(mask, [np.array(roi, np.int32)], 255)
    else:
        mask[:] = 255
    return mask


def aliases_for(cfg, label):
    mapping = cfg.get("products") or {}
    for key, value in mapping.items():
        if str(key).strip().lower() == str(label).strip().lower():
            if isinstance(value, list):
                return [str(item) for item in value]
            if value:
                return [str(value)]
    return []


def save_evidence(detector, frame, detections, roi, evidence_dir, label, tag=""):
    try:
        Path(evidence_dir).mkdir(parents=True, exist_ok=True)
        stamp = time.strftime("%Y%m%d_%H%M%S")
        safe_label = "".join(ch if ch.isalnum() else "_" for ch in str(label))[:40]
        path = str(Path(evidence_dir) / f"{stamp}_{tag}{safe_label}.jpg")
        cv2.imwrite(path, detector.annotate(frame, detections, roi))
        return path
    except Exception as error:
        LOG.warning("مش قادر أحفظ صورة الدليل: %s", error)
        return None


def _is_fridge_cam(name: str, source: str) -> bool:
    n = str(name).lower()
    s = str(source)
    if any(x in n for x in ["3", "7", "ثلاجة"]):
        return True
    if "/channels/301" in s or "/channels/701" in s:
        return True
    return False


def handle_frame(frame, cfg, detector, pos, alerts, tracker, show=False, roi=None, tag="", cam_name=""):
    if roi is None:
        roi = cfg["camera"].get("roi")
    with _MODEL_LOCK:
        detections = detector.detect(frame)
    inside = [item for item in detections if detector.is_inside_roi(item["bbox"], roi)]
    labels = {item["label"] for item in inside}

    fired = tracker.update(labels)
    sent = 0
    if fired:
        window = cfg["pos"].get("check_window_seconds", 90)
        for label in fired:
            aliases = aliases_for(cfg, label)
            sold, description = pos.check_recent_sale(label, aliases, window)
            if sold:
                LOG.info("مرصود '%s' بس متسجّل على الكاشير — مفيش تنبيه", label)
                continue

            note = f"احتمال: {' / '.join(aliases[:5])}" if aliases else None
            image_path = save_evidence(
                detector, frame, inside, roi, cfg["alerts"]["evidence_dir"], label, tag
            )
            try:
                alerts.send(label, image_path=image_path, note=note, camera=cam_name or tag)
            except TypeError:
                alerts.send(label, image_path=image_path, note=note)
            sent += 1

    # لو مفيش منتج مكتشف، لكن فيه شخص على كاميرا التلاجة وافتتح وسحب من غير تسجيل
    if sent == 0 and _is_fridge_cam(cam_name, cfg.get("_last_source", "")):
        persons = [d for d in inside if str(d.get("label","")).lower() == "person"]
        if persons:
            now = time.time()
            with _person_lock:
                key = cam_name
                st = _person_state.get(key) or {"seen": 0, "last": now, "alerted": 0}
                st["seen"] += 1
                st["last"] = now
                if st["seen"] >= 2 and (now - st["alerted"]) > 60:
                    st["alerted"] = now
                    _person_state[key] = st
            # نفحص هل فيه بيع حديث؟ لو لأ نبعت تنبيه
            sold, _ = pos.check_recent_sale("bottle", aliases_for(cfg,"bottle"), 90)
            if not sold:
                image_path = save_evidence(
                    detector, frame, persons, roi, cfg["alerts"]["evidence_dir"], "person", tag
                )
                try:
                    alerts.send("bottle", image_path=image_path, note="تم سحب منتج من التلاجة دون تسجيل على الكاشير", camera=cam_name or tag)
                except TypeError:
                    alerts.send("bottle", image_path=image_path, note="تم سحب منتج من التلاجة دون تسجيل على الكاشير")
                sent += 1

    if show:
        cv2.imshow("PlayZone - Fridge", detector.annotate(frame, inside, roi))
    return sent, len(inside)
