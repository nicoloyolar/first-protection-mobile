class UsuarioPropietario {
  final String uidUsuarioPropietario;
  final String nombre;
  final String rut;
  final String email;
  final String telefono;
  final String domicilio;
  final String contactoEmergencia;
  final List<String> misVehiculos;

  UsuarioPropietario({
    required this.uidUsuarioPropietario,
    required this.nombre,
    required this.rut,
    required this.email,
    required this.telefono,
    required this.domicilio,
    required this.contactoEmergencia,
    this.misVehiculos = const [],
  });

  Map<String, dynamic> toMap() => {
    'nombre': nombre,
    'rut': rut,
    'email': email,
    'telefono': telefono,
    'domicilio': domicilio,
    'contactoEmergencia': contactoEmergencia,
    'misVehiculos': misVehiculos,
  };
}
