# PlayZone — Phase 1: Core Database Foundation

المرحلة دي ربطت المشروع بقاعدة بيانات SQLite حقيقية عن طريق Drift، بدل البيانات الوهمية.

## ⚠️ خطوة إجبارية قبل التشغيل: توليد كود Drift

Drift بيحتاج code generation عشان يشتغل. **لازم تشغّل الأمر ده قبل أي `flutter run`:**

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

الأمر ده هيولّد الملفات دي (متوجودش في المشروع لسه، وده طبيعي):
- `lib/core/database/app_database.g.dart`
- `lib/core/database/daos/employee_dao.g.dart`
- `lib/core/database/daos/device_dao.g.dart`
- `lib/core/database/daos/customer_dao.g.dart`
- `lib/core/database/daos/product_dao.g.dart`

من غير الخطوة دي المشروع مش هيعمل build خالص (هتلاقي أخطاء "Target of URI doesn't exist" على ملفات `.g.dart`).

كل مرة تعدّل في أي جدول (table) أو DAO، لازم تعيد تشغيل الأمر ده تاني.

## إيه اللي اتغيّر في المرحلة دي

- **قاعدة بيانات حقيقية**: SQLite عن طريق Drift، الملف بيتحفظ في مجلد بيانات التطبيق (مش مسار ثابت مكتوب في الكود)
- **6 جداول أساسية**: Employees, DeviceTypes, Devices, Customers, Categories, Products
- **Seed Data تلقائي**: أول مرة تشغّل التطبيق، بيتزرع نفس بيانات الـ mock اللي كانت موجودة (نفس الأجهزة، نفس المنتجات، نفس الأسعار) — عشان الانتقال يكون سلس ومحسّش الفرق
- **Repository Layer**: كل شاشة بقت بتتكلم مع `EmployeeRepository` / `DeviceRepository` / `CustomerRepository` / `ProductRepository` بدل ما تلمس الداتابيز مباشرة
- **PermissionService مركزي**: كل عملية حساسة (تغيير سعر، تعديل مخزون) بقت بتتفحص على مستوى الـ Repository نفسه، مش بس مخفية في الواجهة — يعني حتى لو حد لقى طريقة يوصل للفانكشن مباشرة، هيتمنع
- **شاشة عملاء جديدة بالكامل**: بحث، إضافة عميل، عرض نقاط الولاء وعدد الزيارات (لسه بتتحدّث يدوي، هتتوصل بالجلسات في Phase 2)
- **PIN مشفّر**: فيه حساب أدمن تجريبي (تليفون `01000000000`، PIN `0000`) — مخزّن كـ SHA-256 hash، مش نص عادي

## حساب تجريبي (Seed)
```
تليفون: 01000000000
PIN: 0000
دور: أدمن
```
(شاشة تسجيل الدخول الفعلية لسه ماتبنتش — استخدم الـ dropdown في TopBar للتجربة لحد كده)

## اللي لسه مبني عليه Phase 2
Sessions (الجلسة الحية الفعلية)، Live Timer الحقيقي، Checkout المتصل بفاتورة حقيقية، Pause/Resume الفعلي.
