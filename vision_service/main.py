"""PlayZone — خدمة رصد الثلاجة بالكاميرا.

بتقرا صورة الكاميرا، تلاقي منتج جوه منطقة الرصد (ROI)، تتأكد إنه **مش**
مسجّل على كاشير PlayZone خلال آخر ``check_window_seconds``، وبعدها تبعت
تنبيه تليجرام مع صورة الدليل. القاعدة بتتقرا قراءة فقط — مفيش أي كتابة.

التشغيل:
    python main.py
    python main.py --config config.yaml --dry-run
    python main.py --video sample.mp4 --once 200
"""

from __future__ import annotations

import argparse
import logging
import os
import signal
import sys
import time
from pathlib import Path

# لازم قبل استيراد cv2 — يخلي RTSP يمشي على TCP (أثبت للشبكة).
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


def _handle_signal(signum, _frame):
    global _stop
    _stop = True
    LOG.info("وصلت إشارة إيقاف (%s) — بستنى الدورة الحالية تخلص", signum)


def _sleep(seconds: float) -> None:
    """نوم قابل للإلغاء عشان Ctrl+C ميستناش كتير."""
    deadline = time.monotonic() + max(0.0, seconds)
    while not _stop and time.monotonic() < deadline:
        time.sleep(min(0.2, max(0.0, deadline - time.monotonic())))


def load_env(base_dir: str) -> None:
    """يقرا ``.env`` (توكن تليجرام) لو python-dotenv موجودة."""
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

    # مكتبات خارجية مش محتاجة تزعجنا بتفاصيلها.
    for noisy in ("ultralytics", "urllib3", "matplotlib"):
        logging.getLogger(noisy).setLevel(logging.WARNING)


def is_video_file(source) -> bool:
    """ملف فيديو محلي (مش كاميرا ولا RTSP) — نقف في آخره بدل إعادة الفتح."""
    if not isinstance(source, str):
        return False
    if source.lower().startswith(("rtsp://", "http://", "https://")):
        return False
    return Path(source).is_file()


def open_camera(source):
    if isinstance(source, int):
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


def save_evidence(detector, frame, detections, roi, evidence_dir, label):
    try:
        Path(evidence_dir).mkdir(parents=True, exist_ok=True)
        stamp = time.strftime("%Y%m%d_%H%M%S")
        safe_label = "".join(ch if ch.isalnum() else "_" for ch in str(label))[:40]
        path = str(Path(evidence_dir) / f"{stamp}_{safe_label}.jpg")
        cv2.imwrite(path, detector.annotate(frame, detections, roi))
        return path
    except Exception as error:  # noqa: BLE001
        LOG.warning("مش قادر أحفظ صورة الدليل: %s", error)
        return None


def handle_frame(frame, cfg, detector, pos, alerts, tracker, show=False):
    """يعالج إطار واحد؛ يرجّع عدد التنبيهات اللي اتبعتت."""
    roi = cfg["camera"].get("roi")
    detections = detector.detect(frame)
    inside = [item for item in detections if detector.is_inside_roi(item["bbox"], roi)]
    labels = {item["label"] for item in inside}

    fired = tracker.update(labels)
    if not fired:
        if show:
            cv2.imshow("PlayZone - Fridge", detector.annotate(frame, inside, roi))
        return 0

    window = cfg["pos"].get("check_window_seconds", 90)
    sent = 0
    for label in fired:
        aliases = aliases_for(cfg, label)
        sold, description = pos.check_recent_sale(label, aliases, window)
        if sold:
            LOG.info("مرصود '%s' بس متسجّل على الكاشير — مفيش تنبيه", label)
            continue

        note = f"احتمال: {' / '.join(aliases[:5])}" if aliases else None
        image_path = save_evidence(
            detector, frame, inside, roi, cfg["alerts"]["evidence_dir"], label
        )
        alerts.send(label, image_path=image_path, note=note)
        sent += 1

    if show:
        cv2.imshow("PlayZone - Fridge", detector.annotate(frame, inside, roi))
    return sent


def run(cfg, args):
    camera = cfg["camera"]
    source = args.source if args.source is not None else camera["source"]
    video_mode = is_video_file(source)
    fps = max(0.5, float(camera.get("fps") or 4.0))
    interval = 1.0 / fps
    reconnect = max(1.0, float(camera.get("reconnect_seconds") or 5.0))
    min_motion = float(cfg.get("runtime", {}).get("min_motion", 0) or 0)

    detector = FridgeDetector(
        weights=resolve_path(cfg["model"]["weights"], cfg["_base_dir"]),
        conf_thres=cfg["model"].get("conf_threshold", 0.55),
        iou_thres=cfg["model"].get("iou_threshold", 0.45),
        keep_labels=cfg["model"].get("labels") or [],
    )
    pos = PosClient(cfg["pos"], cfg["_base_dir"])
    alerts = AlertManager(cfg, cfg["_base_dir"])

    if args.dry_run or args.no_telegram:
        cfg["alerts"].setdefault("telegram", {})["enabled"] = False
        LOG.info("وضع التجربة: تنبيهات تليجرام متوقفة (السجل والصور شغالين)")

    tracker = ZoneTracker(
        min_hits=cfg["alerts"]["min_hits"],
        cooldown_seconds=cfg["alerts"]["cooldown_seconds"],
    )

    LOG.info(
        "بدء الرصد | المصدر=%s | fps=%.1f | ROI=%s | قاعدة=%s | كولداون=%.0f ث",
        source,
        fps,
        camera.get("roi") or "كل الكادر",
        pos.database if pos.mode == "local" else pos.mode,
        cfg["alerts"]["cooldown_seconds"],
    )

    capture = None
    previous_gray = None
    processed = 0
    alerts_sent = 0
    last_sample = 0.0
    retry_at = 0.0

    while not _stop:
        if capture is None or not capture.isOpened():
            now = time.monotonic()
            if now < retry_at:
                _sleep(min(1.0, retry_at - now))
                continue
            capture = open_camera(source)
            if not capture.isOpened():
                LOG.warning(
                    "الكاميرا مش راضية تفتح (%s) — محاولة تانية بعد %.0f ث",
                    source,
                    reconnect,
                )
                capture.release()
                capture = None
                retry_at = time.monotonic() + reconnect
                if args.once:
                    break
                continue
            LOG.info("الكاميرا اتوصلت: %s", source)
            previous_gray = None

        ok, frame = capture.read()
        if not ok or frame is None:
            if video_mode:
                LOG.info("خلص الفيديو (%s)", source)
                break
            LOG.warning("انقطعت الصورة — بعيد الاتصال بالكاميرا")
            capture.release()
            capture = None
            previous_gray = None
            retry_at = time.monotonic() + 1.0
            _sleep(1.0)
            continue

        moment = time.monotonic()
        if not video_mode and moment - last_sample < interval:
            continue
        last_sample = moment

        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        if min_motion > 0 and previous_gray is not None:
            diff = cv2.absdiff(gray, previous_gray)
            motion = cv2.mean(diff, mask=roi_mask(frame.shape, camera.get("roi")))[0]
            if motion < min_motion:
                previous_gray = gray
                continue
        previous_gray = gray

        alerts_sent += handle_frame(
            frame, cfg, detector, pos, alerts, tracker, show=args.show
        )
        processed += 1

        if args.show and (cv2.waitKey(1) & 0xFF) in (ord("q"), 27):
            LOG.info("اتقفلت نافذة المعاينة")
            break
        if args.once and processed >= args.once:
            LOG.info("خلصت %d إطار (--once)", processed)
            break

    if capture is not None:
        capture.release()
    if args.show:
        cv2.destroyAllWindows()

    LOG.info("الخدمة وقفت | إطارات=%d | تنبيهات=%d", processed, alerts_sent)
    return 0


def build_parser():
    parser = argparse.ArgumentParser(
        description="PlayZone fridge vision service",
    )
    parser.add_argument("--config", help="مسار config.yaml (الافتراضي: config.yaml)")
    parser.add_argument("--source", help="كاميرا/فيديو بدل اللي في الإعدادات")
    parser.add_argument("--video", dest="source", help="اختصار لتجربة على ملف فيديو")
    parser.add_argument("--once", type=int, default=0, help="يقف بعد N إطار معالَج")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="مفيش تليجرام — بس السجل وصور الدليل",
    )
    parser.add_argument(
        "--no-telegram",
        action="store_true",
        help="إيقاف تليجرام مؤقتاً من غير تعديل الإعدادات",
    )
    parser.add_argument("--show", action="store_true", help="نافذة معاينة (q للخروج)")
    parser.add_argument("--verbose", action="store_true", help="لوج تفصيلي")
    return parser


def main(argv=None):
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except (AttributeError, OSError):
        pass

    args = build_parser().parse_args(argv)
    root = str(service_root())
    setup_logging(root, verbose=args.verbose)
    load_env(root)

    signal.signal(signal.SIGINT, _handle_signal)
    if hasattr(signal, "SIGTERM"):
        signal.signal(signal.SIGTERM, _handle_signal)

    try:
        cfg = load_config(args.config)
    except (FileNotFoundError, ValueError) as error:
        LOG.error("%s", error)
        return 2

    LOG.info("الإعدادات: %s", cfg.get("_config_path") or "الافتراضية")

    try:
        return run(cfg, args)
    except KeyboardInterrupt:
        LOG.info("اتوقفت يدوياً")
        return 0
    except Exception:  # noqa: BLE001
        LOG.exception("الخدمة وقعت على خطأ غير متوقع")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
