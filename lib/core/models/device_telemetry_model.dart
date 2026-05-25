class DeviceTelemetry {
  final String deviceId;
  final int sequence;
  final int timestamp;
  final double lat;
  final double lng;
  final double accuracyMeters;
  final double speedKmh;
  final double heading;
  final bool gpsFix;
  final int satellites;
  final double vehicleVoltage;
  final int backupBatteryPercent;
  final bool externalPower;
  final bool ignition;
  final bool movement;
  final bool panicButton;
  final bool tamper;
  final bool humo;
  final bool sirena;
  final bool cortaCorriente;
  final int rssi;
  final bool online;
  final String firmwareVersion;
  final String hardwareVersion;

  const DeviceTelemetry({
    required this.deviceId,
    required this.sequence,
    required this.timestamp,
    required this.lat,
    required this.lng,
    required this.accuracyMeters,
    required this.speedKmh,
    required this.heading,
    required this.gpsFix,
    required this.satellites,
    required this.vehicleVoltage,
    required this.backupBatteryPercent,
    required this.externalPower,
    required this.ignition,
    required this.movement,
    required this.panicButton,
    required this.tamper,
    required this.humo,
    required this.sirena,
    required this.cortaCorriente,
    required this.rssi,
    required this.online,
    required this.firmwareVersion,
    required this.hardwareVersion,
  });

  factory DeviceTelemetry.fromMap(String deviceId, Map<dynamic, dynamic> data) {
    final location = _map(data['location']);
    final power = _map(data['power']);
    final signals = _map(data['signals']);
    final actuators = _map(data['actuators']);
    final network = _map(data['network']);

    return DeviceTelemetry(
      deviceId: deviceId,
      sequence: _asInt(data['sequence']),
      timestamp: _asInt(data['timestamp']),
      lat: _asDouble(location['lat'] ?? data['latitud']),
      lng: _asDouble(location['lng'] ?? data['longitud']),
      accuracyMeters: _asDouble(location['accuracyMeters']),
      speedKmh: _asDouble(location['speedKmh'] ?? data['velocidad']),
      heading: _asDouble(location['heading']),
      gpsFix: location['gpsFix'] != false,
      satellites: _asInt(location['satellites']),
      vehicleVoltage: _asDouble(power['vehicleVoltage'] ?? data['voltaje']),
      backupBatteryPercent: _asInt(power['backupBatteryPercent']),
      externalPower: power['externalPower'] != false,
      ignition: signals['ignition'] == true,
      movement: signals['movement'] == true,
      panicButton: signals['panicButton'] == true,
      tamper: signals['tamper'] == true,
      humo: actuators['humo'] == true || data['humo'] == true,
      sirena: actuators['sirena'] == true || data['sirenaActiva'] == true,
      cortaCorriente:
          actuators['cortaCorriente'] == true || data['cortaCorriente'] == true,
      rssi: _asInt(network['rssi']),
      online: network['online'] != false,
      firmwareVersion: data['firmwareVersion']?.toString() ?? '',
      hardwareVersion: data['hardwareVersion']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'sequence': sequence,
    'timestamp': timestamp,
    'location': {
      'lat': lat,
      'lng': lng,
      'accuracyMeters': accuracyMeters,
      'speedKmh': speedKmh,
      'heading': heading,
      'gpsFix': gpsFix,
      'satellites': satellites,
    },
    'power': {
      'vehicleVoltage': vehicleVoltage,
      'backupBatteryPercent': backupBatteryPercent,
      'externalPower': externalPower,
    },
    'signals': {
      'ignition': ignition,
      'movement': movement,
      'panicButton': panicButton,
      'tamper': tamper,
    },
    'actuators': {
      'humo': humo,
      'sirena': sirena,
      'cortaCorriente': cortaCorriente,
    },
    'network': {'rssi': rssi, 'online': online},
    'firmwareVersion': firmwareVersion,
    'hardwareVersion': hardwareVersion,
    'latitud': lat,
    'longitud': lng,
    'velocidad': speedKmh,
    'voltaje': vehicleVoltage,
    'humo': humo,
    'sirenaActiva': sirena,
    'cortaCorriente': cortaCorriente,
    'ultimaActualizacion': timestamp,
  };

  static Map<dynamic, dynamic> _map(dynamic value) {
    if (value is Map) return Map<dynamic, dynamic>.from(value);
    return const {};
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
