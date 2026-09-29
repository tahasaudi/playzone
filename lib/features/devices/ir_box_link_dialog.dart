import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/ir/ir_box_repository.dart';
import '../../core/ir/esp32_ir_command_box.dart';

/// نافذة ربط جهاز (بلايستيشن) بصندوق IR بتاع ستارته.
/// بيحصل التخزين في إعدادات التطبيق ويختبر الاتصال بالبورد مباشرة.
Future<void> showIrBoxLinkDialog(
  BuildContext context,
  WidgetRef ref, {
  required int deviceId,
  required String deviceName,
}) {
  return showDialog(
    context: context,
    builder: (_) => _IrBoxLinkDialog(deviceId: deviceId, deviceName: deviceName),
  );
}

class _IrBoxLinkDialog extends ConsumerStatefulWidget {
  const _IrBoxLinkDialog({required this.deviceId, required this.deviceName});

  final int deviceId;
  final String deviceName;

  @override
  ConsumerState<_IrBoxLinkDialog> createState() => _IrBoxLinkDialogState();
}

class _IrBoxLinkDialogState extends ConsumerState<_IrBoxLinkDialog> {
  late final TextEditingController _url;
  bool? _reachable; // null = لم يُختبر بعد
  bool _testing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _url = TextEditingController(
        text: ref.read(irBoxLinksProvider)[widget.deviceId] ?? '');
  }

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _test() async {
    if (_url.text.trim().isEmpty) {
      setState(() => _error = 'اكتب عنوان البورد (IP) الأول');
      return;
    }
    setState(() {
      _testing = true;
      _reachable = null;
      _error = null;
    });
    final ok = await Esp32IrCommandBox(_url.text.trim()).isReachable();
    if (!mounted) return;
    setState(() {
      _testing = false;
      _reachable = ok;
    });
  }

  Future<void> _save() async {
    final url = _url.text.trim();
    if (url.isEmpty) {
      setState(() => _error = 'اكتب عنوان البورد (IP) الأول');
      return;
    }
    await ref.read(irBoxRepositoryProvider).setLink(widget.deviceId, url);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم ربط الجهاز بصندوق IR')));
    }
  }

  Future<void> _unlink() async {
    await ref.read(irBoxRepositoryProvider).removeLink(widget.deviceId);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: AppRadius.largeR,
          border: Border.all(color: AppColors.glassBorderPurple),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ربط بصندوق IR — ${widget.deviceName}',
                style: AppTypography.sectionTitle),
            const SizedBox(height: 6),
            const Text(
              'اكتب عنوان البورد (ESP32 IR Box) بتاع الستارة دي، مثلاً 192.168.1.50',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _url,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'عنوان البورد (IP أو http://...)',
                hintText: '192.168.1.50',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_error!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 13)),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                SecondaryButton(
                  label: _testing ? 'جارٍ الفحص...' : 'اختبار الاتصال',
                  icon: Icons.network_check_rounded,
                  onPressed: _testing ? null : _test,
                ),
                const SizedBox(width: AppSpacing.sm),
                if (_reachable == true)
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.statusAvailable, size: 20),
                if (_reachable == false)
                  const Icon(Icons.error_rounded,
                      color: AppColors.danger, size: 20),
                if (_reachable != null)
                  const SizedBox(width: 6),
                if (_reachable == true)
                  const Text('متصّل ✓',
                      style: TextStyle(
                          color: AppColors.statusAvailable, fontSize: 12)),
                if (_reachable == false)
                  const Text('لا يمكن الوصول',
                      style:
                          TextStyle(color: AppColors.danger, fontSize: 12)),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                if (_url.text.trim().isNotEmpty) ...[
                  SecondaryButton(
                    label: 'قطع الربط',
                    icon: Icons.link_off_rounded,
                    onPressed: _unlink,
                  ),
                  const SizedBox(width: 8),
                ],
                const Spacer(),
                SecondaryButton(
                  label: 'إلغاء',
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                PrimaryButton(
                  label: 'حفظ',
                  icon: Icons.check_rounded,
                  onPressed: _save,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}