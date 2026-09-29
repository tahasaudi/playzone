import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/permissions/app_feature.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/employee_repository.dart';
import '../../data/repositories/employee_feature_repository.dart';

/// الشاشة المحمية — كل أرقام الإيراد/الربح/المتوقع اللي كانت أزرار
/// مقفولة على اللوحة اتحوّلت هنا لشاشة لوحدها. القفل حاليًا في
/// الذاكرة (أول ما تدخل بتروح قفل تاني) والسماح لأي موظف/محصلي
/// per-feature في شاشة الصلحيات.
class ProtectedScreen extends ConsumerStatefulWidget {
  const ProtectedScreen({super.key});

  @override
  ConsumerState<ProtectedScreen> createState() => _ProtectedScreenState();
}

/// Whether the current session on this screen has passed the PIN check.
final protectedUnlockedProvider =
    StateProvider<bool>((ref) => false);

class _ProtectedScreenState extends ConsumerState<ProtectedScreen> {
  final _pinController = TextEditingController();
  String? _error;
  bool _checking = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    final pin = _pinController.text.trim();
    if (pin.isEmpty) return;
    setState(() {
      _checking = true;
      _error = null;
    });
    final ok =
        await ref.read(settingsRepositoryProvider).verifyLockedPin(pin);
    if (!mounted) return;
    if (ok) {
      ref.read(protectedUnlockedProvider.notifier).state = true;
    } else {
      setState(() => _error = 'الرقم السري غلط');
    }
    setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = ref.watch(protectedUnlockedProvider);
    final visible = ref.watch(visibleFeaturesProvider);
    final allowed =
        visible.contains(AppFeature.protectedScreen);

    if (!allowed) {
      return const Center(
        child: Text('مفيش صلاحية لشوفة الشاشة المحمية',
            style: TextStyle(color: AppColors.textTertiary)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الشاشة المحمية', style: AppTypography.sectionTitle),
                  SizedBox(height: 2),
                  Text('الإيرادات والأرباح محمية برقم سري — مش على اللوحة',
                      style: AppTypography.secondary),
                ],
              ),
            ),
            if (unlocked)
              SecondaryButton(
                label: 'قفل',
                icon: Icons.lock_rounded,
                onPressed: () {
                  ref.read(protectedUnlockedProvider.notifier).state = false;
                  _pinController.clear();
                },
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: unlocked
              ? _ProtectedContent(visible: visible)
              : Center(
                  child: _PinGate(
                    controller: _pinController,
                    checking: _checking,
                    error: _error,
                    onUnlock: _unlock,
                  ),
                ),
        ),
      ],
    );
  }
}

class _PinGate extends StatelessWidget {
  const _PinGate({
    required this.controller,
    required this.checking,
    required this.error,
    required this.onUnlock,
  });

  final TextEditingController controller;
  final bool checking;
  final String? error;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: AppColors.glassBorderPurple,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.lock_rounded,
                size: 44, color: AppColors.accentSecondary),
            const SizedBox(height: AppSpacing.md),
            const Text('الرقم السري للحماية',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.textTertiary, fontSize: 12)),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: controller,
              autofocus: true,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 10,
              onSubmitted: (_) => onUnlock(),
              decoration: InputDecoration(
                labelText: 'ادخل الرقم السري',
                counterText: '',
                errorText: error,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: checking ? '...تحقق' : 'فتح',
              icon: Icons.lock_open_rounded,
              expand: true,
              onPressed: checking ? null : onUnlock,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProtectedContent extends ConsumerWidget {
  const _ProtectedContent({required this.visible});
  final Set<AppFeature> visible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(oneSecondTickerProvider);
    final activeSessions = ref.watch(activeSessionsProvider).value ?? [];
    final todayInvoices = ref.watch(todayInvoicesProvider).value ?? [];
    final todayExpenses = ref.watch(todayExpensesProvider).value ?? [];

    final gamingRevenue = activeSessions
        .fold<double>(0, (sum, s) => sum + s.liveCost);
    final activeCount =
        activeSessions.where((s) => s.session.status == 'active').length;

    // طلبات الكافيه المرتبطة بالجلسات اللي لسه شغالة — محجوزة هتتحصل.
    final ordersOnLiveSessions = <int, double>{};
    for (final inv in todayInvoices) {
      if (inv.sessionId == null) continue;
      final stillOpen = activeSessions.any((s) => s.session.id == inv.sessionId);
      if (stillOpen) {
        ordersOnLiveSessions[inv.sessionId!] =
            (ordersOnLiveSessions[inv.sessionId!] ?? 0) + inv.total;
      }
    }
    final ordersTotal = ordersOnLiveSessions.values.fold<double>(0, (a, b) => a + b);

    final todayRevenue = todayInvoices.fold<double>(0, (sum, i) => sum + i.total);
    final todayExpenseTotal = todayExpenses.fold<double>(0, (sum, e) => sum + e.amount);
    final todayProfit = todayRevenue - todayExpenseTotal;
    // المتوقع تحصيله: الإيراد المحصل + اللي اتسجل من الجلسات + طلباتهم.
    final expectedRevenue = todayRevenue + gamingRevenue + ordersTotal;

    String egp(double v) => 'EGP ${v.toStringAsFixed(0)}';

    final metrics = <(AppFeature, String, String, IconData, Color, String?)>[
      if (visible.contains(AppFeature.viewPerformance))
        (
          AppFeature.viewPerformance,
          'أداء اليوم',
          egp(todayRevenue),
          Icons.insights_rounded,
          AppColors.accentSecondary,
          'الربح: ${egp(todayProfit)}',
        ),
      if (visible.contains(AppFeature.viewDailyRevenue))
        (
          AppFeature.viewDailyRevenue,
          'الإيراد اليومي',
          egp(todayRevenue),
          Icons.payments_rounded,
          AppColors.accentSecondary,
          null,
        ),
      if (visible.contains(AppFeature.viewDailyExpenses))
        (
          AppFeature.viewDailyExpenses,
          'مصروفات اليوم',
          egp(todayExpenseTotal),
          Icons.money_off_rounded,
          AppColors.danger,
          null,
        ),
      if (visible.contains(AppFeature.viewDailyProfit))
        (
          AppFeature.viewDailyProfit,
          'الربح (بعد المصروفات)',
          egp(todayProfit),
          Icons.savings_rounded,
          AppColors.statusAvailable,
          null,
        ),
      if (visible.contains(AppFeature.viewGamingRevenue))
        (
          AppFeature.viewGamingRevenue,
          'إيراد الألعاب (مباشر)',
          egp(gamingRevenue),
          Icons.sports_esports_rounded,
          AppColors.statusActive,
          null,
        ),
      if (visible.contains(AppFeature.viewExpectedRevenue))
        (
          AppFeature.viewExpectedRevenue,
          'الإيراد المتوقع',
          egp(expectedRevenue),
          Icons.trending_up_rounded,
          AppColors.accentSecondary,
          'من ${activeSessions.length} جهاز شغال دلوقتي',
        ),
      if (visible.contains(AppFeature.viewSessionCount))
        (
          AppFeature.viewSessionCount,
          'الجلسات الشغّالة',
          '$activeCount',
          Icons.timelapse_rounded,
          AppColors.statusActive,
          'من ${activeSessions.length} جهاز معرّف',
        ),
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (metrics.isNotEmpty) ...[
            LayoutBuilder(builder: (context, constraints) {
              final columns = constraints.maxWidth > 1400
                  ? 4
                  : constraints.maxWidth > 900
                      ? 3
                      : 2;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.6,
                children: metrics.map((m) => _MetricCard2(m)).toList(),
              );
            }),
          ],
          if (visible.contains(AppFeature.viewEmployeeRevenueBreakdown)) ...[
            const SizedBox(height: AppSpacing.lg),
            const _EmployeeRevenueBreakdown(),
          ],
        ],
      ),
    );
  }
}

class _MetricCard2 extends StatelessWidget {
  const _MetricCard2(this.m);
  final (AppFeature, String, String, IconData, Color, String?) m;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(m.$4, size: 18, color: m.$5),
              const SizedBox(width: AppSpacing.sm),
              Text(m.$2, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(m.$3, style: AppTypography.numberLarge),
          if (m.$6 != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(m.$6!,
                style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
          ],
        ],
      ),
    );
  }
}

/// Today's revenue broken down by which employee handled each invoice.
class _EmployeeRevenueBreakdown extends ConsumerWidget {
  const _EmployeeRevenueBreakdown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(todayInvoicesProvider);
    final employeesAsync = ref.watch(activeEmployeesProvider);

    return invoicesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (invoices) {
        final employees = employeesAsync.value ?? [];
        final byEmployee = <int?, double>{};
        for (final invoice in invoices) {
          byEmployee[invoice.employeeId] =
              (byEmployee[invoice.employeeId] ?? 0) + invoice.total;
        }
        if (byEmployee.isEmpty) return const SizedBox.shrink();

        String nameFor(int? id) {
          if (id == null) return 'غير محدد';
          return employees.where((e) => e.id == id).map((e) => e.name).firstOrNull ??
              'موظف #$id';
        }

        final entries = byEmployee.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('الإيراد اليومي حسب الموظف',
                  style: AppTypography.cardTitle),
              const SizedBox(height: AppSpacing.md),
              for (final entry in entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(nameFor(entry.key),
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                      Text('EGP ${entry.value.toStringAsFixed(0)}',
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

extension _FirstOrNullExt<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}