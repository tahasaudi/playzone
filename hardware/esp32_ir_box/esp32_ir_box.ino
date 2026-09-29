/*
 * PlayZone — IR Command Box (ESP32)
 * =================================
 * محطة أوامر تحت بالبوري بيحوله السيستم (البنك) لأوامر IR للشاشات.
 *
 * القطع:
 *   - بورد ESP32 (أي نوع — أفضل DevKit v1)
 *   - LED باعث IR (مثلا TSAL6200 / IR333)  + مقاومة 100Ω
 *   - (اختياري للتعلم/الحفظ) مستقبل IR مثل VS1838B على نفس الخط
 *
 * التوصيل:
 *   - باعث IR (الـ Anode عبر المقاومة)   -> GPIO4
 *   - مستقبل IR OUT (اختياري)            -> GPIO5
 *   - VIN/GND من مزود 5V أو من نفس مصدر الشاشة
 *
 * قبل الرفع (Flash) عدِّل السطرين التاليين بشبكة المحل:
 *   WIFI_SSID / WIFI_PASS
 *
 * بعد التشغيل افتح الرقم (IP) اللي يظهر في Serial Monitor من أي متصفح:
 *
 *   /            صفحة الحالة مع أزرار learn/send لكل صوت
 *   /api/liveness  {"ok":true}  ← بيستخدمه السيستم لفحص الاتصال
 *   /api/learn?slot=power       ← يبقي في وضع التعلم 15 ثانية:
 *                                وجّه ريموت الشاشة اضغط الزر المطلوب.
 *   /api/send?slot=power        ← يبعت الإشارة المحفوظة للشاشة
 *
 * فلوب الاستخدام في المحل:
 *   1) علّم صوت "power" من ريموت الشاشة (learn).
 *   2) علّم صوت "input1" (اختياري) — التحويل لمدخل البلايستيشن.
 *   3) باقي الحتة تلقائية: السيستم يبعت /api/send?slot=power
 *      مع بدء الجلسة (شغّل) ووقت التحصيل (أطفئ).
 *
 * المكتبة المطلوبة من Library Manager (Arduino IDE):
 *   IRremoteESP8266   (v2.8.x)  — باسمها الشائع "IRremoteESP8266"
 *   ArduinoJson       (v6.x)
 *   + محمّل "ESP32 by Espressif" من Board Manager.
 */

#include <WiFi.h>
#include <WebServer.h>
#include <ArduinoJson.h>
#include <LittleFS.h>
#include <IRremoteESP8266.h>
#include <IRsend.h>
#include <IRrecv.h>
#include <IRutils.h>

// ===================== إعدادات الشبكة (عدّلها) =====================
const char* WIFI_SSID = "PLAYZONE_NET";  // اسم شبكة المحل
const char* WIFI_PASS = "12345678";      // باسورد الشبكة
// لو الشبكة ثابتة ومش Dynamic، ضع IP هنا وعطّل السطر التالي
// (IPAddress _net(192, 168, 1, 50), _gw(192, 168, 1, 1), _sn(255, 255, 255, 0));
// ==================================================================

const uint16_t kIrLedPin = 4;   // GPIO4 — باعث IR للشاشة
const uint16_t kRecvPin  = 5;   // GPIO5 — مستقبل IR (للتعلم)

const uint16_t kLearnTimeoutMs = 15000;  // مدة التعلم لكل زرا

const char* SLOTS_FILE = "/slots.json";  // التخزين في LittleFS

IRsend irsend(kIrLedPin);
IRrecv irrecv(kRecvPin);
decode_results irResult;

WebServer server(80);

// اسم الصوت اللي بيتعلّم دلوقتي، أو فارغ لو مش في وضع التعلم
String learningSlot = "";
unsigned long learnDeadline = 0;

// ---------------- تخزين الأصوات ----------------

struct IrSlot {
  int    protocol = 0;  // decode_type_t (كعدد)
  uint16_t bits   = 0;
  uint64_t value  = 0;
};

// يحمّل بصوت بالاسم، يرجع true لو موجود
bool slotExists(String name) {
  if (!LittleFS.exists(SLOTS_FILE)) return false;
  File f = LittleFS.open(SLOTS_FILE, "r");
  if (!f) return false;
  DynamicJsonDocument doc(4096);
  deserializeJson(doc, f);
  f.close();
  return doc["slots"][name].is<JsonObject>();
}

// بيحفظ الصوت بعد التعلم
void saveSlot(String name, IrSlot s) {
  DynamicJsonDocument doc(4096);
  if (LittleFS.exists(SLOTS_FILE)) {
    File f = LittleFS.open(SLOTS_FILE, "r");
    if (f) {
      deserializeJson(doc, f);
      f.close();
    }
  }
  JsonObject slot = doc["slots"][name].to<JsonObject>();
  slot["p"] = s.protocol;
  slot["b"] = s.bits;
  slot["v"] = (unsigned long long)s.value;
  File out = LittleFS.open(SLOTS_FILE, "w");
  serializeJson(doc, out);
  out.close();
}

// بيقرا الصوت ويبعت إشارته
bool sendSlot(String name) {
  if (!LittleFS.exists(SLOTS_FILE)) return false;
  File f = LittleFS.open(SLOTS_FILE, "r");
  if (!f) return false;
  DynamicJsonDocument doc(4096);
  deserializeJson(doc, f);
  f.close();
  JsonObject slot = doc["slots"][name].as<JsonObject>();
  if (slot.isNull()) return false;
  IrSlot s;
  s.protocol = slot["p"] | 0;
  s.bits     = slot["b"] | 0;
  s.value    = (uint64_t)(slot["v"] | 0ULL);
  if (s.bits == 0) return false;

  // إيقاف الاستقبال أثناء الإرسال حتى ما يتسجلش الأشعة بتاعته
  irrecv.disableIRIn();
  irsend.send((decode_type_t)s.protocol, s.value, s.bits);
  irrecv.enableIRIn();
  return true;
}

// ---------------- HTTP ----------------

void handleLiveness() {
  server.send(200, "application/json", "{\"ok\":true}");
}

void handleState() {
  DynamicJsonDocument doc(2048);
  doc["ip"] = WiFi.localIP().toString();
  JsonArray slots = doc["slots"].to<JsonArray>();
  if (LittleFS.exists(SLOTS_FILE)) {
    File f = LittleFS.open(SLOTS_FILE, "r");
    if (f) {
      DynamicJsonDocument tmp(4096);
      deserializeJson(tmp, f);
      f.close();
      for (JsonPair kv : tmp["slots"].as<JsonObject>())
        slots.add(kv.key().c_str());
    }
  }
  String out;
  serializeJson(doc, out);
  server.send(200, "application/json", out);
}

void handleLearn() {
  learningSlot = server.hasArg("slot") ? server.arg("slot") : "";
  if (learningSlot.isEmpty()) {
    server.send(400, "text/plain", "missing slot");
    return;
  }
  learnDeadline = millis() + kLearnTimeoutMs;
  server.send(200, "text/plain", "learning slot: " + learningSlot +
    " (وجّه الريموت واضغط الزر خلال 15 ثانية)");
}

void handleSend() {
  String slot = server.hasArg("slot") ? server.arg("slot") : "";
  if (slot.isEmpty()) { server.send(400, "text/plain", "missing slot"); return; }
  if (sendSlot(slot)) {
    server.send(200, "text/plain", "sent " + slot);
  } else {
    server.send(404, "text/plain", "no saved IR for slot: " + slot);
  }
}

void handleRoot() {
  String html = String("") +
    "<!doctype html><html dir='rtl'><head><meta charset='utf-8'>"
    "<title>PlayZone IR Box</title><style>"
    "body{font-family:Tahoma;background:#12102a;color:#eee;padding:24px;max-width:640px;margin:auto}"
    "h1{color:#b98cff} .slot{background:#1e1b3d;border:1px solid #3a3560;border-radius:10px;"
    "padding:14px;margin:10px 0} input{padding:8px;border-radius:6px;border:0;width:200px}"
    "button{background:#7c5cff;color:#fff;border:0;padding:8px 14px;border-radius:6px;cursor:pointer;margin:4px}"
    "</style></head><body><h1>صندوق أوامر البلايستيشن</h1>"
    "<p>IP: <b>" + WiFi.localIP().toString() + "</b></p>"
    "<p>علّم صوت جديد: أدخل اسم مثل <code>power</code> أو <code>input1</code>.</p>"
    "<div class='slot'><b>تعلم صوت</b><br><input id='n' placeholder='power'> "
    "<button onclick=fetch('/api/learn?slot='+encodeURIComponent(n.value))>تعلم 15 ثا</button></div>"
    "<div class='slot'><b>أصوات محفوظة</b><br><span id='slots'></span>"
    "<script>fetch('/api/state').then(r=>r.json()).then(d=>{"
    "document.getElementById('slots').innerHTML=d.slots.join(', ')||'لا يوجد';})"
    "</script></div></body></html>";
  server.send(200, "text/html", html);
}

void setupRoutes() {
  server.on("/", handleRoot);
  server.on("/api/liveness", handleLiveness);
  server.on("/api/state", handleState);
  server.on("/api/learn", handleLearn);
  server.on("/api/send", handleSend);
  server.begin();
}

// ---------------- ثابت ----------------

void setup() {
  Serial.begin(115200);
  delay(200);

  if (!LittleFS.begin(true)) {
    Serial.println("LittleFS mount failed!");
  }

  irsend.begin();
  irrecv.enableIRIn();

  WiFi.mode(WIFI_STA);
  WiFi.setSleep(false);
  // لو الشبكة ثابتة فعّلت الأسطر:  (المرة)
  // WiFi.config(_net, _gw, _sn);
  WiFi.begin(WIFI_SSID, WIFI_PASS);

  int tries = 0;
  while (WiFi.status() != WL_CONNECTED && tries < 60) {
    delay(500);
    tries++;
  }
  if (WiFi.status() == WL_CONNECTED) {
    Serial.print("IP: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("WiFi failed — start AP? (check SSID/PASS)");
  }

  setupRoutes();
}

void loop() {
  // إعادة الاتصال لو انقطع النت
  if (WiFi.status() != WL_CONNECTED) {
    WiFi.reconnect();
    delay(2000);
    return;
  }

  // التعلم: استقبل الإشارة وحفظها في الصوت المطلوب
  if (!learningSlot.isEmpty() && irrecv.decode(&irResult)) {
    if (millis() <= learnDeadline) {
      IrSlot s;
      s.protocol = irResult.decode_type;
      s.bits     = irResult.bits;
      s.value    = irResult.value;
      saveSlot(learningSlot, s);
      Serial.printf("Learned '%s': proto=%d bits=%d val=0x%08X%08X\n",
        learningSlot.c_str(), s.protocol, s.bits,
        (unsigned)(s.value >> 32), (unsigned)s.value);
      learningSlot = "";
    }
    irrecv.resume();
  } else if (!learningSlot.isEmpty() && millis() > learnDeadline) {
    Serial.println("Learn timeout");
    learningSlot = "";
  }

  server.handleClient();
}