"""تحميل إعدادات ``config.yaml`` مع قيم افتراضية آمنة.

كل المسارات النسبية بتتحسب من فولدر ``vision_service`` نفسه، مش من مكان
تشغيل الأمر — عشان تشغيل الخدمة من Task Scheduler أو من أي فولدر تاني
يشتغل بنفس الشكل.
"""

from __future__ import annotations

import os
import re
from copy import deepcopy
from pathlib import Path

import yaml

DEFAULTS = {
    "camera": {
        "source": "0",
        "fps": 4.0,
        "reconnect_seconds": 5.0,
        "roi": [],
    },
    "model": {
        "weights": "yolo11n.pt",
        "conf_threshold": 0.55,
        "iou_threshold": 0.45,
        # 480 keeps a fridge product readable while running ~2× faster than 640
        # on a till with no GPU.
        "imgsz": 480,
        "labels": [],
    },
    # كاميرات المحل اللي بتتعرض في شبكة واحدة (زرار «كاميرات المحل»).
    # كل كاميرا: name + source (رابط RTSP أو رقم كاميرا USB) + roi اختياري.
    "shop": {"cameras": []},
    # ربط صنف الموديل (bottle / cup / ...) بأسماء المنتجات في PlayZone.
    "products": {},
    "pos": {
        "mode": "local",  # local | http | off
        "database": "",
        "check_window_seconds": 90,
        "base_url": "",
        "api_key": "",
    },
    "alerts": {
        "telegram": {"enabled": True, "bot_token": "", "chat_id": ""},
        "log_to_file": True,
        "cooldown_seconds": 180,
        "min_hits": 3,
        "evidence_dir": "logs/evidence",
    },
    "runtime": {
        "min_motion": 2.0,  # 0 = من غير فلتر حركة
        "save_sold": False,
    },
}

_ENV_DOLLAR = re.compile(r"\$\{([A-Za-z_][A-Za-z0-9_]*)\}|\$([A-Za-z_][A-Za-z0-9_]*)")
_ENV_PERCENT = re.compile(r"%([A-Za-z_][A-Za-z0-9_]*)%")


def _deep_merge(base, override):
    """دَمج متداخل: القيم اللي في الملف هي اللي تكسب."""
    merged = deepcopy(base)
    for key, value in (override or {}).items():
        if isinstance(value, dict) and isinstance(merged.get(key), dict):
            merged[key] = _deep_merge(merged[key], value)
        else:
            merged[key] = deepcopy(value)
    return merged


def _expand(value):
    """يستبدل ``$VAR`` / ``${VAR}`` / ``%VAR%`` بمتغيرات البيئة."""
    if isinstance(value, str):
        value = _ENV_DOLLAR.sub(
            lambda m: os.environ.get(m.group(1) or m.group(2), ""), value
        )
        value = _ENV_PERCENT.sub(lambda m: os.environ.get(m.group(1), ""), value)
        return value
    if isinstance(value, dict):
        return {key: _expand(item) for key, item in value.items()}
    if isinstance(value, list):
        return [_expand(item) for item in value]
    return value


def service_root() -> Path:
    """فولدر ``vision_service`` (أبو ``core``)."""
    return Path(__file__).resolve().parent.parent


def resolve_path(value: str | os.PathLike, base_dir: str | os.PathLike) -> str:
    path = Path(os.path.expanduser(str(value)))
    if not path.is_absolute():
        path = Path(base_dir) / path
    return str(path)


def default_database_path() -> str:
    appdata = os.environ.get("APPDATA")
    if not appdata:
        appdata = str(Path.home() / "AppData" / "Roaming")
    return str(Path(appdata) / "PlayZone" / "PlayZone" / "playzone.sqlite")


def _camera_source(value):
    """``"0"`` = أول كاميرا على الجهاز، أي حاجة تانية = مسار/URL زي ما هو."""
    if isinstance(value, int):
        return value
    text = str(value or "").strip()
    if text.isdigit():
        return int(text)
    return text


def load_env(base_dir: str | os.PathLike | None = None) -> None:
    """يقرا ``.env`` (بيانات الكاميرا/تليجرام) قبل توسيع المتغيرات."""
    env_file = Path(base_dir or service_root()) / ".env"
    if not env_file.exists():
        return
    try:
        from dotenv import load_dotenv
    except ImportError:
        return
    load_dotenv(env_file, override=False)


def load_config(path: str | None = None) -> dict:
    root = service_root()
    # لازم قبل _expand عشان ${CAM_USER} و ${CAM_PASS} يتلاقوا.
    load_env(root)
    config_path = Path(path) if path else None

    if config_path is None:
        for name in ("config.yaml", "config.example.yaml"):
            candidate = root / name
            if candidate.exists():
                config_path = candidate
                break

    data = {}
    if config_path is not None:
        if not config_path.exists():
            raise FileNotFoundError(f"ملف الإعدادات مش موجود: {config_path}")
        with open(config_path, "r", encoding="utf-8-sig") as handle:
            data = yaml.safe_load(handle) or {}
        if not isinstance(data, dict):
            raise ValueError(f"ملف الإعدادات لازم يكون قاموس YAML: {config_path}")

    cfg = _expand(_deep_merge(DEFAULTS, data))
    cfg["_base_dir"] = str(root)
    cfg["_config_path"] = str(config_path) if config_path else ""

    camera = cfg["camera"]
    camera["source"] = _camera_source(camera.get("source"))
    camera["fps"] = float(camera.get("fps") or 4.0)
    camera["reconnect_seconds"] = float(camera.get("reconnect_seconds") or 5.0)
    if isinstance(camera.get("roi"), list):
        camera["roi"] = [
            [int(point[0]), int(point[1])]
            for point in camera["roi"]
            if isinstance(point, (list, tuple)) and len(point) >= 2
        ]

    cameras = []
    for index, entry in enumerate(cfg.get("shop", {}).get("cameras") or [], start=1):
        if not isinstance(entry, dict):
            continue
        source = _camera_source(entry.get("source"))
        if source in ("", None):
            continue
        roi = entry.get("roi") or []
        cameras.append(
            {
                "name": str(entry.get("name") or f"Camera {index}").strip(),
                "source": source,
                "roi": [
                    [int(point[0]), int(point[1])]
                    for point in roi
                    if isinstance(point, (list, tuple)) and len(point) >= 2
                ],
                "reconnect_seconds": float(entry.get("reconnect_seconds") or 5.0),
            }
        )
    cfg["shop"]["cameras"] = cameras

    pos = cfg["pos"]
    pos["mode"] = str(pos.get("mode") or "local").strip().lower()
    pos["database"] = resolve_path(pos.get("database") or default_database_path(), root)
    pos["check_window_seconds"] = float(pos.get("check_window_seconds") or 90)

    alerts = cfg["alerts"]
    alerts["cooldown_seconds"] = float(alerts.get("cooldown_seconds") or 180)
    alerts["min_hits"] = max(1, int(alerts.get("min_hits") or 3))
    alerts["evidence_dir"] = resolve_path(
        alerts.get("evidence_dir") or "logs/evidence", root
    )

    return cfg
