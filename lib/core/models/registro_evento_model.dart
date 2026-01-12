enum TipoEvento {
  alarmaActivada,    
  comandoRemoto,     
  infoSistema,       
  salidaZonaSegura   
}

class RegistroEvento {
  final String id;
  final String idVehiculo; 
  final DateTime fecha;    
  final TipoEvento tipo;
  final String titulo;       
  final String descripcion;  
  final String actor;       
  final double latitud;
  final double longitud;

  RegistroEvento({
    required this.id,
    required this.idVehiculo,
    required this.fecha,
    required this.tipo,
    required this.titulo,
    required this.descripcion,
    required this.actor,
    required this.latitud,
    required this.longitud,
  });
}