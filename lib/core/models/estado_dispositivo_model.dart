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

  factory EstadoDispositivo.fromMap(String idDispositivo, Map<dynamic, dynamic> data) {
    return EstadoDispositivo(
      idDispositivo: idDispositivo,
      ultimaActualizacion: data['ultimaActualizacion'] ?? 0,
      latitud: (data['latitud'] ?? 0.0).toDouble(),
      longitud: (data['longitud'] ?? 0.0).toDouble(),
      velocidad: (data['velocidad'] ?? 0.0).toDouble(),
      cortaCorriente: data['cortaCorriente'] ?? false,
      protocoloActivo: data['protocoloActivo'] ?? false,
      humoDesplegado: data['humoDesplegado'] ?? false,
      sirenaActiva: data['sirenaActiva'] ?? false,
      voltaje: (data['voltaje'] ?? 0.0).toDouble(),
      humoActivo: data['humo'] ?? false, 
    );
  }
}
