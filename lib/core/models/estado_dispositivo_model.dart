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
  });

  factory EstadoDispositivo.fromMap(
    String idDispositivo,
    Map<dynamic, dynamic> data,
  ) {
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
    );
  }

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
