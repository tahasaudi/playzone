import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/database/app_database.dart';
import '../../core/database/daos/device_dao.dart';
import '../../core/database/daos/product_dao.dart';
import '../../core/database/daos/reservation_dao.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/device_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../data/repositories/employee_repository.dart';
import '../../data/repositories/reservation_repository.dart';

/// Global search — spec (search phase). Opens with Ctrl+K from anywhere,
/// searches customers, devices, products, invoices, employees and
/// reservations at once, and jumps to the owning screen on select.
/// All results come from the LIVE providers, so the list is always
/// in sync with what the rest of the app is showing.
Future<void> showGlobalSearchDialog(
  BuildContext context,
  void Function(String route) onNavigate,
) {
  return showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => _GlobalSearchDialog(onNavigate: onNavigate),
  );
}

class _GlobalSearchDialog extends ConsumerStatefulWidget {
  const _GlobalSearchDialog({required this.onNavigate});
  final void Function(String route) onNavigate;

  @override
  ConsumerState<_GlobalSearchDialog> createState() =>
      _GlobalSearchDialogState();
}

class _SearchResult {
  const _SearchResult({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
}

class _GlobalSearchDialogState extends ConsumerState<_GlobalSearchDialog> {
  final TextEditingController _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<_SearchResult> _buildResults(String q) {
    final needle = q.trim().toLowerCase();
    if (needle.isEmpty) return const [];

    final results = <_SearchResult>[];

    for (final c in ref.read(customersProvider).value ?? const <CustomerRow>[]) {
      if (c.name.toLowerCase().contains(needle) ||
          c.phone.toLowerCase().contains(needle)) {
        results.add(_SearchResult(
          icon: Icons.person_rounded,
          title: c.name,
          subtitle: 'عميل · ${c.phone}',
          route: 'customers',
        ));
      }
    }

    for (final d in ref.read(devicesWithTypeProvider).value ??
        const <DeviceWithType>[]) {
      if (d.device.name.toLowerCase().contains(needle) ||
          d.type.name.toLowerCase().contains(needle)) {
        results.add(_SearchResult(
          icon: Icons.sports_esports_rounded,
          title: '${d.type.name} — ${d.device.name}',
          subtitle: 'جهاز',
          route: 'dashboard',
        ));
      }
    }

    for (final p in ref.read(productsWithCategoryProvider).value ??
        const <ProductWithCategory>[]) {
      if (p.product.name.toLowerCase().contains(needle)) {
        results.add(_SearchResult(
          icon: Icons.local_cafe_rounded,
          title: p.product.name,
          subtitle: 'منتج · ${p.category.name}',
          route: 'inventory',
        ));
      }
    }

    for (final inv
        in ref.read(recentInvoicesProvider).value ?? const <InvoiceRow>[]) {
      if (inv.id.toString() == needle || '#${inv.id}' == needle) {
        results.add(_SearchResult(
          icon: Icons.receipt_long_rounded,
          title: 'فاتورة #${inv.id}',
          subtitle: 'فاتورة · EGP ${inv.total.toStringAsFixed(0)}',
          route: 'invoices',
        ));
      }
    }

    for (final e
        in ref.read(activeEmployeesProvider).value ?? const <EmployeeRow>[]) {
      if (e.name.toLowerCase().contains(needle) ||
          e.phone.toLowerCase().contains(needle)) {
        results.add(_SearchResult(
          icon: Icons.badge_rounded,
          title: e.name,
          subtitle: 'موظف · ${e.phone}',
          route: 'employees',
        ));
      }
    }

    for (final r in ref.read(upcomingReservationsProvider).value ??
        const <ReservationWithDetails>[]) {
      if (r.customer.name.toLowerCase().contains(needle) ||
          r.device.name.toLowerCase().contains(needle)) {
        results.add(_SearchResult(
          icon: Icons.event_note_rounded,
          title: '${r.customer.name} — ${r.device.name}',
          subtitle: 'حجز',
          route: 'reservations',
        ));
      }
    }

    return results.take(20).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(top: 120, left: 80, right: 80),
      backgroundColor: Colors.transparent,
      child: Container(
        width: 620,
        constraints: const BoxConstraints(maxHeight: 520),
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: AppRadius.largeR,
          border: Border.all(color: AppColors.glassBorderPurple),
          boxShadow: AppShadows.cardHover,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: TextField(
                controller: _query,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'ابحث عن عميل، جهاز، منتج، فاتورة، موظف أو حجز...',
                  hintStyle:
                      TextStyle(color: AppColors.textTertiary, fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: AppColors.accentSecondary),
                  border: InputBorder.none,
                ),
              ),
            ),
            const Divider(color: AppColors.glassBorder, height: 1),
            Flexible(
              child: Builder(
                builder: (_) {
                  if (_query.text.trim().isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: Text('اكتب حاجة للبحث',
                          style: TextStyle(color: AppColors.textTertiary)),
                    );
                  }
                  final results = _buildResults(_query.text);
                  if (results.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: Text('مفيش نتائج',
                          style: TextStyle(color: AppColors.textTertiary)),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: results.length,
                    itemBuilder: (_, i) {
                      final r = results[i];
                      return InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                          widget.onNavigate(r.route);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md, vertical: 12),
                          child: Row(
                            children: [
                              Icon(r.icon,
                                  size: 20, color: AppColors.accentSecondary),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r.title,
                                        style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 14)),
                                    const SizedBox(height: 2),
                                    Text(r.subtitle,
                                        style: const TextStyle(
                                            color: AppColors.textTertiary,
                                            fontSize: 11)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded,
                                  size: 12, color: AppColors.textTertiary),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}