import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/vehiculo_model.dart';
import '../models/estado_dispositivo_model.dart';
import '../services/database_service.dart';
import '../services/live_location_service.dart';

/// Umbrales de la heurística básica de cercanía usuario-vehículo, ver
/// docs/physical-device-integration.md sección "Cercania Usuario-Vehiculo".
/// Valores tomados del rango sugerido ahí mismo; a futuro deberían ser
/// configurables por organización.
const double _carjackingDistanceMeters = 80;
const double _carjackingSpeedKmh = 8;

/// Umbrales del modo estacionado/armado, ver docs/physical-device-
/// integration.md sección "Modos Del Sistema" y "Cercania Usuario-
/// Vehiculo" (`armedRadiusMeters`: 80 a 150 sugerido).
const double _armedRadiusMeters = 100;
const double _maxSpeedKmhToArm = 5;

class VehiculoController extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final LiveLocationService _locationService = LiveLocationService();

  List<Vehiculo> listaVehiculos = [];
  Vehiculo? vehiculoSeleccionado;
  EstadoDispositivo? estadoActual;

  bool cargando = false;
  StreamSubscription? _suscripcionEstado;
  Map<String, bool> _onlineStatus = {};

  String? _uid;
  StreamSubscription<Position>? _suscripcionUbicacion;
  Position? posicionUsuario;
  double? distanciaAlVehiculoMetros;
  bool alertaAlejamiento = false;
  bool permisoUbicacionDenegado = false;
  bool alertaMovimientoArmado = false;
  bool alertaGeocerca = false;

  bool get tieneVehiculos => listaVehiculos.isNotEmpty;

  bool get vehiculoArmado => estadoActual?.armado ?? false;

  bool vehiculoEstaOnline(String idDispositivo) {
    if (vehiculoSeleccionado?.idDispositivo == idDispositivo &&
        estadoActual != null) {
      final threshold =
          DateTime.now().millisecondsSinceEpoch - (5 * 60 * 1000);
      return estadoActual!.ultimaActualizacion > threshold;
    }
    return _onlineStatus[idDispositivo] ?? false;
  }

  Future<void> cargarFlota(String uid) async {
    if (cargando) return;

    cargando = true;
    notifyListeners();

    try {
      listaVehiculos = await _dbService.obtenerVehiculosUsuario(uid);

      if (listaVehiculos.isNotEmpty) {
        final ids = listaVehiculos.map((v) => v.idDispositivo).toList();
        _onlineStatus = await _dbService.obtenerEstadoOnlineDispositivos(ids);
        seleccionarVehiculo(listaVehiculos.first);
      } else {
        vehiculoSeleccionado = null;
        estadoActual = null;
        await _suscripcionEstado?.cancel();
      }
    } catch (e) {
      debugPrint("Error al cargar flota: $e");
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  void seleccionarVehiculo(Vehiculo vehiculo) {
    if (vehiculoSeleccionado?.idDispositivo == vehiculo.idDispositivo) {
      return;
    }

    vehiculoSeleccionado = vehiculo;
    estadoActual = null;

    _suscripcionEstado?.cancel();

    _suscripcionEstado = _dbService
        .obtenerDispositivos(vehiculo.idDispositivo)
        .listen(
          (nuevoEstado) {
            if (estadoActual == nuevoEstado) return;
            estadoActual = nuevoEstado;
            _evaluarCercania();
            _evaluarModoArmado();
            _evaluarGeocerca();
            notifyListeners();
          },
          onError: (error) {
            debugPrint("Error en Stream de dispositivo: $error");
          },
        );

    notifyListeners();
  }

  /// Activa o desactiva el modo estacionado/armado. Devuelve un mensaje de
  /// error para mostrar en la UI, o `null` si quedó todo bien. No permite
  /// armar mientras el vehículo se está moviendo — armar tiene sentido para
  /// "dejé el auto estacionado", no en marcha.
  Future<String?> alternarModoArmado(bool armar) async {
    final estado = estadoActual;
    final vehiculo = vehiculoSeleccionado;
    if (estado == null || vehiculo == null || _uid == null) {
      return "No hay un vehículo seleccionado todavía";
    }

    if (armar && estado.velocidad > _maxSpeedKmhToArm) {
      return "No puedes armar el sistema mientras el vehículo está en movimiento";
    }

    await _dbService.actualizarModoArmado(
      idDispositivo: vehiculo.idDispositivo,
      armado: armar,
      actorUid: _uid!,
      lat: armar ? estado.latitud : null,
      lng: armar ? estado.longitud : null,
    );
    alertaMovimientoArmado = false;
    return null;
  }

  /// Heurística de "vehiculoSeMovioEstandoArmado" (ver
  /// docs/physical-device-integration.md): si el vehículo está armado y se
  /// aleja más de `_armedRadiusMeters` del punto donde se armó, es una señal
  /// de que se movió sin que el dueño lo autorizara (robo, remolque, etc).
  /// Igual que `_evaluarCercania`, solo dispara la alerta en la transición
  /// para no inundar `eventos/` mientras la condición se mantiene.
  void _evaluarModoArmado() {
    final estado = estadoActual;
    final vehiculo = vehiculoSeleccionado;

    if (estado == null || !estado.armado || estado.armedAtLat == null || estado.armedAtLng == null) {
      alertaMovimientoArmado = false;
      return;
    }

    final distancia = _locationService.distanciaEnMetros(
      latA: estado.latitud,
      lngA: estado.longitud,
      latB: estado.armedAtLat!,
      lngB: estado.armedAtLng!,
    );

    final seMovio = distancia >= _armedRadiusMeters;

    if (seMovio && !alertaMovimientoArmado && vehiculo != null && _uid != null) {
      _dbService.registrarAlertaModoArmado(
        idDispositivo: vehiculo.idDispositivo,
        actorUid: _uid!,
        distanciaMetros: distancia,
      );
    }
    alertaMovimientoArmado = seMovio;
  }

  /// Geocerca: zona fija configurable por el usuario (ver
  /// docs/plan-de-trabajo.md Pista A), independiente del modo armado y de
  /// la ubicación del teléfono. Se evalúa siempre que está activa, sin
  /// requerir que el usuario haya armado el sistema.
  void _evaluarGeocerca() {
    final estado = estadoActual;
    final vehiculo = vehiculoSeleccionado;

    if (estado == null ||
        !estado.geofenceEnabled ||
        estado.geofenceCenterLat == null ||
        estado.geofenceCenterLng == null ||
        estado.geofenceRadiusMeters == null) {
      alertaGeocerca = false;
      return;
    }

    final distancia = _locationService.distanciaEnMetros(
      latA: estado.latitud,
      lngA: estado.longitud,
      latB: estado.geofenceCenterLat!,
      lngB: estado.geofenceCenterLng!,
    );

    final fueraDeZona = distancia > estado.geofenceRadiusMeters!;

    if (fueraDeZona && !alertaGeocerca && vehiculo != null && _uid != null) {
      _dbService.registrarAlertaGeocerca(
        idDispositivo: vehiculo.idDispositivo,
        actorUid: _uid!,
        distanciaMetros: distancia,
        radioMetros: estado.geofenceRadiusMeters!,
      );
    }
    alertaGeocerca = fueraDeZona;
  }

  /// Pide permiso de ubicación y empieza a escuchar la posición del
  /// teléfono. Se llama una vez por sesión (desde `HomeRouter`), no por
  /// vehículo — la ubicación es del usuario, no del vehículo seleccionado.
  Future<void> iniciarSeguimientoUsuario(String uid) async {
    if (_uid == uid && _suscripcionUbicacion != null) return;
    _uid = uid;

    final permiso = await _locationService.solicitarPermiso();
    if (!_locationService.permisoConcedido(permiso)) {
      permisoUbicacionDenegado = true;
      notifyListeners();
      return;
    }

    permisoUbicacionDenegado = false;
    await _suscripcionUbicacion?.cancel();
    _suscripcionUbicacion = _locationService.escucharPosicion().listen(
      (posicion) {
        posicionUsuario = posicion;
        _dbService.actualizarUbicacionUsuario(
          uid: uid,
          lat: posicion.latitude,
          lng: posicion.longitude,
          accuracy: posicion.accuracy,
        );
        _evaluarCercania();
        notifyListeners();
      },
      onError: (error) {
        debugPrint("Error en Stream de ubicación: $error");
      },
    );
  }

  /// Heurística básica de cercanía usuario-vehículo (ver
  /// docs/physical-device-integration.md). Solo genera una alerta en la
  /// transición de "cerca/detenido" a "lejos y en movimiento" para no
  /// inundar `eventos/` con el mismo aviso en cada actualización de GPS.
  void _evaluarCercania() {
    final posicion = posicionUsuario;
    final estado = estadoActual;
    final vehiculo = vehiculoSeleccionado;

    if (posicion == null || estado == null) {
      distanciaAlVehiculoMetros = null;
      return;
    }

    distanciaAlVehiculoMetros = _locationService.distanciaEnMetros(
      latA: posicion.latitude,
      lngA: posicion.longitude,
      latB: estado.latitud,
      lngB: estado.longitud,
    );

    final sospechoso =
        distanciaAlVehiculoMetros! >= _carjackingDistanceMeters &&
        estado.velocidad >= _carjackingSpeedKmh;

    if (sospechoso && !alertaAlejamiento && vehiculo != null && _uid != null) {
      _dbService.registrarAlertaProximidad(
        idDispositivo: vehiculo.idDispositivo,
        actorUid: _uid!,
        distanciaMetros: distanciaAlVehiculoMetros!,
        velocidadKmh: estado.velocidad,
      );
    }
    alertaAlejamiento = sospechoso;
  }

  Future<void> cambiarEstadoCortaCorriente(bool activar) async {
    if (vehiculoSeleccionado == null) return;

    await _dbService.actualizarEstadoMando(
      vehiculoSeleccionado!.idDispositivo,
      'cortaCorriente',
      activar,
    );
  }

  Future<void> cambiarEstadoProtocolo(bool activar) async {
    if (vehiculoSeleccionado == null) return;

    await _dbService.actualizarEstadoMando(
      vehiculoSeleccionado!.idDispositivo,
      'protocoloActivo',
      activar,
    );
  }

  Future<bool> vincularVehiculo({
    required String idUsuario,
    required String idDispositivo,
    required String alias,
    required String patente,
    required String marca,
    required String modelo,
    String color = '',
  }) async {
    bool exito = await _dbService.vincularNuevoVehiculo(
      idUsuario: idUsuario,
      idDispositivo: idDispositivo,
      alias: alias,
      patente: patente,
      marca: marca,
      modelo: modelo,
      color: color,
    );

    if (exito) {
      await cargarFlota(idUsuario);
    }

    return exito;
  }

  @override
  void dispose() {
    _suscripcionEstado?.cancel();
    _suscripcionUbicacion?.cancel();
    super.dispose();
  }

  Future<void> cambiarEstadoHumo(bool nuevoEstado) async {
    if (vehiculoSeleccionado == null) return;

    await _dbService.actualizarEstadoMando(
      vehiculoSeleccionado!.idDispositivo,
      'humo',
      nuevoEstado,
    );
  }
}
