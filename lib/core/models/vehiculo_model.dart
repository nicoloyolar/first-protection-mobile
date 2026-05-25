class Vehiculo {
  final String idVehiculo;
  final String idDispositivo;
  final String idDueno;
  final String idPropietario;
  final String organizationId;
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
    String? idPropietario,
    this.organizationId = 'first-protection',
    this.compartidoCon = const [],
    required this.patente,
    required this.marca,
    required this.modelo,
    required this.anio,
    required this.color,
    required this.alias,
  }) : idPropietario = idPropietario ?? idDueno;

  factory Vehiculo.fromMap(Map<dynamic, dynamic> data) {
    final propietario =
        data['idPropietario'] ?? data['idDueno'] ?? data['idOwner'] ?? '';

    return Vehiculo(
      idVehiculo: data['idVehiculo'] ?? '',
      idDispositivo: data['idDispositivo'] ?? '',
      idDueno: propietario,
      idPropietario: propietario,
      organizationId:
          data['organizationId'] ??
          data['organizacionId'] ??
          'first-protection',
      compartidoCon: List<String>.from(data['compartidoCon'] ?? []),
      patente: data['patente'] ?? 'S/P',
      marca: data['marca'] ?? '',
      modelo: data['modelo'] ?? '',
      anio: data['anio'] ?? '',
      color: data['color'] ?? '',
      alias: data['alias'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'idVehiculo': idVehiculo,
    'idDispositivo': idDispositivo,
    'idDueno': idDueno,
    'idPropietario': idPropietario,
    'organizationId': organizationId,
    'compartidoCon': compartidoCon,
    'patente': patente,
    'marca': marca,
    'modelo': modelo,
    'anio': anio,
    'color': color,
    'alias': alias,
  };
}
