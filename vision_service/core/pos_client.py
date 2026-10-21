import requests
import time
import os

class PosClient:
    def __init__(self, base_url, api_key=None):
        self.base_url = base_url.rstrip('/') if base_url else ""
        self.api_key = api_key or os.getenv("POS_API_KEY", "")
        self.headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
            "Accept": "application/json"
        }

    def check_recent_sale(self, product_name, window_seconds=90):
        if not self.base_url:
            return False
        try:
            url = f"{self.base_url}/sales/recent"
            minutes = max(1, int(window_seconds / 60))
            resp = requests.get(url, headers=self.headers, params={"minutes": minutes, "limit": 100}, timeout=5)
            if resp.status_code != 200:
                return False
            data = resp.json()
            now = time.time()
            sales = data.get("sales") or data.get("data") or []
            for sale in sales:
                ts = sale.get("timestamp") or sale.get("created_at") or sale.get("time") or 0
                if isinstance(ts, str):
                    try:
                        from dateutil import parser
                        ts = parser.parse(ts).timestamp()
                    except:
                        continue
                if now - float(ts) > window_seconds:
                    continue
                items = sale.get("items") or []
                for it in items:
                    name = str(it.get("name", "")).lower()
                    if product_name.lower() in name or name in product_name.lower():
                        return True
            return False
        except Exception as e:
            print(f"[POS] خطأ في فحص المبيعات: {e}")
            return False
