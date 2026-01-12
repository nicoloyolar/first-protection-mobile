class Dispositivo {
  final String idDispositivo;              
  final String direccionMac;      
  final String versionFirmware; 
  final DateTime fechaInstalacion;
  final DateTime fechaUltimoMantenimiento;
  final bool activo;           
  final String? idVehiculoActual; 

  Dispositivo({
    required this.idDispositivo,
    required this.direccionMac,
    required this.versionFirmware,
    required this.fechaInstalacion,
    required this.fechaUltimoMantenimiento,
    this.activo = true,
    this.idVehiculoActual,
  });
}