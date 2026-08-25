import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/warehouse_data.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          // ignore: use_null_aware_elements
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class StatusDot extends StatelessWidget {
  const StatusDot({super.key, required this.online, this.label});

  final bool online;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final color = online ? AppColors.success : AppColors.muted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label ?? (online ? 'متصل' : 'غير متصل'),
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 21),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class DeviceSummaryCard extends StatelessWidget {
  const DeviceSummaryCard({
    super.key,
    required this.title,
    required this.icon,
    required this.online,
    required this.status,
    this.details = const [],
    this.progress,
    this.progressColor = AppColors.primary,
  });

  final String title;
  final IconData icon;
  final bool online;
  final String status;
  final List<String> details;
  final double? progress;
  final Color progressColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 21),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        status,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusDot(online: online),
              ],
            ),
            if (progress != null) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  value: progress!.clamp(0, 1),
                  color: progressColor,
                  backgroundColor: AppColors.border,
                ),
              ),
            ],
            if (details.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: details
                    .map(
                      (detail) => Text(
                        detail,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Color statusColor(JsonMap item) {
  if (!boolValue(item['online'])) return AppColors.muted;
  final value = '${item['state'] ?? item['status'] ?? item['event'] ?? ''}'
      .toLowerCase();
  if (value.contains('danger') ||
      value.contains('fire') ||
      value.contains('critical')) {
    return AppColors.danger;
  }
  if (value.contains('warning') ||
      value.contains('low') ||
      value.contains('pending')) {
    return AppColors.warning;
  }
  return AppColors.success;
}

String friendlyStatus(Object? value) {
  return switch (textValue(value, 'unknown').toLowerCase()) {
    'moving' => 'متحرك',
    'idle' => 'خامل',
    'normal' => 'طبيعي',
    'stopped' => 'متوقف',
    'danger' => 'خطر',
    'warning' => 'تحذير',
    'stopped_low_battery' => 'متوقف لانخفاض البطارية',
    'stopped_safety' => 'توقف أمان',
    'unknown' => 'غير معروف',
    final value => value,
  };
}
