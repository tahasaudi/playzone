/// عقد وسيط IR — أي قطعة مادية بتشتغل المراسلة مع الشاشات
/// (حالياً ESP32 بأوامر HTTP) لازم تنفذ الواجهتين دول.
abstract class IrCommandBox {
  /// فحص إن كان الصندوق حي على الشبكة (بيستخدمه زر "اختبار").
  Future<bool> isReachable();

  /// إرسال إشارة مسجلة بالاسم، مثل "power" أو "input1".
  Future<bool> send(String slot);
}