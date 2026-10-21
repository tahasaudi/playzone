import requests
import os
from datetime import datetime

class AlertManager:
    def __init__(self, config):
        self.cfg = config

    def send(self, product, image_path=None):
        now = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        msg = f"[PLAYZONE-FRIDGE-VISION]\nتنبيه: تم سحب منتج من الثلاجة ولم يُسجّل on الكاشير\nالمنتج: {product}\nالوقت: {now}\nيرجى المراجعة فوراً"
        
        tg = self.cfg.get('alerts', {}).get('telegram', {})
        if tg.get('enabled'):
            token = os.getenv('TELEGRAM_BOT_TOKEN') or tg.get('bot_token')
            chat_id = os.getenv('TELEGRAM_CHAT_ID') or tg.get('chat_id')
            if token and chat_id:
                try:
                    if image_path and os.path.exists(image_path):
                        url = f"https://api.telegram.org/bot{token}/sendPhoto"
                        with open(image_path, 'rb') as f:
                            requests.post(url, data={"chat_id": chat_id, "caption": msg}, files={"photo": f}, timeout=10)
                    else:
                        url = f"https://api.telegram.org/bot{token}/sendMessage"
                        requests.post(url, data={"chat_id": chat_id, "text": msg}, timeout=5)
                except Exception as e:
                    print(f"[ALERT] خطأ في إرسال تليجرام: {e}")

        if self.cfg.get('alerts', {}).get('log_to_file', True):
            os.makedirs('logs', exist_ok=True)
            with open('logs/alerts.log', 'a', encoding='utf-8') as f:
                f.write(f"[{now}] {product} | لم يُسجّل on الكاشير\n")

        print(msg)
