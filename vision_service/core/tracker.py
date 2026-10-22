"""تأكيد زمني للرصد ومنع تكرار التنبيه لنفس المنتج.

الموديل بيرصد كذا إطار في الثانية، والإيد اللي بتاخد منتج بتفضل في الصورة
أكتر من إطار. من غير الطبقة دي التليجرام هيتبعتله عشرات الرسائل في ثانية.
"""

from __future__ import annotations

import time


class ZoneTracker:
    """يستقبل أصناف ظهرت جوه الـROI في الإطار الحالي، ويرجّع الأصناف اللي
    استحقت تنبيه في اللحظة دي.

    - ``min_hits``: عدد إطارات متتالية لازم الصنف يظهر فيها قبل التنبيه.
    - ``max_gap``: لو الصنف غاب أكتر من كده، العدّاد يبدأ من أول وجديد.
    - ``cooldown``: أقصى تكرار للتنبيه لنفس الصنف.
    """

    def __init__(self, min_hits: int = 3, cooldown_seconds: float = 180.0,
                 max_gap_seconds: float = 3.0):
        self.min_hits = max(1, int(min_hits))
        self.cooldown = max(0.0, float(cooldown_seconds))
        self.max_gap = max(0.5, float(max_gap_seconds))
        self._state: dict[str, dict] = {}

    def update(self, labels, now: float | None = None) -> list[str]:
        moment = time.monotonic() if now is None else float(now)
        fired: list[str] = []

        # أي صنف اختفى فترة كافية بيتمسح — لحظة رجوعه تبقى رصد جديد.
        for label in list(self._state):
            if moment - self._state[label]["last_seen"] > self.max_gap:
                del self._state[label]

        for label in sorted({str(item) for item in labels if item}):
            state = self._state.get(label)
            if state is None:
                state = {"hits": 0, "last_seen": moment, "last_alert": None}
                self._state[label] = state

            state["hits"] += 1
            state["last_seen"] = moment

            ready = state["hits"] >= self.min_hits
            cooled = (
                state["last_alert"] is None
                or (moment - state["last_alert"]) >= self.cooldown
            )
            if ready and cooled:
                state["last_alert"] = moment
                state["hits"] = 0
                fired.append(label)

        return fired

    def reset(self) -> None:
        self._state.clear()
