"""تنبيهات الثلاجة: تليجرام + سجل نصي محلي."""

from __future__ import annotations

import logging
import os
from datetime import datetime

try:
    import requests
except ImportError:  # pragma: no cover
    requests = None

LOG = logging.getLogger("vision.alerts")


class AlertManager:
    def __init__(self, config, base_dir="."):
        self.cfg = config or {}
        self.base_dir = str(base_dir)

    def _log_path(self) -> str:
        return os.path.join(self.base_dir, "logs", "alerts.log")

    def send(self, product, image_path=None, note=None):
        now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        lines = [
            "[PLAYZONE-FRIDGE-VISION]",
            "تنبيه: تم سحب منتج من الثلاجة ولم يُسجّل على الكاشير",
            f"المنتج: {product}",
        ]
        if note:
            lines.append(f"ملاحظة: {note}")
        lines += [
            f"الوقت: {now}",
            "يرجى المراجعة فوراً",
        ]
        message = "\n".join(lines)

        telegram = self.cfg.get("alerts", {}).get("telegram", {})
        if telegram.get("enabled"):
            token = os.getenv("TELEGRAM_BOT_TOKEN") or telegram.get("bot_token")
            chat_id = os.getenv("TELEGRAM_CHAT_ID") or telegram.get("chat_id")
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
                        LOG.warning(
                            "تليجرام رفض التنبيه (%s): %s",
                            response.status_code,
                            response.text[:200],
                        )
                except Exception as error:  # noqa: BLE001
                    LOG.warning("خطأ في إرسال تليجرام: %s", error)
            elif not (token and chat_id):
                LOG.warning(
                    "تنبيهات تليجرام مفعّلة بس الـtoken أو الـchat_id ناقص "
                    "(شوف .env) — التنبيه اتسجل في الملف بس"
                )

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
