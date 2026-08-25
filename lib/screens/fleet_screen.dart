import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/warehouse_data.dart';
import '../services/api_service.dart';
import '../state/warehouse_controller.dart';
import '../widgets/warehouse_widgets.dart';

class FleetScreen extends StatefulWidget {
  const FleetScreen({super.key, required this.controller});

  final WarehouseController controller;

  @override
  State<FleetScreen> createState() => _FleetScreenState();
}

class _FleetScreenState extends State<FleetScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final robots = widget.controller.snapshot.robots.entries.toList();
    final forklifts = widget.controller.snapshot.forklifts.entries.toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              'الروبوتات والرافعات',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
        TabBar(
          controller: _tabs,
          dividerColor: AppColors.muted,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.muted,
          tabs: [
            Tab(text: 'AGV (${robots.length})'),
            Tab(text: 'رافعات (${forklifts.length})'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              RefreshIndicator(
                onRefresh: widget.controller.refresh,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: robots.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final entry = robots[index];
                    return _RobotCard(
                      id: entry.key,
                      robot: entry.value,
                      weight: widget
                          .controller
                          .snapshot
                          .robotWeights[entry.key],
                      busy: widget.controller.actionInProgress,
                      onCommand: (action) =>
                          _confirmRobotCommand(entry.key, action),
                    );
                  },
                ),
              ),
              RefreshIndicator(
                onRefresh: widget.controller.refresh,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: forklifts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final entry = forklifts[index];
                    return _ForkliftCard(id: entry.key, forklift: entry.value);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmRobotCommand(String id, String action) async {
    final label = switch (action) {
      'stop' => 'إيقاف',
      'resume' => 'استئناف',
      'charge' => 'شحن',
      _ => action,
    };
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد الإجراء'),
        content: Text('$label الروبوت ${id.toUpperCase()}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final message = await widget.controller.sendRobotCommand(id, action);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }
}

class _RobotCard extends StatelessWidget {
  const _RobotCard({
    required this.id,
    required this.robot,
    required this.weight,
    required this.busy,
    required this.onCommand,
  });

  final String id;
  final JsonMap robot;
  final JsonMap? weight;
  final bool busy;
  final ValueChanged<String> onCommand;

  @override
  Widget build(BuildContext context) {
    final battery = numberValue(robot['battery']);
    final online = boolValue(robot['online']);
    final lowBattery = boolValue(robot['low_battery']) || battery <= 20;
    return Card(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFF122D52),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.smart_toy_outlined,
                    color: Color(0xFF65A8FF),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        id.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        lowBattery
                            ? 'البطارية ضعيفة'
                            : friendlyStatus(robot['status']),
                        style: TextStyle(
                          color: lowBattery
                              ? AppColors.warning
                              : AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusDot(online: online),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'البطارية',
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                    Text(
                      '${battery.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: lowBattery
                            ? AppColors.warning
                            : AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: (battery / 100).clamp(0, 1),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(4),
                  color: lowBattery ? AppColors.warning : AppColors.primary,
                  backgroundColor: AppColors.border,
                ),
                const SizedBox(height: 10),
                Text(
                  'الحمولة الحالية: ${numberValue(weight?['value']).toStringAsFixed(1)} كغ',
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _RobotAction(
                        label: 'إيقاف',
                        icon: Icons.stop,
                        color: AppColors.danger,
                        background: AppColors.dangerDark,
                        enabled: !busy,
                        onPressed: () => onCommand('stop'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _RobotAction(
                        label: 'استئناف',
                        icon: Icons.play_arrow,
                        color: AppColors.success,
                        background: AppColors.successDark,
                        enabled: !busy,
                        onPressed: () => onCommand('resume'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _RobotAction(
                        label: 'شحن',
                        icon: Icons.battery_charging_full,
                        color: AppColors.warning,
                        background: AppColors.warningDark,
                        enabled: !busy,
                        onPressed: () => onCommand('charge'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RobotAction extends StatelessWidget {
  const _RobotAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.background,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color background;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: enabled ? onPressed : null,
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      ),
      icon: Icon(icon, size: 16),
      label: FittedBox(child: Text(label)),
    );
  }
}

class _ForkliftCard extends StatelessWidget {
  const _ForkliftCard({required this.id, required this.forklift});

  final String id;
  final JsonMap forklift;

  @override
  Widget build(BuildContext context) {
    final battery = numberValue(forklift['battery']);
    final online = boolValue(forklift['online']);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.warningDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.forklift, color: AppColors.warning),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    id.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    friendlyStatus(forklift['status']),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: (battery / 100).clamp(0, 1),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(4),
                    color: AppColors.primary,
                    backgroundColor: AppColors.border,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'البطارية ${battery.toStringAsFixed(0)}%   •   السرعة ${numberValue(forklift['speed']).toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            StatusDot(online: online, label: online ? 'متصل' : 'منقطع'),
          ],
        ),
      ),
    );
  }
}
