
class Vehiculo {
  final String idVehiculo;          
  final String idDispositivo;   
  final String idDueno;     
  final List<String> compartidoCon; 
  
  final String patente;      
  final String marca;      
  final String modelo;       
  final String anio;
  final String color;
  final String alias;       

  Vehiculo({
    required this.idVehiculo,
    required this.idDispositivo,
    required this.idDueno,
    this.compartidoCon = const [],
    required this.patente,
    required this.marca,
    required this.modelo,
    required this.anio,
    required this.color,
    required this.alias,
  });
  factory Vehiculo.fromMap(Map<dynamic, dynamic> data) {
    return Vehiculo(
      idVehiculo      : data['idVehiculo'] ?? '',
      idDispositivo   : data['idDispositivo'] ?? '', 
      idDueno         : data['idDueno'] ?? '',
      compartidoCon   : List<String>.from(data['compartidoCon'] ?? []),
      patente         : data['patente'] ?? 'S/P',
      marca           : data['marca'] ?? '',
      modelo          : data['modelo'] ?? '',
      anio            : data['anio'] ?? '',
      color           : data['color'] ?? '',
      alias           : data['alias'] ?? '',
    );
  }
}