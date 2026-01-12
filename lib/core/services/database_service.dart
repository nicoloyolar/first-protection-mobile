import 'package:firebase_database/firebase_database.dart';
import '../models/vehiculo_model.dart';
import '../models/estado_dispositivo_model.dart';

class DatabaseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  Future<List<Vehiculo>> obtenerVehiculosUsuario(String uid) async {
    try {
      final snapshot = await _db.child('usuarios/$uid/mis_vehiculos').get();
      
      if (!snapshot.exists) return [];

      List<Vehiculo> misVehiculos = [];
      final mapIds = snapshot.value as Map<dynamic, dynamic>;

      for (var idVehiculo in mapIds.keys) {
        final vehicleSnap = await _db.child('vehicles_meta/$idVehiculo').get();
        if (vehicleSnap.exists) {
          final data = vehicleSnap.value as Map<dynamic, dynamic>;
          data['idVehiculo'] = idVehiculo; 
          misVehiculos.add(Vehiculo.fromMap(data));
        }
      }
      return misVehiculos;
    } catch (e) {
      return [];
    }
  }

  Stream<EstadoDispositivo> obtenerDispositivos(String idDispositivo) {
    return _db.child('estado_vehiculo/$idDispositivo').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      
      if (data == null) {
        return EstadoDispositivo(
            idDispositivo         : idDispositivo, 
            ultimaActualizacion   : 0, 
            latitud               : 0, 
            longitud              : 0, 
            velocidad             : 0, 
            cortaCorriente        : false, 
            humoDesplegado        : false, 
            sirenaActiva          : false
        );
      }
      data['idDispositivo'] = idDispositivo; 
      return EstadoDispositivo.fromMap(data);
    });
  }
}