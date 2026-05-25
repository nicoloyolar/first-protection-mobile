enum DeviceEventType {
  panicButtonPressed,
  ignitionOn,
  ignitionOff,
  movementDetected,
  vehicleMovedWhileArmed,
  tamperDetected,
  gpsLost,
  gpsRecovered,
  powerDisconnected,
  powerRestored,
  actuatorStateChanged,
  heartbeat,
  commandAck,
}

enum DeviceEventSeverity { info, warning, critical }

class DeviceEvent {
  final String id;
  final String deviceId;
  final DeviceEventType type;
  final DeviceEventSeverity severity;
  final int timestamp;
  final double? lat;
  final double? lng;
  final Map<String, dynamic> metadata;

  const DeviceEvent({
    required this.id,
    required this.deviceId,
    required this.type,
    required this.severity,
    required this.timestamp,
    this.lat,
    this.lng,
    this.metadata = const {},
  });

  factory DeviceEvent.fromMap(
    String id,
    String deviceId,
    Map<dynamic, dynamic> data,
  ) {
    final location = data['location'] is Map
        ? Map<dynamic, dynamic>.from(data['location'] as Map)
        : const <dynamic, dynamic>{};

    return DeviceEvent(
      id: id,
      deviceId: deviceId,
      type: _typeFromString(data['type']?.toString()),
      severity: _severityFromString(data['severity']?.toString()),
      timestamp: _asInt(data['timestamp']),
      lat: _nullableDouble(location['lat'] ?? data['latitud']),
      lng: _nullableDouble(location['lng'] ?? data['longitud']),
      metadata: data['metadata'] is Map
          ? Map<String, dynamic>.from(data['metadata'] as Map)
          : const {},
    );
  }

  Map<String, dynamic> toMap() => {
    'type': type.name,
    'severity': severity.name,
    'timestamp': timestamp,
    if (lat != null && lng != null) 'location': {'lat': lat, 'lng': lng},
    'metadata': metadata,
  };

  static DeviceEventType _typeFromString(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'panicbuttonpressed':
        return DeviceEventType.panicButtonPressed;
      case 'ignitionon':
        return DeviceEventType.ignitionOn;
      case 'ignitionoff':
        return DeviceEventType.ignitionOff;
      case 'movementdetected':
        return DeviceEventType.movementDetected;
      case 'vehiclemovedwhilearmed':
        return DeviceEventType.vehicleMovedWhileArmed;
      case 'tamperdetected':
        return DeviceEventType.tamperDetected;
      case 'gpslost':
        return DeviceEventType.gpsLost;
      case 'gpsrecovered':
        return DeviceEventType.gpsRecovered;
      case 'powerdisconnected':
        return DeviceEventType.powerDisconnected;
      case 'powerrestored':
        return DeviceEventType.powerRestored;
      case 'actuatorstatechanged':
        return DeviceEventType.actuatorStateChanged;
      case 'commandack':
        return DeviceEventType.commandAck;
      default:
        return DeviceEventType.heartbeat;
    }
  }

  static DeviceEventSeverity _severityFromString(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'critical':
        return DeviceEventSeverity.critical;
      case 'warning':
        return DeviceEventSeverity.warning;
      default:
        return DeviceEventSeverity.info;
    }
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double? _nullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
