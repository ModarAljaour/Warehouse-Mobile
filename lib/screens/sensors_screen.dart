import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/warehouse_data.dart';
import '../state/warehouse_controller.dart';
import '../widgets/warehouse_widgets.dart';
import 'sensor_history_screen.dart';

enum _SensorFilter { all, temperature, battery }

class SensorsScreen extends StatefulWidget {
  const SensorsScreen({super.key, required this.controller});

  final WarehouseController controller;

  @override
  State<SensorsScreen> createState() => _SensorsScreenState();
}

class _SensorsScreenState extends State<SensorsScreen> {
  _SensorFilter _filter = _SensorFilter.all;

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.controller.snapshot;
    final items = <Widget>[];

    if (_filter != _SensorFilter.battery) {
      for (final entry in snapshot.machines.entries) {
        final machine = entry.value;
        final value = numberValue(machine['temperature']);
        items.add(
          _TelemetryCard(
            id: entry.key,
            subtitle: friendlyStatus(machine['state']),
            value: '${value.toStringAsFixed(1)}°C',
            progress: value / 120,
            online: boolValue(machine['online']),
            icon: Icons.thermostat,
          ),
        );
      }
      for (final entry in snapshot.environmentSensors.entries) {
        final sensor = entry.value;
        final value = numberValue(sensor['temperature']);
        items.add(
          _TelemetryCard(
            id: entry.key,
            subtitle:
                'رطوبة ${numberValue(sensor['humidity']).toStringAsFixed(0)}%',
            value: '${value.toStringAsFixed(1)}°C',
            progress: value / 120,
            online: boolValue(sensor['online']),
            icon: Icons.device_thermostat,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SensorHistoryScreen(
                  api: widget.controller.api,
                  sensors: snapshot.environmentSensors,
                  initialSensorId: entry.key,
                ),
              ),
            ),
          ),
        );
      }
    }

    if (_filter != _SensorFilter.temperature) {
      for (final entry in snapshot.robots.entries) {
        final robot = entry.value;
        final value = numberValue(robot['battery']);
        items.add(
          _TelemetryCard(
            id: entry.key,
            subtitle: friendlyStatus(robot['status']),
            value: '${value.toStringAsFixed(1)}%',
            progress: value / 100,
            online: boolValue(robot['online']),
            warning: value <= 20 || boolValue(robot['low_battery']),
            icon: Icons.battery_charging_full,
          ),
        );
      }
      for (final entry in snapshot.forklifts.entries) {
        final forklift = entry.value;
        final value = numberValue(forklift['battery']);
        items.add(
          _TelemetryCard(
            id: entry.key,
            subtitle: friendlyStatus(forklift['status']),
            value: '${value.toStringAsFixed(1)}%',
            progress: value / 100,
            online: boolValue(forklift['online']),
            warning: value <= 20,
            icon: Icons.battery_charging_full,
          ),
        );
      }
    }

    return RefreshIndicator(
      onRefresh: widget.controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الحساسات والمعدات',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          widget.controller.websocketConnected
                              ? 'WebSocket — بيانات حية'
                              : 'WebSocket — جاري إعادة الاتصال',
                          style: TextStyle(
                            color: widget.controller.websocketConnected
                                ? AppColors.success
                                : AppColors.warning,
                            fontSize: 11,
                          ),
                        ),
                      ],
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
                  color: AppColors.dangerDark,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${snapshot.alerts.length} تنبيه',
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _FilterButton(
                label: 'الكل',
                selected: _filter == _SensorFilter.all,
                onPressed: () => setState(() => _filter = _SensorFilter.all),
              ),
              const SizedBox(width: 8),
              _FilterButton(
                label: 'حرارة',
                selected: _filter == _SensorFilter.temperature,
                onPressed: () =>
                    setState(() => _filter = _SensorFilter.temperature),
              ),
              const SizedBox(width: 8),
              _FilterButton(
                label: 'بطارية',
                selected: _filter == _SensorFilter.battery,
                onPressed: () =>
                    setState(() => _filter = _SensorFilter.battery),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (items.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Text(
                  'لا توجد قراءات بعد',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            )
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: item,
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(62, 36),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        foregroundColor: selected ? AppColors.primary : AppColors.muted,
        backgroundColor: selected
            ? AppColors.primary.withValues(alpha: 0.13)
            : Colors.transparent,
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
        ),
        shape: const StadiumBorder(),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }
}

class _TelemetryCard extends StatelessWidget {
  const _TelemetryCard({
    required this.id,
    required this.subtitle,
    required this.value,
    required this.progress,
    required this.online,
    required this.icon,
    this.warning = false,
    this.onTap,
  });

  final String id;
  final String subtitle;
  final String value;
  final double progress;
  final bool online;
  final bool warning;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final unhealthy = !online || warning;
    final color = unhealthy ? AppColors.danger : AppColors.primary;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: unhealthy
              ? AppColors.danger.withValues(alpha: 0.5)
              : AppColors.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      id.toUpperCase(),
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress.clamp(0, 1),
                      minHeight: 5,
                      borderRadius: BorderRadius.circular(4),
                      color: color,
                      backgroundColor: AppColors.border,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        value,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          color: color,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        online ? (warning ? 'تحذير' : 'متصل') : 'متوقف',
                        style: TextStyle(color: color, fontSize: 9),
                      ),
                    ],
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: 7),
                    const Icon(
                      Icons.chevron_left,
                      color: AppColors.muted,
                      size: 18,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
