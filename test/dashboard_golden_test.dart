import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warehouse_mobile/core/app_theme.dart';
import 'package:warehouse_mobile/models/warehouse_data.dart';
import 'package:warehouse_mobile/screens/dashboard_screen.dart';
import 'package:warehouse_mobile/services/api_service.dart';
import 'package:warehouse_mobile/state/warehouse_controller.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader('NotoSansArabic')
      ..addFont(rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/NotoSansArabic-Bold.ttf'));
    await loader.load();
    final fallbackLoader = FontLoader('NotoSans')
      ..addFont(rootBundle.load('assets/fonts/NotoSans-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/NotoSans-Bold.ttf'));
    await fallbackLoader.load();
  });

  testWidgets('dashboard mobile layout', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = WarehouseController(ApiService());
    controller.snapshot = WarehouseSnapshot.fromJson({
      'machines': {
        'arm_1': {
          'machine_id': 'arm_1',
          'temperature': 54.2,
          'current': 8.4,
          'state': 'normal',
          'online': true,
        },
      },
      'robots': {
        'agv_01': {'robot_id': 'agv_01', 'battery': 78.0, 'status': 'moving', 'online': true},
        'agv_02': {'robot_id': 'agv_02', 'battery': 43.0, 'status': 'idle', 'online': true},
      },
      'forklifts': {
        'forklift_01': {'forklift_id': 'forklift_01', 'battery': 92.0, 'speed': 2.4, 'status': 'moving', 'online': true},
      },
      'environment_sensors': {
        for (var index = 1; index <= 6; index++)
          'sensor_0$index': {'sensor_id': 'sensor_0$index', 'temperature': 31.0 + index, 'humidity': 60.0, 'online': true},
      },
      'robot_weights': {
        'agv_01': {'robot_id': 'agv_01', 'value': 8.0},
        'agv_02': {'robot_id': 'agv_02', 'value': 1.0},
      },
      'devices': {
        'arm_1': {'online': true},
        'agv_01': {'online': true},
        'agv_02': {'online': true},
        'forklift_01': {'online': true},
        'conveyor_01': {'online': false},
      },
      'alerts': [
        {'event_name': 'LOW_BATTERY', 'robot_id': 'agv_02', 'message': 'Robot battery requires attention.'},
      ],
    });
    controller.stats = {
      'machines': {'total': 1, 'online': 1, 'active': 1},
      'robots': {'total': 2, 'online': 2, 'active': 2},
      'forklifts': {'total': 1, 'online': 1, 'active': 1},
      'alerts_count': 1,
      'system_health': 'Excellent',
    };

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: DashboardScreen(controller: controller)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/dashboard_mobile.png'),
    );
  });
}
