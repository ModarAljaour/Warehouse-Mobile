import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../state/warehouse_controller.dart';
import 'alerts_screen.dart';
import 'control_screen.dart';
import 'dashboard_screen.dart';
import 'fleet_screen.dart';
import 'sensors_screen.dart';

class WarehouseShell extends StatefulWidget {
  const WarehouseShell({
    super.key,
    required this.controller,
    required this.onLogout,
  });

  final WarehouseController controller;
  final VoidCallback onLogout;

  @override
  State<WarehouseShell> createState() => _WarehouseShellState();
}

class _WarehouseShellState extends State<WarehouseShell> {
  int _index = 0;

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final controller = widget.controller;
          final pages = [
            DashboardScreen(
              controller: controller,
              onLogout: widget.onLogout,
            ),
            SensorsScreen(controller: controller),
            FleetScreen(controller: controller),
            ControlScreen(controller: controller),
            AlertsScreen(controller: controller),
          ];
          return Scaffold(
            body: SafeArea(
              child: controller.loading && controller.snapshot.devices.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : IndexedStack(index: _index, children: pages),
            ),
            bottomNavigationBar: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: NavigationBar(
                selectedIndex: _index,
                onDestinationSelected: (value) =>
                    setState(() => _index = value),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.grid_view_outlined),
                    selectedIcon: Icon(Icons.grid_view, color: AppColors.primary),
                    label: 'الرئيسية',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.sensors_outlined),
                    selectedIcon: Icon(Icons.sensors, color: AppColors.primary),
                    label: 'الحساسات',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.smart_toy_outlined),
                    selectedIcon: Icon(Icons.smart_toy, color: AppColors.primary),
                    label: 'الروبوتات',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.tune_outlined),
                    selectedIcon: Icon(Icons.tune, color: AppColors.primary),
                    label: 'التحكم',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.notifications_none),
                    selectedIcon: Icon(
                      Icons.notifications,
                      color: AppColors.primary,
                    ),
                    label: 'التنبيهات',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
