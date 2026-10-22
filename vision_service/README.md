# PlayZone — خدمة رصد الثلاجة (Fridge Vision)

بتراقب كاميرا الثلاجة، تلاقي منتج اتاخد من منطقة الرصد، تتأكد إنه **مش**
مسجّل على كاشير PlayZone، وتبعت تنبيه تليجرام مع صورة الدليل.

**مهم:** الخدمة بتقرا `playzone.sqlite` **قراءة فقط**. مفيش أي كتابة أو تعديل
في بيانات الكافيه، ومفيش أي أمر بيتنفذ على الشاشات.

## التشغيل

```powershell
cd vision_service
py -3 -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt

copy config.example.yaml config.yaml
copy .env.example .env      # وحط TELEGRAM_BOT_TOKEN و TELEGRAM_CHAT_ID
notepad config.yaml         # كاميرا + ROI + ربط الأصناف
python main.py
```

أول تشغيل بينزّل أوزان `yolo11n.pt` (~6MB) — محتاج إنترنت مرة واحدة بس.

## الإعدادات المهمة

| الإعداد | معناه |
| --- | --- |
| `camera.source` | `0` لكاميرا USB، أو رابط `rtsp://...` للكاميرا IP |
| `camera.roi` | مضلّع منطقة الرف اللي بيتاخد منه المنتج (إحداثيات الصورة) |
| `camera.fps` | كام إطار يتعالج في الثانية (4 كافية جداً) |
| `products` | ربط صنف الموديل (`bottle`/`cup`) بأسماء المنتجات في قاعدة PlayZone |
| `pos.mode` | `local` (قاعدة PlayZone) أو `http` (نظام كاشير خارجي) أو `off` |
| `alerts.cooldown_seconds` | نفس المنتج ميتكررش قبل كده |
| `alerts.min_hits` | عدد إطارات التأكيد قبل التنبيه |

### اختيار الـROI

صوّر الكادر من الكاميرا الحقيقية، وافتح الصورة في Paint واقرأ إحداثيات
الأركان، وحطها في `camera.roi` بالترتيب. الـROI لازم يغطي الرف/فتحة
الثلاجة اللي الإيد بتدخل منها — مش الكادر كله — عشان التنبيهات متبقاش عشوائية.

### ربط الأصناف

الموديل بيعرف أصناف عامة (bottle, cup, sandwich...) والقاعدة فيها أسماء
عربية (مياه، بيبسي، شاي...). الربط في `products` هو اللي بيوصل الاتنين:

```yaml
products:
  bottle: [مياه, بيبسي, كولا, عصير]
  cup: [قهوة, شاي]
```

لو الصنف مش موجود في `products`، الخدمة بتدور على اسم الصنف نفسه.

## خيارات سطر الأوامر

```powershell
python main.py --dry-run              # من غير تليجرام (سجل + صور بس)
python main.py --show                 # نافذة معاينة، q للخروج
python main.py --video test.mp4 --once 200   # تجربة على فيديو
python main.py --verbose
```

## كاميرات المحل (زرار في البرنامج)

زرار **«كاميرات المحل»** في الشاشة الرئيسية بيفتح نافذة فيها كل الكاميرات
المعرّفة في `shop.cameras`، والموديل شغال على كل واحدة، والكاميرا اللي مش
واصلة بتظهر `OFFLINE` وتعيد المحاولة لوحدها.

1. حط بيانات الدخول في `.env` (مش في `config.yaml`):

   ```
   CAM_USER=admin
   CAM_PASS=......
   ```

2. عرّف الكاميرات:

   ```yaml
   shop:
     cameras:
       - name: "Camera 1"
         source: "rtsp://${CAM_USER}:${CAM_PASS}@192.168.1.2:554/Streaming/Channels/101"
   ```

3. من غير البرنامج:

   ```powershell
   python demo.py --shop
   ```

مسار Hikvision: `/Streaming/Channels/101` للقناة 1 و `/201` للقناة 2.
مسار Dahua: `/cam/realmonitor?channel=1&subtype=0`.

## الملفات الناتجة

- `logs/vision.log` — كل حاجة حصلت
- `logs/alerts.log` — التنبيهات بس
- `logs/evidence/*.jpg` — صورة الدليل مع المستطيلات والـROI

## ملاحظات تشغيل

- شغّلها في نافذة منفصلة أو Task Scheduler عند الدخول.
- لو الكاميرا قطعت، الخدمة بتعيد الاتصال لوحدها كل `reconnect_seconds`.
- `min_motion` بيمنع تشغيل الموديل على كادر ساكن — بيوفر معالج كتير.
- التنبيه معناه «فيه احتمال»: الكاميرا بتشوف الصنف، والكاشير هو اللي بيأكد.
