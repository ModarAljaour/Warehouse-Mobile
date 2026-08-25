import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/warehouse_data.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiService {
  ApiService({this.baseUrl = 'https://api.syrian-dev.com'});

  final String baseUrl;
  String? accessToken;

  Uri get websocketUri {
    final uri = Uri.parse(baseUrl);
    return uri.replace(
      scheme: uri.scheme == 'https' ? 'wss' : 'ws',
      path: '/ws/sensors',
      query: null,
    );
  }

  Future<String> login(String username, String password) async {
    final data = await _request(
      'POST',
      '/api/auth/login',
      body: {'username': username, 'password': password},
    );
    final token = textValue(asJsonMap(data)['access_token'], '');
    if (token.isEmpty) throw ApiException('لم يرسل الخادم رمز الدخول');
    accessToken = token;
    return token;
  }

  Future<JsonMap> health() async =>
      asJsonMap(await _request('GET', '/api/health'));

  Future<JsonMap> dashboard() async =>
      asJsonMap(await _request('GET', '/api/dashboard'));

  Future<JsonMap> stats() async =>
      asJsonMap(await _request('GET', '/api/stats'));

  Future<Map<String, JsonMap>> sensors() async =>
      asRecordMap(await _request('GET', '/api/environment-sensors'));

  Future<SensorHistory> sensorHistory(
    String sensorId, {
    required int hours,
    int limit = 300,
  }) async {
    final data = await _request(
      'GET',
      '/api/history/environment-sensors/$sensorId?hours=$hours&limit=$limit',
    );
    return SensorHistory.fromJson(asJsonMap(data));
  }

  Future<Map<String, JsonMap>> devices() async =>
      asRecordMap(await _request('GET', '/api/devices'));

  Future<List<JsonMap>> alerts() async =>
      asJsonList(await _request('GET', '/api/alerts'));

  Future<JsonMap> toggleDevice(String deviceId, bool enabled) async =>
      asJsonMap(
        await _request(
          'POST',
          '/api/devices/$deviceId/toggle',
          body: {'enabled': enabled},
        ),
      );

  Future<JsonMap> emergency(String action) async => asJsonMap(
    await _request('POST', '/api/emergency/${action.toLowerCase()}'),
  );

  Future<JsonMap> robotCommand(String robotId, String action) async =>
      asJsonMap(
        await _request(
          'POST',
          '/api/robots/$robotId/command/${action.toLowerCase()}',
        ),
      );

  Future<Object?> _request(String method, String path, {JsonMap? body}) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.openUrl(method, Uri.parse('$baseUrl$path'));
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      if (accessToken != null) {
        request.headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer $accessToken',
        );
      }
      if (body != null) request.write(jsonEncode(body));
      final response = await request.close().timeout(
        const Duration(seconds: 12),
      );
      final text = await utf8.decoder.bind(response).join();
      final decoded = text.isEmpty ? <String, dynamic>{} : jsonDecode(text);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final detail = textValue(
          asJsonMap(decoded)['detail'],
          'تعذر تنفيذ الطلب',
        );
        throw ApiException(detail, statusCode: response.statusCode);
      }
      return decoded;
    } on SocketException {
      throw ApiException('تعذر الاتصال بالخادم');
    } on TimeoutException {
      throw ApiException('انتهت مهلة الاتصال بالخادم');
    } on FormatException {
      throw ApiException('استجابة الخادم غير صالحة');
    } finally {
      client.close(force: true);
    }
  }
}
