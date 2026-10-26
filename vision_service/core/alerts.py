"""تنبيهات الثلاجة: تليجرام + سجل نصي محلي + ملف JSON للبرنامج."""

from __future__ import annotations

import json
import logging
import os
from datetime import datetime
from pathlib import Path

try:
    import requests
except ImportError:  # pragma: no cover
    requests = None

LOG = logging.getLogger("vision.alerts")


class AlertManager:
    def __init__(self, config, base_dir="."):
        self.cfg = config or {}
        self.base_dir = str(base_dir)
        self.logs_dir = Path(self.base_dir) / "logs"
        try:
            self.logs_dir.mkdir(parents=True, exist_ok=True)
        except Exception:
            pass

    def _log_path(self) -> str:
        return os.path.join(self.base_dir, "logs", "alerts.log")

    def _jsonl_path(self) -> str:
        return os.path.join(self.base_dir, "logs", "alerts.jsonl")

    def _json_path(self) -> str:
        return os.path.join(self.base_dir, "logs", "alerts.json")

    def send(self, product, image_path=None, note=None, camera=None, person_id=None, event_type="fridge_unregistered"):
        now_iso = datetime.now().isoformat()
        now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        lines = [
            "[PLAYZONE-FRIDGE-VISION]",
            "تنبيه: تم سحب منتج من الثلاجة ولم يُسجّل على الكاشير",
            f"المنتج: {product}",
        ]
        if camera:
            lines.append(f"الكاميرا: {camera}")
        if note:
            lines.append(f"ملاحظة: {note}")
        lines += [
            f"الوقت: {now}",
            "يرجى المراجعة فوراً",
        ]
        message = "\n".join(lines)

        try:
            # ندمج كل الكاميرات في صورة واحدة عشان يظهر كل حاجة جنب بعض
            combo_path = None
            try:
                import cv2
                import numpy as np
                from pathlib import Path
                from .config import load_config, resolve_path
                from .detector import FridgeDetector
                from main import open_camera
                base_dir_cur = self.base_dir
                cfg_c = load_config(os.path.join(base_dir_cur, "config.yaml"))
                det_c = FridgeDetector(weights=resolve_path(cfg_c.get("model",{}).get("weights","yolo11m.pt"), base_dir_cur), conf_thres=0.12, iou_thres=0.4, keep_labels=['person','bottle','cup'], imgsz=512)
                def grab(src):
                    try:
                        cap=open_camera(src)
                        for _ in range(35): cap.grab()
                        ok,f=cap.read()
                        cap.release()
                        return f if ok else None
                    except:
                        return None
                cams = cfg_c.get("shop",{}).get("cameras") or []
                imgs=[]
                for c in cams:
                    src=c.get("source","")
                    f=grab(src)
                    if f is None: continue
                    try:
                        d=det_c.detect(f)
                        imgs.append(det_c.annotate(f,d,[]))
                    except:
                        imgs.append(f)
                if imgs:
                    h=max(x.shape[0] for x in imgs)
                    def rs(i):
                        if i.shape[0]==h: return i
                        sc=h/i.shape[0]; return cv2.resize(i,(int(i.shape[1]*sc),h))
                    out=np.hstack([rs(x) for x in imgs])
                    ev = Path(base_dir_cur)/"logs"/"evidence"
                    ev.mkdir(parents=True,exist_ok=True)
                    combo_path=str(ev/f"fridge_all_{int(datetime.now().timestamp())}.jpg")
                    cv2.imwrite(combo_path,out)
                    image_path = combo_path
            except Exception as e:
                LOG.warning("combo failed: %s",e)

            alert = {
                "id": f"al_{int(datetime.now().timestamp()*1000)}",
                "time": now_iso,
                "time_text": now,
                "type": event_type,
                "product": str(product),
                "camera": camera,
                "person_id": person_id,
                "note": note,
                "image_path": image_path,
                "read": False,
                "source": "vision_service",
            }
            jsonl_path = self._jsonl_path()
            with open(jsonl_path, "a", encoding="utf-8") as f:
                f.write(json.dumps(alert, ensure_ascii=False) + "\n")
            items = []
            try:
                if os.path.exists(jsonl_path):
                    with open(jsonl_path, "r", encoding="utf-8") as f:
                        for line in f:
                            line = line.strip()
                            if not line:
                                continue
                            try:
                                items.append(json.loads(line))
                            except Exception:
                                continue
            except Exception:
                items = []
            items = items[-100:]
            with open(self._json_path(), "w", encoding="utf-8") as f:
                json.dump(items, f, ensure_ascii=False, indent=2)
        except Exception as e:
            LOG.warning("مش قادر أكتب alerts.json: %s", e)

        if self.cfg.get("alerts", {}).get("telegram", {}).get("enabled"):
            token = os.getenv("TELEGRAM_BOT_TOKEN") or self.cfg.get("alerts", {}).get("telegram", {}).get("bot_token")
            chat_id = os.getenv("TELEGRAM_CHAT_ID") or self.cfg.get("alerts", {}).get("telegram", {}).get("chat_id")
            if token and chat_id and requests is not None:
                try:
                    if image_path and os.path.exists(image_path):
                        url = f"https://api.telegram.org/bot{token}/sendPhoto"
                        with open(image_path, "rb") as handle:
                            response = requests.post(
                                url,
                                data={"chat_id": chat_id, "caption": message},
                                files={"photo": handle},
                                timeout=10,
                            )
                    else:
                        url = f"https://api.telegram.org/bot{token}/sendMessage"
                        response = requests.post(
                            url,
                            data={"chat_id": chat_id, "text": message},
                            timeout=5,
                        )
                    if response.status_code >= 400:
                        LOG.warning("تليجرام رفض التنبيه (%s): %s", response.status_code, response.text[:200])
                except Exception as error:
                    LOG.warning("خطأ في إرسال تليجرام: %s", error)

        if self.cfg.get("alerts", {}).get("log_to_file", True):
            try:
                path = self._log_path()
                os.makedirs(os.path.dirname(path), exist_ok=True)
                with open(path, "a", encoding="utf-8") as handle:
                    handle.write(f"[{now}] {product} | لم يُسجّل على الكاشير")
                    if note:
                        handle.write(f" | {note}")
                    handle.write("\n")
            except OSError as error:
                LOG.warning("مش قادر أكتب سجل التنبيهات: %s", error)

        LOG.warning("تنبيه ثلاجة: %s%s", product, f" ({note})" if note else "")
        return message
