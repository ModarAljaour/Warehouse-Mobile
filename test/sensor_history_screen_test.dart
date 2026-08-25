import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warehouse_mobile/core/app_theme.dart';
import 'package:warehouse_mobile/models/warehouse_data.dart';
import 'package:warehouse_mobile/screens/sensor_history_screen.dart';
import 'package:warehouse_mobile/services/api_service.dart';

void main() {
  setUpAll(() async {
    final arabic = FontLoader('NotoSansArabic')
      ..addFont(rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/NotoSansArabic-Bold.ttf'));
    final latin = FontLoader('NotoSans')
      ..addFont(rootBundle.load('assets/fonts/NotoSans-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/NotoSans-Bold.ttf'));
    await Future.wait([arabic.load(), latin.load()]);
  });

  testWidgets('sensor history renders and changes metric and range', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = _FakeApiService();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: SensorHistoryScreen(
          api: api,
          initialSensorId: 'sensor_01',
          sensors: const {
            'sensor_01': {
              'sensor_id': 'sensor_01',
              'temperature': 35.5,
              'humidity': 55.0,
              'online': true,
            },
            'sensor_02': {
              'sensor_id': 'sensor_02',
              'temperature': 31.0,
              'humidity': 58.0,
              'online': true,
            },
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('سجل الحساس'), findsOneWidget);
    expect(find.text('12 قراءة'), findsOneWidget);
    expect(find.text('35.5°C'), findsAtLeastNWidgets(1));
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/sensor_history_mobile.png'),
    );

    await tester.tap(find.text('الرطوبة'));
    await tester.pumpAndSettle();
    expect(find.text('55.0%'), findsAtLeastNWidgets(1));

    await tester.tap(find.text('6 ساعات'));
    await tester.pumpAndSettle();
    expect(api.lastHours, 6);
    expect(tester.takeException(), isNull);
  });
}

class _FakeApiService extends ApiService {
  int lastHours = 0;

  @override
  Future<SensorHistory> sensorHistory(
    String sensorId, {
    required int hours,
    int limit = 300,
  }) async {
    lastHours = hours;
    final start = DateTime(2026, 8, 26, 8);
    return SensorHistory(
      sensorId: sensorId,
      hours: hours,
      points: List.generate(
        12,
        (index) => SensorHistoryPoint(
          time: start.add(Duration(minutes: index * 5)),
          temperature: 30 + index * 0.5,
          humidity: 60 - index * 0.45,
        ),
      ),
    );
  }
}
