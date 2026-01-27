// ignore_for_file: empty_catches

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
    return _db.child('dispositivos').child(idDispositivo).onValue.map((event) {
      final snapshot = event.snapshot;
      
      if (snapshot.value == null) {
        throw Exception("No hay datos para este dispositivo");
      }

      final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
      
      return EstadoDispositivo.fromMap(idDispositivo, data);
    });
  }

  Future<bool> vincularNuevoVehiculo({
    required String idUsuario,
    required String idDispositivo,
    required String alias,
    required String patente,
    required String marca,
    required String modelo,
  }) async {
    try {
      final String idVehiculo = idDispositivo; 

      Map<String, dynamic> actualizaciones = {};

      actualizaciones['vehicles_meta/$idVehiculo'] = {
        'idDispositivo'   : idDispositivo,
        'idPropietario'   : idUsuario,
        'alias'           : alias,
        'patente'         : patente,
        'marca'           : marca,
        'modelo'          : modelo,
      };

      actualizaciones['usuarios/$idUsuario/mis_vehiculos/$idVehiculo'] = true;
      actualizaciones['dispositivos/$idDispositivo/alias'] = alias;
      actualizaciones['dispositivos/$idDispositivo/patente'] = patente;
      actualizaciones['dispositivos/$idDispositivo/id'] = idDispositivo;
      actualizaciones['dispositivos/$idDispositivo/ultimaVinculacion'] = ServerValue.timestamp;

      await _db.update(actualizaciones);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> actualizarEstadoMando(String idDispositivo, String campo, bool valor) async {
    await _db.child('dispositivos').child(idDispositivo).child(campo).set(valor);
  }
}