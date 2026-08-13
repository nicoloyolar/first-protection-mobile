class EstadoDispositivo {
  final String idDispositivo;
  final int ultimaActualizacion;
  final double latitud;
  final double longitud;
  final double velocidad;
  final bool cortaCorriente;
  final bool protocoloActivo;
  final bool humoDesplegado;
  final bool sirenaActiva;
  final double voltaje;
  final bool humoActivo;

  /// Modo del sistema ('normal' o 'armed' por ahora — ver "Modos Del
  /// Sistema" en docs/physical-device-integration.md, que define más
  /// estados a futuro). `armedAt*` es la posición del vehículo en el
  /// momento en que se armó, usada como ancla para detectar movimiento
  /// mientras está estacionado.
  final String systemMode;
  final double? armedAtLat;
  final double? armedAtLng;

  /// Geocerca: zona fija configurable por el usuario, independiente del
  /// modo armado y de la ubicación del teléfono — ver docs/plan-de-
  /// trabajo.md Pista A. Se mantiene activa (o no) explícitamente por el
  /// usuario, sin depender de si el vehículo está "armado" en un momento
  /// dado.
  final bool geofenceEnabled;
  final double? geofenceCenterLat;
  final double? geofenceCenterLng;
  final double? geofenceRadiusMeters;

  bool get armado => systemMode == 'armed';

  EstadoDispositivo({
    required this.idDispositivo,
    required this.ultimaActualizacion,
    required this.latitud,
    required this.longitud,
    required this.velocidad,
    required this.cortaCorriente,
    required this.protocoloActivo,
    required this.humoDesplegado,
    required this.sirenaActiva,
    required this.voltaje,
    required this.humoActivo,
    this.systemMode = 'normal',
    this.armedAtLat,
    this.armedAtLng,
    this.geofenceEnabled = false,
    this.geofenceCenterLat,
    this.geofenceCenterLng,
    this.geofenceRadiusMeters,
  });

  factory EstadoDispositivo.fromMap(
    String idDispositivo,
    Map<dynamic, dynamic> data,
  ) {
    final armedAt = data['armedAt'] is Map
        ? Map<dynamic, dynamic>.from(data['armedAt'] as Map)
        : null;
    final geofence = data['geofence'] is Map
        ? Map<dynamic, dynamic>.from(data['geofence'] as Map)
        : null;

    return EstadoDispositivo(
      idDispositivo: idDispositivo,
      ultimaActualizacion: _asInt(data['ultimaActualizacion']),
      latitud: _asDouble(data['latitud']),
      longitud: _asDouble(data['longitud']),
      velocidad: _asDouble(data['velocidad']),
      cortaCorriente: data['cortaCorriente'] ?? false,
      protocoloActivo: data['protocoloActivo'] ?? false,
      humoDesplegado: data['humoDesplegado'] ?? false,
      sirenaActiva: data['sirenaActiva'] ?? false,
      voltaje: _asDouble(data['voltaje']),
      humoActivo: data['humo'] ?? false,
      systemMode: data['systemMode']?.toString() ?? 'normal',
      armedAtLat: armedAt == null ? null : _asDouble(armedAt['lat']),
      armedAtLng: armedAt == null ? null : _asDouble(armedAt['lng']),
      geofenceEnabled: geofence?['enabled'] == true,
      geofenceCenterLat: geofence == null || geofence['centerLat'] == null
          ? null
          : _asDouble(geofence['centerLat']),
      geofenceCenterLng: geofence == null || geofence['centerLng'] == null
          ? null
          : _asDouble(geofence['centerLng']),
      geofenceRadiusMeters: geofence == null || geofence['radiusMeters'] == null
          ? null
          : _asDouble(geofence['radiusMeters']),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is EstadoDispositivo &&
        other.idDispositivo == idDispositivo &&
        other.ultimaActualizacion == ultimaActualizacion &&
        other.latitud == latitud &&
        other.longitud == longitud &&
        other.velocidad == velocidad &&
        other.cortaCorriente == cortaCorriente &&
        other.protocoloActivo == protocoloActivo &&
        other.humoDesplegado == humoDesplegado &&
        other.sirenaActiva == sirenaActiva &&
        other.voltaje == voltaje &&
        other.humoActivo == humoActivo &&
        other.systemMode == systemMode &&
        other.armedAtLat == armedAtLat &&
        other.armedAtLng == armedAtLng &&
        other.geofenceEnabled == geofenceEnabled &&
        other.geofenceCenterLat == geofenceCenterLat &&
        other.geofenceCenterLng == geofenceCenterLng &&
        other.geofenceRadiusMeters == geofenceRadiusMeters;
  }

  @override
  int get hashCode => Object.hash(
    idDispositivo,
    ultimaActualizacion,
    latitud,
    longitud,
    velocidad,
    cortaCorriente,
    protocoloActivo,
    humoDesplegado,
    sirenaActiva,
    voltaje,
    humoActivo,
    systemMode,
    armedAtLat,
    armedAtLng,
    Object.hash(
      geofenceEnabled,
      geofenceCenterLat,
      geofenceCenterLng,
      geofenceRadiusMeters,
    ),
  );

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
