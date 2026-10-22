"""تأكيد زمني للرصد ومنع تكرار التنبيه لنفس المنتج.

الموديل بيرصد كذا إطار في الثانية، والإيد اللي بتاخد منتج بتفضل في الصورة
أكتر من إطار. من غير الطبقة دي التليجرام هيتبعتله عشرات الرسائل في ثانية.
وكمان: المنتج اللي واقف على الرف مش المفروض ينبّه كل شوية — لازم يختفي
الأول (يتاخد) وبعدها يظهر تاني عشان يتسلّح من جديد.
"""

from __future__ import annotations

import time


class ZoneTracker:
    """يستقبل أصناف ظهرت جوه الـROI في الإطار الحالي، ويرجّع الأصناف اللي
    استحقت تنبيه في اللحظة دي.

    - ``min_hits``: عدد إطارات متتالية لازم الصنف يظهر فيها قبل التنبيه.
    - ``max_gap``: لو الصنف غاب أكتر من كده، الرصد الجديد يبدأ من أول وجديد.
    - ``cooldown``: أقصى تكرار للتنبيه لنفس الصنف (حتى لو اختفى ورجع).
    """

    def __init__(self, min_hits: int = 3, cooldown_seconds: float = 180.0,
                 max_gap_seconds: float = 3.0):
        self.min_hits = max(1, int(min_hits))
        self.cooldown = max(0.0, float(cooldown_seconds))
        self.max_gap = max(0.5, float(max_gap_seconds))
        self._state: dict[str, dict] = {}
        self._last_alert: dict[str, float] = {}

    def update(self, labels, now: float | None = None) -> list[str]:
        moment = time.monotonic() if now is None else float(now)
        fired: list[str] = []

        # أي صنف اختفى فترة كافية بيتمسح — لحظة رجوعه تبقى رصد جديد.
        for label in list(self._state):
            if moment - self._state[label]["last_seen"] > self.max_gap:
                del self._state[label]

        # ذاكرة الكولداون بتتمسح لوحدها بعد ما تنتهي.
        for label in list(self._last_alert):
            if moment - self._last_alert[label] > self.cooldown:
                del self._last_alert[label]

        for label in sorted({str(item) for item in labels if item}):
            state = self._state.get(label)
            if state is None:
                state = {"hits": 0, "last_seen": moment, "armed": True}
                self._state[label] = state

            state["hits"] += 1
            state["last_seen"] = moment

            # مش بننبّه تاني طول ما المنتج لسه ظاهر في نفس المكان: التنبيه
            # معناه "اتاخد"، فلازم يختفي الأول عشان يتسلّح من جديد.
            ready = state["hits"] >= self.min_hits and state["armed"]
            if ready and label not in self._last_alert:
                self._last_alert[label] = moment
                state["hits"] = 0
                state["armed"] = False
                fired.append(label)

        return fired

    def reset(self) -> None:
        self._state.clear()
        self._last_alert.clear()
