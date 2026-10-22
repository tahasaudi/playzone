"""كشف المنتجات في صورة الثلاجة وتحديد اللي منها جوه منطقة الرصد."""

from __future__ import annotations

import cv2
import numpy as np
from ultralytics import YOLO


class FridgeDetector:
    def __init__(self, weights, conf_thres=0.55, iou_thres=0.45, keep_labels=None,
                 imgsz=480):
        self.model = YOLO(weights)
        self.conf_thres = float(conf_thres)
        self.iou_thres = float(iou_thres)
        self.imgsz = max(160, int(imgsz))
        self.keep_labels = {
            str(item).strip().lower()
            for item in (keep_labels or [])
            if str(item).strip()
        }

    def detect(self, frame):
        results = self.model(
            frame,
            conf=self.conf_thres,
            iou=self.iou_thres,
            imgsz=self.imgsz,
            verbose=False,
        )
        detections = []
        for result in results:
            if result.boxes is None:
                continue
            for box in result.boxes:
                class_id = int(box.cls[0])
                label = str(self.model.names[class_id])
                if self.keep_labels and label.strip().lower() not in self.keep_labels:
                    continue
                x1, y1, x2, y2 = map(int, box.xyxy[0])
                detections.append(
                    {
                        "label": label,
                        "conf": float(box.conf[0]),
                        "bbox": (x1, y1, x2, y2),
                    }
                )
        return detections

    def is_inside_roi(self, bbox, roi_poly):
        """مركز العلبة جوه المضلّع؟ من غير ROI كل حاجة مقبولة."""
        if not roi_poly or len(roi_poly) < 3:
            return True
        x1, y1, x2, y2 = bbox
        center = ((x1 + x2) // 2, (y1 + y2) // 2)
        polygon = np.array(roi_poly, np.int32)
        try:
            return cv2.pointPolygonTest(polygon, center, False) >= 0
        except cv2.error:
            return False

    def annotate(self, frame, detections, roi_poly=None):
        """نسخة من الإطار عليها المستطيلات والـROI — دليل التنبيه."""
        canvas = frame.copy()
        if roi_poly and len(roi_poly) >= 3:
            cv2.polylines(
                canvas,
                [np.array(roi_poly, np.int32)],
                True,
                (0, 255, 255),
                2,
            )
        for item in detections:
            x1, y1, x2, y2 = item["bbox"]
            cv2.rectangle(canvas, (x1, y1), (x2, y2), (0, 0, 255), 2)
            caption = f'{item["label"]} {item["conf"]:.2f}'
            cv2.putText(
                canvas,
                caption,
                (x1, max(12, y1 - 6)),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.5,
                (0, 0, 255),
                1,
                cv2.LINE_AA,
            )
        return canvas
