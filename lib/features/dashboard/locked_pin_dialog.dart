import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_buttons.dart';
import '../../data/repositories/settings_repository.dart';

/// Prompts for the custom PIN from Settings → الأزرار المحمية and
/// verifies it against the stored hash. Returns true only on a correct
/// PIN; shows one inline error line otherwise (never hints why the PIN
/// failed).
Future<bool> showLockedPinDialog(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _LockedPinDialog(),
  );
  return ok ?? false;
}

class _LockedPinDialog extends ConsumerStatefulWidget {
  const _LockedPinDialog();

  @override
  ConsumerState<_LockedPinDialog> createState() => _LockedPinDialogState();
}

class _LockedPinDialogState extends ConsumerState<_LockedPinDialog> {
  final _controller = TextEditingController();
  bool _error = false;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    final ok =
        await ref.read(settingsRepositoryProvider).verifyLockedPin(_controller.text);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _busy = false;
        _error = true;
        _controller.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: AppRadius.largeR,
          border: Border.all(color: AppColors.glassBorderPurple),
          boxShadow: AppShadows.cardHover,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lock_rounded, color: AppColors.accentSecondary),
                SizedBox(width: AppSpacing.sm),
                Text('رقم سري محمي', style: AppTypography.sectionTitle),
              ],
            ),
            const SizedBox(height: 4),
            const Text('ادخل الرقم السري لعرض الرقم',
                style: AppTypography.secondary),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _controller,
              autofocus: true,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'الرقم السري',
                errorText: _error ? 'الرقم السري غير صحيح' : null,
                filled: true,
                fillColor: AppColors.glassFill,
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SecondaryButton(
                  label: 'إلغاء',
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                const SizedBox(width: AppSpacing.sm),
                PrimaryButton(
                  label: _busy ? '...' : 'فتح',
                  icon: Icons.lock_open_rounded,
                  onPressed: _busy ? null : _submit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}