# PlayZone — المستند التفصيلي الكامل (نسخة محدّثة شاملة)

هذا المستند هو "مصدر الحقيقة" (Source of Truth) لكل حاجة اتقررت واتبنت في المشروع لحد دلوقتي. نسخة محدّثة من البرومبت الأصلي بكل القرارات الفعلية والتفاصيل التقنية.

---

## 1. نظرة عامة على المشروع

- **الاسم**: PlayZone
- **النوع**: نظام إدارة كافيه بلايستيشن + بلياردو (Flutter Windows Desktop)
- **الهوية البصرية**: Dark Purple Glassmorphism — خلفية شبه سوداء بنفسجية، كروت زجاجية شفافة، توهج بنفسجي خفيف
- **الأولوية**: السرعة والوضوح للكاشير قبل أي زخرفة بصرية
- **اللغة**: عربي بالكامل، RTL

---

## 2. الستاك التقني (Confirmed Stack)

| الطبقة | التقنية |
|---|---|
| الواجهة | Flutter Desktop (Windows) |
| إدارة الحالة | Riverpod (`flutter_riverpod`) |
| قاعدة البيانات | Drift + SQLite *(الموديل لسه معمول ليه بس مش متوصّل فعليًا — بيانات mock حاليًا)* |
| الخطوط | Google Fonts — Tajawal (عربي) |
| الأيقونات | Material Symbols Rounded |
| الشارتات | مفيش مكتبة خارجية — اتعمل شارت بسيط بالكود (`MiniBarChart`, `ComparisonBar`) عشان نفضل خفيفين على الديبندنسيز |

> ملحوظة: الستاك ده مختلف عن مشاريعك التانية (real-estate app, RxPharm) اللي شغالة بـ GetX + Hive. القرار كان نكمل بنفس ستاك البرومبت الأصلي.

---

## 3. نظام التصميم (Design System)

### الألوان (`AppColors`)
```
bgBase              = #0B0713   خلفية أساسية شبه سودة بنفسجية
bgElevated          = #130D1F   خلفية الـ sidebar/topbar
bgGlow              = #3B1E66   مصدر التوهج الخلفي
glassFill           = white 10%
glassFillStrong     = white 15%  (hover)
glassBorder         = white 20%
glassBorderPurple   = purple 30% (active/focus)
accentPrimary       = #9333EA
accentSecondary     = #C084FC
statusAvailable     = #22C55E (أخضر)
statusActive        = #EF4444 (أحمر — الجهاز شغّال)
statusPaused        = #F59E0B (أصفر)
statusMaintenance   = #6B7280 (رمادي)
```

### المسافات (`AppSpacing`)
```
xs=4  sm=8  md=16  lg=24  xl=32  xxl=48
sidebarWidth = 260px
topBarHeight = 72px
```

### الراديوس (`AppRadius`)
```
small=10  medium=15  large=22  hero=26
```

### الخطوط (`AppTypography`)
```
pageTitle     = 30px / bold
sectionTitle  = 22px / semi-bold
cardTitle     = 16px / semi-bold
body          = 14px / regular
secondary     = 12px / regular، لون خافت
numberLarge   = 34px / bold (أرقام الـ KPI)
timer         = 40px / bold، tabular figures (التايمر الحي)
```

---

## 4. الكومبوننتس الجاهزة (Reusable Widgets)

| الكومبوننت | الملف | الوظيفة |
|---|---|---|
| `GlassCard` | `core/widgets/glass_card.dart` | السطح الزجاجي الأساسي — hover, blur, border, shadow |
| `PrimaryButton` | `core/widgets/app_buttons.dart` | زرار التدرج البنفسجي — للأكشن الأهم في الشاشة |
| `SecondaryButton` | `core/widgets/app_buttons.dart` | زرار زجاجي شفاف — للأكشنز الثانوية |
| `StatusBadge` | `core/widgets/status_badge.dart` | badge بلون + أيقونة + نص (Accessibility) |
| `MiniBarChart` | `core/widgets/mini_bar_chart.dart` | شارت أعمدة بسيط بدون مكتبات خارجية |
| `ComparisonBar` | `core/widgets/mini_bar_chart.dart` | شريط مقارنة بين قيمتين (زي ألعاب ضد كافيه) |

كل الأزرار بتستخدم `Flexible` + `TextOverflow.ellipsis` للنص جوّاها عشان تتحمّل المساحات الضيقة (زي 3 أزرار جنب بعض في كارت الجهاز) من غير overflow errors.

---

## 5. نظام الصلاحيات (Roles & Permissions)

**3 أدوار:**

| الدور | يفتح جلسة/يبيع | يعمل خصم | يشوف التقارير | يغيّر الأسعار | يدير المستخدمين |
|---|:---:|:---:|:---:|:---:|:---:|
| **أدمن** (`admin`) | ✅ | ✅ | ✅ | ✅ | ✅ |
| **مشرف شيفت** (`shiftSupervisor`) | ✅ | ✅ | ✅ | ❌ | ❌ |
| **كاشير** (`cashier`) | ✅ | ✅ | ❌ | ❌ | ❌ |

> صلاحيات "مشرف الشيفت" افتراض منطقي (أنت حددت الكاشير بالتفصيل بس) — قابل للتعديل.

**آلية العمل:**
- الملف: `core/auth/role_provider.dart`
- الشاشات المحمية: `settings`، `reports`/`statistics`/`audit`، `employees`
- الـ Sidebar بتظهر العنصر بأيقونة 🔒 وتمنع الدخول لو الدور مش مصرّح له
- **مؤقتًا**: فيه dropdown في الـ TopBar لتبديل الدور يدويًا للتجربة (لحد ما تتبني شاشة تسجيل الدخول الحقيقية بالـ PIN)

---

## 6. نظام التسعير (Pricing Engine)

القاعدة: **أنت اللي بتحدد الأسعار من شاشة الإعدادات، مفيش أسعار ثابتة في الكود.**

### 3 مستويات تسعير (Settings → 3 تابات):

1. **سعر افتراضي لكل نوع جهاز** — PS4, PS5, بلياردو, VIP
2. **سعر مخصص لكل جهاز بمفرده** — مثال: PS5 #01 بسعر مختلف عن PS5 #03 (لو الخانة فاضية، بياخد سعر نوعه الافتراضي)
3. **سعر كل منتج كافيه** — قابل للتعديل، وله كمان **سعر تكلفة (cost price)** لحساب الربح في شاشة المخزون

### آلية الحساب — بالدقيقة:

```dart
تكلفة الجلسة = (سعر_الساعة / 60) × عدد_الدقائق_الفعلية

// مثال: PS5 بسعر 30 جنيه/ساعة، الجلسة 25 دقيقة
// التكلفة = (30 / 60) × 25 = 12.5 جنيه — بدون تقريب لساعة كاملة
```

الملف: `core/pricing/pricing_provider.dart`
- `DevicePricing.hourlyRateFor(type, name)` → السعر الفعلي (override أو افتراضي)
- `DevicePricing.costForMinutes(...)` → حساب تكلفة الجلسة
- `ProductPriceEntry` → له `price`, `costPrice`, `stock`, `profit` (محسوب), `isLowStock`, `isOutOfStock`

> ⚠️ التايمر الحي والحساب الفعلي لسه شغالين على بيانات وهمية — الربط الحقيقي بالجلسات هيحصل مع قاعدة البيانات.

---

## 7. الشاشات المبنية فعليًا (Done)

| الشاشة | الوصف | الملف |
|---|---|---|
| **Dashboard** | Hero card + 6 KPI cards + شبكة أجهزة حية (بيانات وهمية) | `features/dashboard/` |
| **Device Card** | 4 حالات: متاح / شغّال / موقّف / صيانة | `features/devices/device_card.dart` |
| **Session Details Panel** | بانل جانبي يفتح بالضغط على جهاز شغّال/موقّف | `features/devices/session_details_panel.dart` |
| **Checkout Modal** | مودال إقفال الجلسة مع طريقة الدفع | `features/devices/checkout_modal.dart` |
| **POS (الكاشير)** | كاتيجوريز + شبكة منتجات + سلة تفاعلية، أسعار حية من الإعدادات | `features/pos/pos_screen.dart` |
| **Settings → Pricing** | 3 تابات: أنواع الأجهزة / أجهزة منفردة / منتجات الكافيه | `features/settings/pricing_settings_screen.dart` |
| **Inventory** | 4 KPI cards + جدول كامل (تكلفة، سعر بيع، ربح، حالة المخزون) | `features/inventory/inventory_screen.dart` |
| **Reports** | فلاتر زمنية، 5 KPI cards، شارت إيرادات، ألعاب ضد كافيه، الأكثر مبيعًا، أكثر الساعات ازدحامًا، استخدام الأجهزة | `features/reports/reports_screen.dart` |
| **Sidebar + TopBar + Shell** | تنقّل كامل مع الصلاحيات + مبدّل دور مؤقت | `features/shell/` |

## 8. الشاشات الناقصة (من قائمة الـ 23 شاشة الأصلية)

- Login / PIN Entry
- New Session (بدء جلسة تفصيلي)
- Quick Sale
- ~~إدارة المنتجات نفسها (إضافة/حذف منتج، مش بس تعديل سعره)~~ ✅ بقت مبنية في شاشة **المخزون** (إضافة/تعديل/حذف منتج + إضافة/تعديل/حذف تصنيف) — مربوطة بقاعدة البيانات، للسوبيرفايزر بتاع الأسعار بس (أدمن) ومسجّلة في سجل المراجعة
- Stock Adjustment (تسوية المخزون يدويًا)
- Employees management (إدارة فعلية للموظفين، مش الصلاحيات بس)
- Shifts + Shift Closing (شاشة الشيفت والإقفال الموجّه بالخطوات)
- Expenses
- Invoices + Invoice Details
- Statistics / Analytics (منفصلة عن Reports حسب القائمة الأصلية)
- Audit Logs
- Backup & Restore

## 9. طبقة البيانات (لسه ناقصة بالكامل)

- جداول Drift: Devices, Sessions, Products, Orders, Invoices, Employees, Shifts
- التايمر الحي الفعلي (Stream بيحدّث كل ثانية)
- حفظ دائم للأسعار والصلاحيات (دلوقتي كله في الذاكرة وبيتصفر عند إعادة التشغيل)
- شاشة تسجيل الدخول الحقيقية اللي بتحدد دور المستخدم بدل الـ dropdown المؤقت

---

## 10. هيكل الملفات الحالي (كامل)

```
lib/
├── main.dart
├── core/
│   ├── auth/
│   │   └── role_provider.dart          # 3 أدوار + الصلاحيات
│   ├── pricing/
│   │   └── pricing_provider.dart       # أسعار الأجهزة/المنتجات + حساب بالدقيقة
│   ├── theme/
│   │   ├── app_colors.dart
│   │   ├── app_tokens.dart             # spacing, radius, typography, shadows
│   │   └── app_theme.dart
│   └── widgets/
│       ├── glass_card.dart
│       ├── status_badge.dart
│       ├── app_buttons.dart            # Primary/Secondary buttons
│       └── mini_bar_chart.dart         # شارت بسيط بدون مكتبة خارجية
└── features/
    ├── shell/
    │   ├── app_shell.dart              # يوجّه الراوت + يحمي الصلاحيات
    │   ├── sidebar.dart
    │   └── top_bar.dart                # فيه مبدّل الدور المؤقت
    ├── dashboard/
    │   ├── dashboard_screen.dart
    │   └── hero_and_kpi.dart
    ├── devices/
    │   ├── device_card.dart
    │   ├── session_details_panel.dart
    │   └── checkout_modal.dart
    ├── pos/
    │   └── pos_screen.dart
    ├── settings/
    │   └── pricing_settings_screen.dart
    ├── inventory/
    │   └── inventory_screen.dart
    └── reports/
        └── reports_screen.dart
```

---

## 11. أخطاء اتصلحت (Log)

- **RenderFlex overflow** في `PrimaryButton`/`SecondaryButton`: النص كان بيطلع بره حدود الزرار في المساحات الضيقة (3 أزرار جنب بعض). الحل: `Flexible` + `ellipsis`، وتقليل الـ padding الأفقي.
- **RenderFlex overflow (bottom)** في `DeviceCard` الحالة النشطة: المحتوى كان أطول من مساحة الكارت. الحل: تقليل المسافات الداخلية، وتكبير ارتفاع خلية الشبكة (`childAspectRatio` من 0.95 لـ 0.72).

---

## 12. القرارات المعلّقة (تحتاج تأكيدك)

1. صلاحيات "مشرف الشيفت" بالظبط (افترضت إنه زي الأدمن في التقارير بس مش في الأسعار/المستخدمين)
2. صورة تصميم مرجعية جديدة (لسه ماوصلتش غير الـ Apple Music الأولى)
3. الأولوية بعد باقي الشاشات: قاعدة البيانات الحقيقية، ولا شاشة تسجيل الدخول؟

---

## 13. سجل القرارات الزمني (Decision Log)

1. الستاك: Riverpod + Drift + SQLite (بدل GetX + Hive المستخدم في مشاريعك التانية)
2. البناء على مراحل بدل ملف واحد ضخم — Design System أولًا، بعدين Shell، بعدين كل شاشة لوحدها
3. الأسعار admin-editable بالكامل، مفيش رقم ثابت في الكود
4. التسعير على 3 مستويات (نوع/جهاز منفرد/منتج) والحساب بالدقيقة مش بالساعة الكاملة
5. 3 أدوار صلاحيات (أدمن/مشرف شيفت/كاشير) بدل دورين بس
6. الأولوية بعد الإعدادات والصلاحيات: باقي الشاشات (Inventory, Reports) قبل قاعدة البيانات وشاشة تسجيل الدخول

---

## 14. تحديث 2026-09-26 — جلسات بمدة ثابتة + إصلاح الجرد + تصحيح الأجهزة

**جلسات المدة السريعة (الشاشة الرئيسية)**
- شريط اختيار المدة فوق الكروت: **60 / 30 / 15 / 7 دقيقة** + "مفتوحة" (تحسب بالدقيقة لحد ما تقفلها).
- عمودين جديدين في `sessions`: `planned_minutes` و `time_up_at`.
- الفوترة **مقفولة** عند `time_up_at` (`_freezeCurrentSegment` + `liveCost` بيقصوصوا الزمن)، يعني مستحيل يتحسب أكثر من الدقائق اللي اتبعت.
- `timeUpWatcherProvider` (كل 5 ثواني) بيقلب الجلسة نفسها لـ `timeup` عند انتهاء الوقت: **التحصيل بيقف** والجهاز بيتحرر لوحده.
- حالة جديدة `timeup` في `DeviceStatus`: الكارت في صف "انتظار" بيقول "انتهى الوقت" ومعاه زرارين: **تحصيل** (للفاتورة) و **＋ وقت** (يمدّد المدة ويكمّل اللعب، لو الدutton المدة محدد).
- الإيقاف المؤقت (Pause) **بيدفع** `time_up_at` قدام بقدار وقت الإيقاف، عشان الإيقاف ماياكلشش الدقائق المدفوعة.

**ترتيب صف الانتظار (FIFO)**
- `SessionDao.watchLastFinishedByDevice()` بيرجّع وقت انتهاء آخر جلسة لكل جهاز، وصف "انتظار" بيترتّب **الأولوية لللي خلص وقته الأول** (واللي معرّفش ليه جلسة بيروحوا آخر الصف).
- `SessionDao.timeUp()` بيكتب `endTime = time_up_at` عشان الترتيب يبقى عادل حتى مع الأجهزة اللي خلصت في نفس اللحظة.

**تصغير وضغط الواجهات**
- `DeviceCard` بقى له وضع `compact`: paddings أصغر، تايمر 24px، أزرار مختصرة، و6 أجهزة في الصف بدل 4. `childAspectRatio` من 0.72 لـ **1.05**.
- الشاشة الرئيسية اتقسمت لـ 3 صفوف: **شغّال / انتظار / صيانة**.
- الكاشير: شريط **سيرش** للمنتجات (يدور في كل التصنيفات)، شبكة 4 أعمدة، صندوق السلة اتنقص من 320 لـ **230**، وإجمالي واحد بدل اتنين.
- `SessionDetailsPanel`: من 380 لـ **320** عرض، `maxHeight: 520`، `Clip.antiAlias`، و`SingleChildScrollView` — ده اللي كان بيعمل الشرائط الصفراء (RenderFlex overflow) والبياض اللي كان بيخرج من الحواف المدورة.

**إصلاح الجرد الدوري (مشكلة حقيقية)**
- السبب: `applyCount` كان بيكتب `countedQty` لكل صف، وكل صف未被 العد كان قيمته 0 → **كل المنتجات التانية بتروح صفر**.
- الحل: عمود `counted` (bool) في `stock_count_items`. الصف بيبقى "غير معدود" لحد ما الكاشير يكتب رقم فيه، والاعتماد بيكتب **الصفوف المعدودة فقط** والباقي بيفضل زي ما هو.
- `_CountRow` بقى widget مستقل (كان بيعمل `TextEditingController` + `FocusNode` في `itemBuilder` بيتسرّب مع كل rebuild).
- اتضاف **سيرش** في شاشة الجرد + نص "اكتب الكمية في الصنف اللي بتعدّه هو"، وزرار الاعتماد بيقول عدد المنتجات اللي اتغيّر.

**تصحيح الأجهزة**
- `schemaVersion` 8 → 9 مع `_reconcileDevices()`: الكافيه عنده **6 أجهزة مرقّمة 1..6** — `1,2,3` PS4 و `4,5,6` PS5 (الأسعار الافتراضية PS4 = 20/30، PS5 = 30/45). الأجهزة القديمة بتتص soft-delete عشان الفواتير القديمة تفضل سليمة.
- أي جلسة كانت شغالة وقت التحديث بتتقفل تلقائيًا عشان مفيش تايمر يفضل شغال على جهاز متشال.
- **تغيير نوع الجهاز** بقى متاح من شاشة الأجهزة (⋮ → تغيير نوع الجهاز) وهو مرفوض وقت ما يكون فيه جلسة شغالة.
- أنواع "بلياردو" و "VIP" فاضلة (ما فيش أجهزة) — موجودة جاهزة لو حبيت تضيف طاولات.

