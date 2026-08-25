import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/warehouse_data.dart';
import '../services/api_service.dart';

class WarehouseController extends ChangeNotifier {
  WarehouseController(this.api);

  final ApiService api;
  WarehouseSnapshot snapshot = WarehouseSnapshot.empty();
  JsonMap stats = {};
  bool loading = true;
  bool websocketConnected = false;
  bool actionInProgress = false;
  String? errorMessage;
  DateTime? lastUpdated;

  WebSocket? _socket;
  Timer? _refreshTimer;
  Timer? _reconnectTimer;
  bool _disposed = false;

  void start() {
    refresh();
    _connectWebSocket();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => refresh(silent: true),
    );
  }

  Future<void> refresh({bool silent = false}) async {
    if (!silent) {
      loading = true;
      notifyListeners();
    }
    try {
      final results = await Future.wait([api.dashboard(), api.stats()]);
      snapshot = WarehouseSnapshot.fromJson(results[0]);
      stats = results[1];
      errorMessage = null;
      lastUpdated = DateTime.now();
    } on ApiException catch (error) {
      errorMessage = error.message;
    } finally {
      loading = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<String> setDeviceEnabled(String deviceId, bool enabled) async {
    return _runAction(() async {
      final response = await api.toggleDevice(deviceId, enabled);
      final status = textValue(response['status']);
      final device = asJsonMap(response['device']);
      snapshot.devices[deviceId] = device;
      await refresh(silent: true);
      return status == 'COMMAND_QUEUED'
          ? 'تم حفظ الأمر وسيُنفذ عند عودة اتصال الجهاز'
          : enabled
          ? 'تم إرسال أمر التشغيل'
          : 'تم إرسال أمر الإيقاف';
    });
  }

  Future<String> sendGlobalCommand(String action) async {
    return _runAction(() async {
      await api.emergency(action);
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await refresh(silent: true);
      return switch (action.toLowerCase()) {
        'stop' => 'تم إرسال الإيقاف الشامل',
        'resume' => 'تم إرسال الاستئناف الشامل',
        'reset' => 'تم إرسال إعادة الضبط',
        'charge' => 'تم إرسال أمر الشحن',
        _ => 'تم إرسال الأمر',
      };
    });
  }

  Future<String> sendRobotCommand(String robotId, String action) async {
    return _runAction(() async {
      await api.robotCommand(robotId, action);
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await refresh(silent: true);
      return switch (action.toLowerCase()) {
        'stop' => 'تم إرسال أمر إيقاف $robotId',
        'resume' => 'تم إرسال أمر استئناف $robotId',
        'charge' => 'تم إرسال أمر شحن $robotId',
        _ => 'تم إرسال الأمر إلى $robotId',
      };
    });
  }

  Future<String> _runAction(Future<String> Function() task) async {
    actionInProgress = true;
    notifyListeners();
    try {
      return await task();
    } on ApiException catch (error) {
      throw ApiException(error.message, statusCode: error.statusCode);
    } finally {
      actionInProgress = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> _connectWebSocket() async {
    _reconnectTimer?.cancel();
    try {
      _socket = await WebSocket.connect(
        api.websocketUri.toString(),
      ).timeout(const Duration(seconds: 12));
      websocketConnected = true;
      errorMessage = null;
      notifyListeners();
      _socket!.listen(
        _handleSocketMessage,
        onDone: _handleSocketClosed,
        onError: (_) => _handleSocketClosed(),
        cancelOnError: true,
      );
    } catch (_) {
      _handleSocketClosed();
    }
  }

  void _handleSocketMessage(Object? message) {
    try {
      final envelope = asJsonMap(jsonDecode(message.toString()));
      final type = textValue(envelope['stream_type'], '');
      final data = asJsonMap(envelope['data']);
      switch (type) {
        case 'snapshot':
          snapshot = WarehouseSnapshot.fromJson(data);
        case 'machine_telemetry':
          snapshot.machines[textValue(data['machine_id'])] = data;
        case 'robot_telemetry':
          snapshot.robots[textValue(data['robot_id'])] = data;
        case 'forklift_telemetry':
          snapshot.forklifts[textValue(data['forklift_id'])] = data;
        case 'environment_telemetry':
          snapshot.environmentSensors[textValue(data['sensor_id'])] = data;
        case 'robot_weight':
          snapshot.robotWeights[textValue(data['robot_id'])] = data;
        case 'device_command':
          snapshot.devices[textValue(data['device_id'])] = data;
        case 'machine_alert':
        case 'robot_alert':
          snapshot.alerts.insert(0, data);
      }
      lastUpdated = DateTime.now();
      if (!_disposed) notifyListeners();
    } catch (_) {
      refresh(silent: true);
    }
  }

  void _handleSocketClosed() {
    websocketConnected = false;
    _socket = null;
    if (!_disposed) {
      notifyListeners();
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(const Duration(seconds: 5), _connectWebSocket);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _refreshTimer?.cancel();
    _reconnectTimer?.cancel();
    _socket?.close();
    super.dispose();
  }
}
