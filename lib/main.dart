import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/shell_screen.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'state/warehouse_controller.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await NotificationService.instance.initialize();
  } catch (error) {
    debugPrint('Firebase initialization failed: $error');
  }
  runApp(const WarehouseApp());
}

class WarehouseApp extends StatefulWidget {
  const WarehouseApp({super.key});

  @override
  State<WarehouseApp> createState() => _WarehouseAppState();
}

class _WarehouseAppState extends State<WarehouseApp> {
  final ApiService _api = ApiService();
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();
  StreamSubscription<WarehouseNotification>? _notificationSubscription;
  String? _token;

  @override
  void initState() {
    super.initState();
    _notificationSubscription = NotificationService
        .instance
        .foregroundNotifications
        .listen((notification) {
          _messengerKey.currentState
            ?..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(notification.body),
                  ],
                ),
              ),
            );
        });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WarehouseTwin',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _messengerKey,
      theme: AppTheme.dark,
      locale: const Locale('ar'),
      home: _token == null
          ? LoginScreen(
              api: _api,
              onAuthenticated: (token) => setState(() => _token = token),
            )
          : WarehouseShell(
              controller: WarehouseController(_api)..start(),
              onLogout: () => setState(() => _token = null),
            ),
    );
  }
}
