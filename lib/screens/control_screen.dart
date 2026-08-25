import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/warehouse_data.dart';
import '../services/api_service.dart';
import '../state/warehouse_controller.dart';
import '../widgets/warehouse_widgets.dart';

class ControlScreen extends StatelessWidget {
  const ControlScreen({super.key, required this.controller});

  final WarehouseController controller;

  @override
  Widget build(BuildContext context) {
    final devices = controller.snapshot.devices.entries.toList();
    final machines = controller.snapshot.machines.entries.toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
      children: [
        Text('لوحة التحكم', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        const Row(
          children: [
            Icon(Icons.lock_outline, color: AppColors.danger, size: 14),
            SizedBox(width: 5),
            Text(
              'صلاحية المشرف فقط',
              style: TextStyle(color: AppColors.danger, fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _GlobalCommandCard(
                title: 'إيقاف طارئ شامل',
                endpoint: 'POST  /emergency/STOP',
                icon: Icons.pan_tool_alt_outlined,
                color: AppColors.danger,
                background: AppColors.dangerDark,
                onPressed: () => _confirmGlobal(
                  context,
                  'stop',
                  'إيقاف جميع أنظمة المستودع؟',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _GlobalCommandCard(
                title: 'استئناف الكل',
                endpoint: 'POST  /emergency/RESUME',
                icon: Icons.play_circle_outline,
                color: AppColors.success,
                background: AppColors.successDark,
                onPressed: () => _confirmGlobal(
                  context,
                  'resume',
                  'استئناف جميع أنظمة المستودع؟',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'الأجهزة — ${devices.length} جهاز',
          style: const TextStyle(color: AppColors.muted, fontSize: 11),
        ),
        const SizedBox(height: 9),
        ...devices.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _DeviceControlTile(
              id: entry.key,
              device: entry.value,
              busy: controller.actionInProgress,
              onChanged: (enabled) =>
                  _confirmDevice(context, entry.key, enabled),
            ),
          ),
        ),
        if (machines.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'الآلات — ${machines.length} آلة',
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
          const SizedBox(height: 9),
          ...machines.map(
            (entry) => Card(
              child: ListTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.muted.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.precision_manufacturing_outlined,
                    color: AppColors.muted,
                    size: 20,
                  ),
                ),
                title: Text(
                  entry.key.toUpperCase(),
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'حرارة ${numberValue(entry.value['temperature']).toStringAsFixed(1)}°C  •  تيار ${numberValue(entry.value['current']).toStringAsFixed(1)}A',
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor(entry.value).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    friendlyStatus(entry.value['state']),
                    style: TextStyle(
                      color: statusColor(entry.value),
                      fontSize: 9,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmGlobal(
    BuildContext context,
    String action,
    String prompt,
  ) async {
    final confirmed = await _confirmationDialog(
      context,
      prompt,
      action == 'stop',
    );
    if (!confirmed || !context.mounted) return;
    await _execute(context, () => controller.sendGlobalCommand(action));
  }

  Future<void> _confirmDevice(
    BuildContext context,
    String id,
    bool enabled,
  ) async {
    final action = enabled ? 'تشغيل' : 'إيقاف';
    final confirmed = await _confirmationDialog(
      context,
      '$action الجهاز ${id.toUpperCase()}؟',
      !enabled,
    );
    if (!confirmed || !context.mounted) return;
    await _execute(context, () => controller.setDeviceEnabled(id, enabled));
  }

  Future<void> _execute(
    BuildContext context,
    Future<String> Function() operation,
  ) async {
    try {
      final message = await operation();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } on ApiException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<bool> _confirmationDialog(
    BuildContext context,
    String prompt,
    bool dangerous,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            icon: Icon(
              dangerous ? Icons.warning_amber_rounded : Icons.help_outline,
              color: dangerous ? AppColors.warning : AppColors.primary,
            ),
            title: const Text('تأكيد الإجراء'),
            content: Text(prompt, textAlign: TextAlign.center),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                style: dangerous
                    ? FilledButton.styleFrom(backgroundColor: AppColors.danger)
                    : null,
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('تأكيد'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _GlobalCommandCard extends StatelessWidget {
  const _GlobalCommandCard({
    required this.title,
    required this.endpoint,
    required this.icon,
    required this.color,
    required this.background,
    required this.onPressed,
  });

  final String title;
  final String endpoint;
  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.all(12),
          backgroundColor: background,
          foregroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: color.withValues(alpha: 0.45)),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 25),
            const SizedBox(height: 7),
            FittedBox(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              endpoint,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                color: color.withValues(alpha: 0.55),
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceControlTile extends StatelessWidget {
  const _DeviceControlTile({
    required this.id,
    required this.device,
    required this.busy,
    required this.onChanged,
  });

  final String id;
  final JsonMap device;
  final bool busy;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final type = textValue(device['device_type'], 'device');
    final enabled = boolValue(
      device['reported_enabled'],
      boolValue(device['desired_enabled'], true),
    );
    final pending = boolValue(device['pending']);
    final color = enabled ? AppColors.success : AppColors.muted;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_deviceIcon(type), color: color, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    id.toLowerCase(),
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'ID: $id   •   $type${pending ? '   •   قيد التنفيذ' : ''}',
                    textDirection: TextDirection.ltr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: pending ? AppColors.warning : AppColors.muted,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            Switch(value: enabled, onChanged: busy ? null : onChanged),
          ],
        ),
      ),
    );
  }

  IconData _deviceIcon(String type) => switch (type) {
    'machine' => Icons.settings_outlined,
    'robot' => Icons.smart_toy_outlined,
    'forklift' => Icons.forklift,
    'conveyor' => Icons.view_week_outlined,
    _ => Icons.memory_outlined,
  };
}
