import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/warehouse_data.dart';
import '../state/warehouse_controller.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key, required this.controller});

  final WarehouseController controller;

  @override
  Widget build(BuildContext context) {
    final alerts = controller.snapshot.alerts;
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'التنبيهات',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'أحداث الآلات والروبوتات المباشرة',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: (alerts.isEmpty ? AppColors.success : AppColors.danger)
                      .withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${alerts.length}',
                  style: TextStyle(
                    color: alerts.isEmpty
                        ? AppColors.success
                        : AppColors.danger,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (alerts.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: AppColors.success,
                      size: 42,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'لا توجد تنبيهات حالياً',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'حالة المستودع مستقرة',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          else
            ...alerts.map(
              (alert) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AlertCard(alert: alert),
              ),
            ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});

  final JsonMap alert;

  @override
  Widget build(BuildContext context) {
    final event = textValue(
      alert['event_name'] ?? alert['event'],
      'SYSTEM_ALERT',
    );
    final lower = event.toLowerCase();
    final isCritical =
        lower.contains('fire') ||
        lower.contains('emergency') ||
        textValue(alert['status']).toLowerCase() == 'critical';
    final isWarning =
        lower.contains('low') ||
        lower.contains('warning') ||
        lower.contains('overweight');
    final color = isCritical
        ? AppColors.danger
        : isWarning
        ? AppColors.warning
        : AppColors.primary;
    final icon = isCritical
        ? Icons.local_fire_department_outlined
        : isWarning
        ? Icons.warning_amber_rounded
        : Icons.info_outline;
    final source = textValue(
      alert['machine_id'] ?? alert['robot_id'] ?? alert['forklift_id'],
      'النظام',
    );
    final message = _friendlyMessage(
      event,
      textValue(alert['message'], _friendlyEvent(event)),
    );
    return Card(
      child: Container(
        decoration: BoxDecoration(
          border: BorderDirectional(start: BorderSide(color: color, width: 3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _friendlyEvent(event),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          source.toUpperCase(),
                          style: TextStyle(
                            color: color,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      message,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      _formatTimestamp(
                        alert['timestamp'] ?? alert['last_seen'],
                      ),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _friendlyEvent(String value) {
    final normalized = value.toUpperCase();
    if (normalized.contains('FIRE')) return 'إنذار حريق';
    if (normalized.contains('LOW_BATTERY')) return 'انخفاض بطارية';
    if (normalized.contains('OVERWEIGHT')) return 'حمولة زائدة';
    if (normalized.contains('DANGER')) return 'حالة خطر';
    if (normalized.contains('SAFETY')) return 'توقف أمان';
    return value.replaceAll('_', ' ');
  }

  String _friendlyMessage(String event, String message) {
    final normalized = event.toUpperCase();
    if (normalized.contains('LOW_BATTERY')) {
      return 'انخفضت بطارية الروبوت إلى مستوى يحتاج الانتباه.';
    }
    if (normalized.contains('FIRE')) {
      return 'تم اكتشاف حريق وتفعيل حالة الطوارئ في المستودع.';
    }
    if (normalized.contains('OVERWEIGHT')) {
      return 'تم رفض الحمولة لأنها تتجاوز الوزن المسموح.';
    }
    if (normalized.contains('SAFETY')) {
      return 'توقف الجهاز استجابة لنظام الأمان.';
    }
    return message;
  }

  String _formatTimestamp(Object? value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (parsed == null) return 'الوقت غير متوفر';
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(parsed.hour)}:${two(parsed.minute)}  ${two(parsed.day)}/${two(parsed.month)}/${parsed.year}';
  }
}
