import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class WarehouseNotification {
  const WarehouseNotification({required this.title, required this.body});

  final String title;
  final String body;
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  static const _fireChannel = AndroidNotificationChannel(
    'warehouse_fire_alerts',
    'إنذارات الحريق',
    description: 'تنبيهات الحريق والطوارئ الحرجة داخل المستودع',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final StreamController<WarehouseNotification> _foregroundController =
      StreamController<WarehouseNotification>.broadcast();

  Stream<WarehouseNotification> get foregroundNotifications =>
      _foregroundController.stream;

  Future<void> initialize() async {
    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
      ),
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_fireChannel);

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    await messaging.subscribeToTopic('warehouse_alerts');

    FirebaseMessaging.onMessage.listen((message) async {
      _publishMessage(message);
      await _showForegroundNotification(message);
    });
    FirebaseMessaging.onMessageOpenedApp.listen(_publishMessage);
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title =
        notification?.title ??
        message.data['title']?.toString() ??
        'إنذار حريق';
    final body =
        notification?.body ??
        message.data['body']?.toString() ??
        message.data['message']?.toString() ??
        'تم اكتشاف حالة طارئة داخل المستودع';

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'warehouse_fire_alerts',
          'إنذارات الحريق',
          channelDescription: 'تنبيهات الحريق والطوارئ الحرجة داخل المستودع',
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
          playSound: true,
          enableVibration: true,
          visibility: NotificationVisibility.public,
        ),
      ),
      payload: message.data['event']?.toString() ?? 'FIRE_EMERGENCY',
    );
  }

  void _publishMessage(RemoteMessage message) {
    final notification = message.notification;
    final title =
        notification?.title ??
        message.data['title']?.toString() ??
        'تنبيه المستودع';
    final body =
        notification?.body ??
        message.data['body']?.toString() ??
        message.data['message']?.toString() ??
        'وصل تحديث جديد من المستودع';
    _foregroundController.add(WarehouseNotification(title: title, body: body));
  }
}
