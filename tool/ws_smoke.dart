import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final socket = await WebSocket.connect(
    'wss://api.syrian-dev.com/ws/sensors',
  ).timeout(const Duration(seconds: 10));

  try {
    final raw = await socket.first.timeout(const Duration(seconds: 10));
    final message = jsonDecode(raw as String) as Map<String, dynamic>;
    final data = message['data'] as Map<String, dynamic>? ?? message;
    stdout.writeln(
      'stream=${message['stream_type'] ?? 'event'} '
      'machines=${_length(data['machines'])} '
      'robots=${_length(data['robots'])} '
      'forklifts=${_length(data['forklifts'])} '
      'sensors=${_length(data['environment_sensors'])}',
    );
  } finally {
    await socket.close();
  }
}

int _length(Object? value) => value is Map ? value.length : 0;
