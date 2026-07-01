import 'dart:async';
import 'package:flutter/material.dart';
import '../models/vehiculo_model.dart';
import '../models/estado_dispositivo_model.dart';
import '../services/database_service.dart';

class VehiculoController extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  List<Vehiculo> listaVehiculos = [];
  Vehiculo? vehiculoSeleccionado;
  EstadoDispositivo? estadoActual;

  bool cargando = false;
  StreamSubscription? _suscripcionEstado;
  Map<String, bool> _onlineStatus = {};

  bool get tieneVehiculos => listaVehiculos.isNotEmpty;

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
            notifyListeners();
          },
          onError: (error) {
            debugPrint("Error en Stream de dispositivo: $error");
          },
        );

    notifyListeners();
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
  }) async {
    bool exito = await _dbService.vincularNuevoVehiculo(
      idUsuario: idUsuario,
      idDispositivo: idDispositivo,
      alias: alias,
      patente: patente,
      marca: marca,
      modelo: modelo,
    );

    if (exito) {
      await cargarFlota(idUsuario);
    }

    return exito;
  }

  @override
  void dispose() {
    _suscripcionEstado?.cancel();
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
