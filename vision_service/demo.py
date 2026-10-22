"""نافذة تجربة حيّة للموديل — تشوف الكاميرا والمستطيلات والـROI.

مش بتبعت تنبيهات ولا بتكتب في قاعدة البيانات. بتستخدم نفس الإعدادات ونفس
الموديل بتاع الخدمة، عشان اللي تشوفه هنا هو اللي هيحصل فعلاً.

    .\\.venv\\Scripts\\python.exe demo.py
    .\\.venv\\Scripts\\python.exe demo.py --conf 0.35
    .\\.venv\\Scripts\\python.exe demo.py --snapshot demo.jpg
"""

from __future__ import annotations

import argparse
import time

import cv2

from core.config import load_config, resolve_path
from core.detector import FridgeDetector
from main import is_video_file, open_camera, roi_mask

GREEN = (120, 230, 120)
YELLOW = (60, 220, 250)
GREY = (170, 170, 170)
RED = (90, 90, 240)


def draw(frame, detections, roi, inside_flags, fps, note):
    canvas = frame.copy()
    if roi and len(roi) >= 3:
        cv2.polylines(canvas, [__import__("numpy").array(roi, "int32")], True, YELLOW, 2)
        cv2.putText(canvas, "ROI", (roi[0][0] + 6, roi[0][1] + 20),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.55, YELLOW, 1, cv2.LINE_AA)

    for item, inside in zip(detections, inside_flags):
        x1, y1, x2, y2 = item["bbox"]
        colour = GREEN if inside else GREY
        cv2.rectangle(canvas, (x1, y1), (x2, y2), colour, 2)
        cv2.putText(canvas, f'{item["label"]} {item["conf"]:.2f}',
                    (x1, max(14, y1 - 6)), cv2.FONT_HERSHEY_SIMPLEX, 0.5,
                    colour, 1, cv2.LINE_AA)

    height = canvas.shape[0]
    cv2.rectangle(canvas, (0, height - 30), (canvas.shape[1], height), (20, 20, 20), -1)
    cv2.putText(canvas, f"{fps:.1f} fps | in ROI: {inside_flags.count(True)} | {note}",
                (8, height - 9), cv2.FONT_HERSHEY_SIMPLEX, 0.55, (240, 240, 240), 1,
                cv2.LINE_AA)
    return canvas


def main():
    parser = argparse.ArgumentParser(description="PlayZone fridge vision demo")
    parser.add_argument("--config")
    parser.add_argument("--source", help="كاميرا أو فيديو بدل الإعدادات")
    parser.add_argument("--conf", type=float, help="عتبة الثقة (افتراضي من الإعدادات)")
    parser.add_argument("--imgsz", type=int, help="حجم الإدخال (افتراضي من الإعدادات)")
    parser.add_argument("--snapshot", help="احفظ صورة واحدة واخرج")
    parser.add_argument("--no-window", action="store_true", help="من غير نافذة")
    args = parser.parse_args()

    cfg = load_config(args.config)
    camera = cfg["camera"]
    source = args.source if args.source is not None else camera["source"]
    roi = camera.get("roi") or []

    detector = FridgeDetector(
        weights=resolve_path(cfg["model"]["weights"], cfg["_base_dir"]),
        conf_thres=args.conf if args.conf is not None else cfg["model"]["conf_threshold"],
        iou_thres=cfg["model"].get("iou_threshold", 0.45),
        keep_labels=cfg["model"].get("labels") or [],
        imgsz=args.imgsz or cfg["model"].get("imgsz", 480),
    )

    capture = open_camera(source)
    if not capture.isOpened():
        raise SystemExit(f"تعذر فتح المصدر: {source}")
    try:
        capture.set(cv2.CAP_PROP_BUFFERSIZE, 1)
    except cv2.error:
        pass

    video_mode = is_video_file(source)
    snapshot_path = args.snapshot
    last = time.monotonic()
    fps = 0.0
    misses = 0
    frames = 0

    print("q أو Esc للخروج")
    while True:
        ok, frame = capture.read()
        if not ok or frame is None:
            if video_mode:
                break
            misses += 1
            if misses > 30:
                break
            time.sleep(0.05)
            continue
        misses = 0
        frames += 1

        detections = detector.detect(frame)
        inside = [detector.is_inside_roi(item["bbox"], roi) for item in detections]
        now = time.monotonic()
        elapsed = now - last
        last = now
        if elapsed > 0:
            fps = 0.9 * fps + 0.1 * (1.0 / elapsed)

        labels_in = [item["label"] for item, flag in zip(detections, inside) if flag]
        note = " | ".join(sorted(set(labels_in))) or "nothing inside the ROI"
        canvas = draw(frame, detections, roi, inside, fps, note)

        if snapshot_path:
            # صبر شوية عشان تعرّض الكاميرا يستقر قبل الصورة.
            if frames >= 6:
                cv2.imwrite(snapshot_path, canvas)
                print(f"saved {snapshot_path} | detections: {len(detections)} | in ROI: {inside.count(True)}")
                break
            continue

        if not args.no_window:
            cv2.imshow("PlayZone - Fridge Vision", canvas)
            if cv2.waitKey(1) & 0xFF in (ord("q"), 27):
                break

    capture.release()
    if not args.no_window:
        cv2.destroyAllWindows()
    print(f"frames={frames}")


if __name__ == "__main__":
    main()
