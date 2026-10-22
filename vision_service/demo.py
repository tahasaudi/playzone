"""نافذة تجربة حيّة للموديل — تشوف الكاميرا والمستطيلات والـROI.

مش بتبعت تنبيهات ولا بتكتب في قاعدة البيانات. بتستخدم نفس الإعدادات ونفس
الموديل بتاع الخدمة، عشان اللي تشوفه هنا هو اللي هيحصل فعلاً.

    .\\.venv\\Scripts\\python.exe demo.py
    .\\.venv\\Scripts\\python.exe demo.py --conf 0.35
    .\\.venv\\Scripts\\python.exe demo.py --snapshot demo.jpg

كاميرات المحل (كل الكاميرات في شبكة واحدة والموديل شغال على كل واحدة):

    .\\.venv\\Scripts\\python.exe demo.py --shop
"""

from __future__ import annotations

import argparse
import time

import cv2
import numpy as np

from core.config import load_config, resolve_path
from core.detector import FridgeDetector
from main import is_video_file, open_camera

GREEN = (120, 230, 120)
YELLOW = (60, 220, 250)
GREY = (170, 170, 170)
RED = (90, 90, 240)


def draw(frame, detections, roi, inside_flags, fps, note):
    canvas = frame.copy()
    if roi and len(roi) >= 3:
        cv2.polylines(canvas, [np.array(roi, "int32")], True, YELLOW, 2)
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


def _offline_tile(name, width, height):
    tile = np.full((height, width, 3), 26, np.uint8)
    cv2.putText(tile, "OFFLINE", (width // 2 - 60, height // 2),
                cv2.FONT_HERSHEY_SIMPLEX, 0.9, RED, 2, cv2.LINE_AA)
    cv2.putText(tile, name, (12, 28), cv2.FONT_HERSHEY_SIMPLEX, 0.7,
                (220, 220, 220), 2, cv2.LINE_AA)
    return tile


def _fit(frame, width, height):
    """يحط الصورة في خانة بمقاس ثابت من غير ما يمدّها."""
    h, w = frame.shape[:2]
    scale = min(width / float(w), height / float(h))
    resized = cv2.resize(frame, (max(1, int(w * scale)), max(1, int(h * scale))))
    canvas = np.zeros((height, width, 3), np.uint8)
    y = (height - resized.shape[0]) // 2
    x = (width - resized.shape[1]) // 2
    canvas[y:y + resized.shape[0], x:x + resized.shape[1]] = resized
    return canvas


def _grid(tiles, cols):
    while len(tiles) % cols:
        tiles.append(np.zeros_like(tiles[0]))
    rows = [np.hstack(tiles[i:i + cols]) for i in range(0, len(tiles), cols)]
    return np.vstack(rows)


def run_shop(cfg, args, detector):
    cameras = cfg["shop"]["cameras"]
    if not cameras:
        raise SystemExit(
            "مفيش كاميرات محل في الإعدادات — ضيف shop.cameras في config.yaml"
        )

    print(f"كاميرات المحل: {len(cameras)}")
    for cam in cameras:
        print(f"  - {cam['name']}: {cam['source']}")
        if isinstance(cam["source"], str) and (
            "${" in cam["source"] or "USERNAME" in cam["source"]
        ):
            print("    تحذير: الرابط فيه متغير مش متعرّف — ظبط .env (CAM_USER/CAM_PASS)")

    captures = [None] * len(cameras)
    frames = [None] * len(cameras)
    failed = [0] * len(cameras)
    retry_at = [0.0] * len(cameras)
    fps = [0.0] * len(cameras)
    last_tick = time.monotonic()

    cols = 1 if len(cameras) == 1 else 2
    tile_w, tile_h = (960, 540) if len(cameras) == 1 else (640, 360)
    rounds = 0

    print("q أو Esc للخروج")
    while True:
        for index, cam in enumerate(cameras):
            now = time.monotonic()
            if captures[index] is None:
                if now < retry_at[index]:
                    frames[index] = None
                    continue
                capture = open_camera(cam["source"])
                if not capture.isOpened():
                    print(f"تعذر الاتصال: {cam['name']}")
                    retry_at[index] = now + cam.get("reconnect_seconds", 5.0)
                    frames[index] = None
                    continue
                try:
                    capture.set(cv2.CAP_PROP_BUFFERSIZE, 1)
                except cv2.error:
                    pass
                captures[index] = capture
                failed[index] = 0
                print(f"اتوصلت: {cam['name']}")

            ok, frame = captures[index].read()
            if not ok or frame is None:
                failed[index] += 1
                if failed[index] > 20:
                    captures[index].release()
                    captures[index] = None
                    frames[index] = None
                    retry_at[index] = time.monotonic() + cam.get("reconnect_seconds", 5.0)
                continue

            failed[index] = 0
            detections = detector.detect(frame)
            roi = cam.get("roi") or []
            inside = [detector.is_inside_roi(item["bbox"], roi) for item in detections]
            labels_in = [item["label"] for item, flag in zip(detections, inside) if flag]
            note = " | ".join(sorted(set(labels_in))) or "-"
            frames[index] = draw(frame, detections, roi, inside, fps[index], note)

        now = time.monotonic()
        elapsed = max(1e-6, now - last_tick)
        last_tick = now
        online = sum(1 for item in captures if item is not None)
        if online:
            for index, cam in enumerate(cameras):
                if frames[index] is not None:
                    fps[index] = 0.85 * fps[index] + 0.15 * (1.0 / elapsed)

        tiles = []
        for index, cam in enumerate(cameras):
            name = cam["name"]
            if frames[index] is None:
                tiles.append(_offline_tile(name, tile_w, tile_h))
            else:
                tile = _fit(frames[index], tile_w, tile_h)
                tiles.append(tile)

        grid = _grid(tiles, cols)
        online_text = f"{online}/{len(cameras)} online"
        cv2.rectangle(grid, (0, 0), (grid.shape[1], 30), (15, 15, 15), -1)
        cv2.putText(grid, f"PlayZone shop cameras | {online_text} | Q to close",
                    (10, 21), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (240, 240, 240), 1,
                    cv2.LINE_AA)

        if not args.no_window:
            cv2.imshow("PlayZone - Shop Cameras", grid)
            key = cv2.waitKey(1) & 0xFF
            if key in (ord("q"), 27):
                break
            if cv2.getWindowProperty("PlayZone - Shop Cameras", cv2.WND_PROP_VISIBLE) < 1:
                break

        rounds += 1
        if not online:
            # مفيش كاميرا شغالة: مفيش داعي نلف على المعالج بسرعة.
            time.sleep(0.2)
        if args.snapshot and rounds >= 6:
            cv2.imwrite(args.snapshot, grid)
            print(f"saved {args.snapshot} | {online_text}")
            break

    for capture in captures:
        if capture is not None:
            capture.release()
    if not args.no_window:
        cv2.destroyAllWindows()


def main():
    parser = argparse.ArgumentParser(description="PlayZone fridge vision demo")
    parser.add_argument("--config")
    parser.add_argument("--source", help="كاميرا أو فيديو بدل الإعدادات")
    parser.add_argument("--conf", type=float, help="عتبة الثقة (افتراضي من الإعدادات)")
    parser.add_argument("--imgsz", type=int, help="حجم الإدخال (افتراضي من الإعدادات)")
    parser.add_argument("--snapshot", help="احفظ صورة واحدة واخرج")
    parser.add_argument("--no-window", action="store_true", help="من غير نافذة")
    parser.add_argument("--shop", action="store_true", help="كل كاميرات المحل في شبكة")
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

    if args.shop:
        run_shop(cfg, args, detector)
        return

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
