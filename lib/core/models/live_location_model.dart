/// Ubicación en vivo del usuario (telefono), separada de la ubicación del
/// vehículo. Ver docs/physical-device-integration.md — "Principio Central":
/// el vehículo la reporta el STM, el usuario la reporta su teléfono, y nunca
/// deben confundirse ni sobreescribirse entre sí.
class LiveLocation {
  final double lat;
  final double lng;
  final double? accuracy;
  final int timestamp;

  const LiveLocation({
    required this.lat,
    required this.lng,
    this.accuracy,
    required this.timestamp,
  });

  factory LiveLocation.fromMap(Map<dynamic, dynamic> data) {
    return LiveLocation(
      lat: _asDouble(data['lat']),
      lng: _asDouble(data['lng']),
      accuracy: data['accuracy'] == null ? null : _asDouble(data['accuracy']),
      timestamp: _asInt(data['timestamp']),
    );
  }

  Map<String, dynamic> toMap() => {
    'lat': lat,
    'lng': lng,
    if (accuracy != null) 'accuracy': accuracy,
    'timestamp': timestamp,
  };

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
