typedef JsonMap = Map<String, dynamic>;

JsonMap asJsonMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return <String, dynamic>{};
}

Map<String, JsonMap> asRecordMap(Object? value) {
  final source = asJsonMap(value);
  return source.map((key, item) => MapEntry(key, asJsonMap(item)));
}

List<JsonMap> asJsonList(Object? value) {
  if (value is! List) return <JsonMap>[];
  return value.map(asJsonMap).toList();
}

double numberValue(Object? value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

bool boolValue(Object? value, [bool fallback = false]) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().toLowerCase();
  if (text == 'true') return true;
  if (text == 'false') return false;
  return fallback;
}

String textValue(Object? value, [String fallback = '--']) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? fallback : text;
}

class WarehouseSnapshot {
  WarehouseSnapshot({
    required this.machines,
    required this.robots,
    required this.forklifts,
    required this.environmentSensors,
    required this.robotWeights,
    required this.devices,
    required this.alerts,
  });

  factory WarehouseSnapshot.empty() => WarehouseSnapshot(
    machines: {},
    robots: {},
    forklifts: {},
    environmentSensors: {},
    robotWeights: {},
    devices: {},
    alerts: [],
  );

  factory WarehouseSnapshot.fromJson(JsonMap json) => WarehouseSnapshot(
    machines: asRecordMap(json['machines']),
    robots: asRecordMap(json['robots']),
    forklifts: asRecordMap(json['forklifts']),
    environmentSensors: asRecordMap(json['environment_sensors']),
    robotWeights: asRecordMap(json['robot_weights']),
    devices: asRecordMap(json['devices']),
    alerts: asJsonList(json['alerts']),
  );

  final Map<String, JsonMap> machines;
  final Map<String, JsonMap> robots;
  final Map<String, JsonMap> forklifts;
  final Map<String, JsonMap> environmentSensors;
  final Map<String, JsonMap> robotWeights;
  final Map<String, JsonMap> devices;
  final List<JsonMap> alerts;
}
