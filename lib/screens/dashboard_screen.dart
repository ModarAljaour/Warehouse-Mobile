import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/warehouse_data.dart';
import '../state/warehouse_controller.dart';
import '../widgets/warehouse_widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.controller,
    this.onLogout,
  });

  final WarehouseController controller;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    final snapshot = controller.snapshot;
    final machineStats = asJsonMap(controller.stats['machines']);
    final robotStats = asJsonMap(controller.stats['robots']);
    final forkliftStats = asJsonMap(controller.stats['forklifts']);
    final onlineDevices = snapshot.devices.values
        .where((item) => boolValue(item['online']))
        .length;
    final sensorValues = snapshot.environmentSensors.values.toList();
    final averageTemperature = sensorValues.isEmpty
        ? 0.0
        : sensorValues
                  .map((item) => numberValue(item['temperature']))
                  .reduce((a, b) => a + b) /
              sensorValues.length;
    final systemHealth = textValue(
      controller.stats['system_health'],
      'unknown',
    ).toLowerCase();
    final systemHealthLabel = switch (systemHealth) {
      'excellent' => 'ممتاز',
      'good' => 'جيد',
      'warning' => 'تحذير',
      'critical' => 'حرج',
      _ => 'غير معروف',
    };

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'نظرة عامة',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      controller.errorMessage ?? 'بيانات المستودع الحية',
                      style: TextStyle(
                        color: controller.errorMessage == null
                            ? AppColors.muted
                            : AppColors.danger,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'تحديث',
                onPressed: controller.loading ? null : controller.refresh,
                icon: const Icon(Icons.refresh),
              ),
              if (onLogout != null)
                IconButton(
                  tooltip: 'تسجيل الخروج',
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout, color: AppColors.muted),
                ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.42,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              MetricCard(
                label: 'الأجهزة المتصلة',
                value: '$onlineDevices/${snapshot.devices.length}',
                icon: Icons.hub_outlined,
                color: AppColors.success,
              ),
              MetricCard(
                label: 'الروبوتات النشطة',
                value:
                    '${robotStats['active'] ?? 0}/${robotStats['total'] ?? snapshot.robots.length}',
                icon: Icons.smart_toy_outlined,
                color: AppColors.primary,
              ),
              MetricCard(
                label: 'متوسط الحرارة',
                value: '${averageTemperature.toStringAsFixed(1)}°C',
                icon: Icons.thermostat,
                color: AppColors.warning,
              ),
              MetricCard(
                label: 'التنبيهات',
                value:
                    '${controller.stats['alerts_count'] ?? snapshot.alerts.length}',
                icon: Icons.notifications_active_outlined,
                color: snapshot.alerts.isEmpty
                    ? AppColors.cyan
                    : AppColors.danger,
              ),
            ],
          ),
          SectionHeader(
            'حالة النظام',
            trailing: Text(
              systemHealthLabel,
              style: TextStyle(
                color: systemHealth == 'excellent' || systemHealth == 'good'
                    ? AppColors.success
                    : AppColors.warning,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  _SystemCount(
                    label: 'الآلات',
                    value:
                        '${machineStats['online'] ?? 0}/${machineStats['total'] ?? 0}',
                  ),
                  const VerticalDivider(),
                  _SystemCount(
                    label: 'الروبوتات',
                    value:
                        '${robotStats['online'] ?? 0}/${robotStats['total'] ?? 0}',
                  ),
                  const VerticalDivider(),
                  _SystemCount(
                    label: 'الشوكة',
                    value:
                        '${forkliftStats['online'] ?? 0}/${forkliftStats['total'] ?? 0}',
                  ),
                  const VerticalDivider(),
                  _SystemCount(
                    label: 'الحساسات',
                    value:
                        '${sensorValues.where((item) => boolValue(item['online'])).length}/${sensorValues.length}',
                  ),
                ],
              ),
            ),
          ),
          const SectionHeader('الروبوتات والرافعة'),
          ...snapshot.robots.entries.map((entry) {
            final robot = entry.value;
            final battery = numberValue(robot['battery']);
            final weight = numberValue(
              snapshot.robotWeights[entry.key]?['value'],
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: DeviceSummaryCard(
                title: entry.key.toUpperCase(),
                icon: Icons.smart_toy_outlined,
                online: boolValue(robot['online']),
                status: friendlyStatus(robot['status']),
                progress: battery / 100,
                progressColor: battery <= 20
                    ? AppColors.danger
                    : AppColors.primary,
                details: [
                  'البطارية ${battery.toStringAsFixed(0)}%',
                  'الحمولة ${weight.toStringAsFixed(1)} كغ',
                ],
              ),
            );
          }),
          ...snapshot.forklifts.entries.map((entry) {
            final forklift = entry.value;
            final battery = numberValue(forklift['battery']);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: DeviceSummaryCard(
                title: 'الشوكة ${entry.key}',
                icon: Icons.forklift,
                online: boolValue(forklift['online']),
                status: friendlyStatus(forklift['status']),
                progress: battery / 100,
                progressColor: battery <= 20
                    ? AppColors.danger
                    : AppColors.cyan,
                details: [
                  'البطارية ${battery.toStringAsFixed(0)}%',
                  'السرعة ${numberValue(forklift['speed']).toStringAsFixed(1)}',
                ],
              ),
            );
          }),
          const SectionHeader('الآلة'),
          ...snapshot.machines.entries.map((entry) {
            final machine = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: DeviceSummaryCard(
                title: entry.key.toUpperCase(),
                icon: Icons.precision_manufacturing_outlined,
                online: boolValue(machine['online']),
                status: friendlyStatus(machine['state']),
                details: [
                  'الحرارة ${numberValue(machine['temperature']).toStringAsFixed(1)}°C',
                  'التيار ${numberValue(machine['current']).toStringAsFixed(1)}A',
                ],
              ),
            );
          }),
          if (snapshot.alerts.isNotEmpty) ...[
            const SectionHeader('أحدث التنبيهات'),
            ...snapshot.alerts
                .take(3)
                .map((alert) => _AlertPreview(alert: alert)),
          ],
        ],
      ),
    );
  }
}

class _SystemCount extends StatelessWidget {
  const _SystemCount({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _AlertPreview extends StatelessWidget {
  const _AlertPreview({required this.alert});

  final JsonMap alert;

  @override
  Widget build(BuildContext context) {
    final event = textValue(alert['event_name'] ?? alert['event'], 'تنبيه');
    final critical =
        event.toLowerCase().contains('fire') ||
        textValue(alert['status']).toLowerCase() == 'critical';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          leading: Icon(
            critical
                ? Icons.local_fire_department_outlined
                : Icons.warning_amber,
            color: critical ? AppColors.danger : AppColors.warning,
          ),
          title: Text(
            event,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            textValue(
              alert['message'],
              textValue(alert['machine_id'] ?? alert['robot_id']),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ),
      ),
    );
  }
}
