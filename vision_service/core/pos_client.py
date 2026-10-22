"""فحص هل المنتج اللي اتاخد من الثلاجة اتسجّل على الكاشير ولا لأ.

الوضع الافتراضي ``local``: قراءة مباشرة (قراءة فقط) من قاعدة PlayZone
``playzone.sqlite`` — البرنامج مالوش HTTP API. مفيش أي كتابة في القاعدة.
"""

from __future__ import annotations

import logging
import os
import re
import sqlite3
import time
from datetime import datetime, timezone
from pathlib import Path

try:  # requests مطلوبة فقط لو الوضع http
    import requests
except ImportError:  # pragma: no cover
    requests = None

LOG = logging.getLogger("vision.pos")

_DIACRITICS = re.compile(r"[\u064B-\u0652\u0670\u0640]")
_NON_WORD = re.compile(r"[^\w\u0600-\u06FF]+", re.UNICODE)

_RECENT_ITEMS_SQL = """
SELECT ii.description, i.created_at, i.id
FROM invoice_items AS ii
JOIN invoices AS i ON i.id = ii.invoice_id
ORDER BY i.created_at DESC
LIMIT 400
"""


def normalize(text) -> str:
    """توحيد عربي/إنجليزي بسيط: همزات، تاء مربوطة، تشكيل، فواصل."""
    if text is None:
        return ""
    value = str(text).lower()
    value = _DIACRITICS.sub("", value)
    for source, target in (
        ("أ", "ا"),
        ("إ", "ا"),
        ("آ", "ا"),
        ("ى", "ي"),
        ("ؤ", "و"),
        ("ئ", "ي"),
        ("ة", "ه"),
        ("_", " "),
    ):
        value = value.replace(source, target)
    value = _NON_WORD.sub(" ", value)
    return " ".join(value.split())


def _to_epoch(value) -> float:
    """Drift ممكن يخزّن الوقت ثواني أو مللي ثانية أو نص ISO."""
    if value is None:
        return 0.0
    if isinstance(value, (int, float)):
        number = float(value)
        return number / 1000.0 if number > 1e11 else number
    text = str(value).strip()
    if not text:
        return 0.0
    if text.isdigit():
        return _to_epoch(int(text))
    try:
        parsed = datetime.fromisoformat(text.replace("Z", "+00:00"))
    except ValueError:
        return 0.0
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    return parsed.timestamp()


def _needles(product: str, aliases) -> list[str]:
    raw = [product] + list(aliases or [])
    seen, result = set(), []
    for item in raw:
        key = normalize(item)
        if len(key) >= 2 and key not in seen:
            seen.add(key)
            result.append(key)
    return result


def _matches(description: str, needles: list[str]) -> bool:
    text = normalize(description)
    if not text:
        return False
    for needle in needles:
        if needle in text:
            return True
        if len(needle) >= 3 and text in needle:
            return True
    return False


class PosClient:
    def __init__(self, config, base_dir="."):
        cfg = config or {}
        self.base_dir = str(base_dir)
        self.mode = str(cfg.get("mode") or "local").strip().lower()
        self.database = str(cfg.get("database") or "")
        self.base_url = str(cfg.get("base_url") or "").rstrip("/")
        self.api_key = cfg.get("api_key") or os.getenv("POS_API_KEY", "")
        self.window = float(cfg.get("check_window_seconds") or 90)
        self._warned_missing = False
        self._warned_error = False

    # ------------------------------------------------------------------ API

    def check_recent_sale(self, product, aliases=None, window_seconds=None):
        """يرجّع ``(تم البيع؟, وصف الصنف في الفاتورة)``."""
        window = float(window_seconds or self.window)
        if self.mode == "off":
            return False, None
        if self.mode == "http" and self.base_url:
            return self._check_http(product, aliases, window)
        return self._check_local(product, aliases, window)

    # ---------------------------------------------------------------- local

    def _connect(self):
        path = Path(self.database)
        uri = f"file:{path.resolve().as_posix()}?mode=ro"
        try:
            return sqlite3.connect(uri, uri=True, timeout=3.0)
        except sqlite3.Error:
            return sqlite3.connect(str(path), timeout=3.0)

    def _check_local(self, product, aliases, window):
        if not self.database or not Path(self.database).exists():
            if not self._warned_missing:
                LOG.warning(
                    "قاعدة PlayZone مش موجودة على المسار ده: %s — "
                    "فحص الكاشير متوقف لحد ما تظبطه في config.yaml",
                    self.database,
                )
                self._warned_missing = True
            return False, None

        needles = _needles(product, aliases)
        if not needles:
            return False, None

        try:
            with self._connect() as connection:
                rows = connection.execute(_RECENT_ITEMS_SQL).fetchall()
        except sqlite3.Error as error:
            if not self._warned_error:
                LOG.warning("مش قادر أقرا قاعدة PlayZone: %s", error)
                self._warned_error = True
            return False, None

        now = time.time()
        for description, created_at, invoice_id in rows:
            if now - _to_epoch(created_at) > window:
                continue
            if _matches(description, needles):
                LOG.info(
                    "المنتج '%s' مسجّل على الكاشير (فاتورة #%s: %s)",
                    product,
                    invoice_id,
                    description,
                )
                return True, str(description)
        return False, None

    # ----------------------------------------------------------------- http

    def _check_http(self, product, aliases, window):
        if requests is None:
            LOG.warning("مكتبة requests مش متسطّبة — فحص الكاشير عبر HTTP متوقف")
            return False, None
        minutes = max(1, int(window / 60))
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
            "Accept": "application/json",
        }
        stakes = _needles(product, aliases)
        try:
            response = requests.get(
                f"{self.base_url}/sales/recent",
                headers=headers,
                params={"minutes": minutes, "limit": 100},
                timeout=5,
            )
            if response.status_code != 200:
                return False, None
            payload = response.json()
            sales = payload.get("sales") or payload.get("data") or []
            now = time.time()
            for sale in sales:
                stamp = (
                    sale.get("timestamp")
                    or sale.get("created_at")
                    or sale.get("time")
                    or 0
                )
                if now - _to_epoch(stamp) > window:
                    continue
                for item in sale.get("items") or []:
                    name = str(item.get("name", ""))
                    if _matches(name, stakes):
                        return True, name
            return False, None
        except Exception as error:  # noqa: BLE001 - الخدمة لازم تفضل شغالة
            LOG.warning("خطأ في فحص مبيعات الكاشير: %s", error)
            return False, None
