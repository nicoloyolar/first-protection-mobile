import 'package:geolocator/geolocator.dart';

/// Encapsula el acceso a la ubicación del teléfono (paquete `geolocator`).
/// Es la "ubicación del usuario" del modelo de datos — nunca debe usarse
/// para sobreescribir la ubicación oficial del vehículo, que reporta el
/// dispositivo STM. Ver docs/physical-device-integration.md.
class LiveLocationService {
  /// Verifica servicio de ubicación del sistema y permiso de la app,
  /// solicitando el permiso si todavía no se ha resuelto. Devuelve el
  /// permiso final tal cual lo entrega el sistema operativo.
  Future<LocationPermission> solicitarPermiso() async {
    final servicioActivo = await Geolocator.isLocationServiceEnabled();
    if (!servicioActivo) {
      return LocationPermission.denied;
    }

    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    return permiso;
  }

  bool permisoConcedido(LocationPermission permiso) =>
      permiso == LocationPermission.always ||
      permiso == LocationPermission.whileInUse;

  /// Stream de posición del teléfono. `distanceFilter` evita escrituras
  /// excesivas a Firebase: solo emite cuando el usuario se movió al menos
  /// esa cantidad de metros.
  Stream<Position> escucharPosicion() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15,
      ),
    );
  }

  double distanciaEnMetros({
    required double latA,
    required double lngA,
    required double latB,
    required double lngB,
  }) {
    return Geolocator.distanceBetween(latA, lngA, latB, lngB);
  }
}
