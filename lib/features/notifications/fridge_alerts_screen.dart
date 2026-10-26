import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/glass_card.dart';

class FridgeAlert {
  FridgeAlert({
    required this.id,
    required this.timeText,
    required this.product,
    required this.camera,
    required this.note,
    required this.imagePath,
    required this.read,
  });

  final String id;
  final String timeText;
  final String product;
  final String? camera;
  final String? note;
  final String? imagePath;
  final bool read;
}

final fridgeAlertsProvider = FutureProvider.autoDispose<List<FridgeAlert>>((ref) async {
  final paths = [
    r'C:\Users\miza\AppData\Roaming\PlayZone\vision_service\logs\alerts.json',
    r'C:\Users\miza\AppData\Roaming\PlayZone\vision_service\logs\alerts.jsonl',
  ];

  List<FridgeAlert> alerts = [];

  try {
    final f = File(paths[0]);
    if (await f.exists()) {
      final content = await f.readAsString();
      final data = jsonDecode(content);
      if (data is List) {
        for (final item in data) {
          if (item is Map) {
            alerts.add(FridgeAlert(
              id: (item['id'] ?? '').toString(),
              timeText: (item['time_text'] ?? item['time'] ?? '').toString(),
              product: (item['product'] ?? '').toString(),
              camera: item['camera']?.toString(),
              note: item['note']?.toString(),
              imagePath: item['image_path']?.toString(),
              read: item['read'] == true,
            ));
          }
        }
      }
    }
  } catch (_) {}

  if (alerts.isEmpty) {
    try {
      final f = File(paths[1]);
      if (await f.exists()) {
        final lines = await f.readAsLines();
        for (final line in lines.reversed) {
          if (line.trim().isEmpty) continue;
          try {
            final item = jsonDecode(line);
            if (item is Map) {
              alerts.add(FridgeAlert(
                id: (item['id'] ?? '').toString(),
                timeText: (item['time_text'] ?? item['time'] ?? '').toString(),
                product: (item['product'] ?? '').toString(),
                camera: item['camera']?.toString(),
                note: item['note']?.toString(),
                imagePath: item['image_path']?.toString(),
                read: item['read'] == true,
              ));
            }
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  return alerts;
});

class FridgeAlertsScreen extends ConsumerWidget {
  const FridgeAlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(fridgeAlertsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active_rounded, color: AppColors.accentSecondary, size: 28),
                const SizedBox(width: AppSpacing.sm),
                const Text('إشعارات', style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
                  onPressed: () => ref.invalidate(fridgeAlertsProvider),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: alertsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('خطأ: $e', style: const TextStyle(color: AppColors.danger))),
                data: (alerts) {
                  if (alerts.isEmpty) {
                    return const Center(
                      child: Text('مفيش إشعارات حالياً', style: TextStyle(color: AppColors.textTertiary, fontSize: 16)),
                    );
                  }
                  return ListView.separated(
                    itemCount: alerts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, i) {
                      final a = alerts[i];
                      return GlassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.danger.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'تم سحب منتج من الثلاجة ولم يُسجّل على الكاشير',
                                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('المنتج: ${a.product}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                    if (a.camera != null && a.camera!.isNotEmpty)
                                      Text('الكاميرا: ${a.camera}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                    if (a.note != null && a.note!.isNotEmpty)
                                      Text(a.note!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                    const SizedBox(height: 6),
                                    Text(a.timeText, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                                    if (a.imagePath != null && a.imagePath!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.file(
                                            File(a.imagePath!),
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
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
