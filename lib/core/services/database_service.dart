import 'package:firebase_database/firebase_database.dart';

class DatabaseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  Future<String?> getLinkedVehicleId(String uid) async {
    try {
      final snapshot = await _db.child('users/$uid/vehicle_id').get();
      
      if (snapshot.exists) {
        return snapshot.value.toString();
      }
      return null; 
    } catch (e) {
      return null;
    }
  }

  Stream<DatabaseEvent> getVehicleStream(String vehicleId) {
    return _db.child('vehicles/$vehicleId').onValue;
  }

  Future<void> sendCommand(String vehicleId, String command, bool value) async {
    await _db.child('vehicles/$vehicleId').update({
      command: value,
    });
  }
}