from ultralytics import YOLO
import cv2
import numpy as np

class FridgeDetector:
    def __init__(self, weights, conf_thres=0.6, iou_thres=0.45):
        self.model = YOLO(weights)
        self.conf_thres = conf_thres
        self.iou_thres = iou_thres

    def detect(self, frame):
        results = self.model(frame, conf=self.conf_thres, iou=self.iou_thres, verbose=False)
        detections = []
        for r in results:
            if r.boxes is None:
                continue
            for box in r.boxes:
                cls_id = int(box.cls[0])
                label = self.model.names[cls_id]
                conf = float(box.conf[0])
                x1, y1, x2, y2 = map(int, box.xyxy[0])
                detections.append({
                    "label": label,
                    "conf": conf,
                    "bbox": (x1, y1, x2, y2)
                })
        return detections

    def is_inside_roi(self, bbox, roi_poly):
        if roi_poly is None or len(roi_poly) == 0:
            return True
        x1, y1, x2, y2 = bbox
        cx, cy = (x1 + x2) // 2, (y1 + y2) // 2
        pt = (cx, cy)
        roi_np = np.array(roi_poly, np.int32)
        return cv2.pointPolygonTest(roi_np, pt, False) >= 0
