
class EstadoDispositivo {
  final String idDispositivo;
  final int ultimaActualizacion;   
  
  final double latitud;
  final double longitud;
  final double velocidad;    
  final bool cortaCorriente;     
  final bool humoDesplegado; 
  final bool sirenaActiva;   

  EstadoDispositivo({
    required this.idDispositivo,
    required this.ultimaActualizacion,
    required this.latitud,
    required this.longitud,
    required this.velocidad,
    required this.cortaCorriente,
    required this.humoDesplegado,
    required this.sirenaActiva,
  });

  factory EstadoDispositivo.fromMap(Map<dynamic, dynamic> data) {
    return EstadoDispositivo(
      idDispositivo           : data['idDispositivo'] ?? '',
      ultimaActualizacion     : data['ultimaActualizacion'] ?? 0,
      latitud                 : (data['latitud'] ?? 0.0).toDouble(),
      longitud                : (data['longitud'] ?? 0.0).toDouble(),
      velocidad               : (data['velocidad'] ?? 0.0).toDouble(),
      cortaCorriente          : data['cortaCorriente'] ?? false,
      humoDesplegado          : data['humoDesplegado'] ?? false,
      sirenaActiva            : data['sirenaActiva'] ?? false,
    );
  }
}