import 'package:flutter_test/flutter_test.dart';
import 'package:warehouse_mobile/main.dart';

void main() {
  testWidgets('login screen renders', (tester) async {
    await tester.pumpWidget(const WarehouseApp());

    expect(find.text('WarehouseTwin'), findsOneWidget);
    expect(find.text('تسجيل الدخول'), findsOneWidget);
    expect(find.text('نظام التوأمة الرقمية للمستودع'), findsOneWidget);
  });
}
