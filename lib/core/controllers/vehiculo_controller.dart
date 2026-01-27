// ignore_for_file: empty_catches

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

  bool get tieneVehiculos => listaVehiculos.isNotEmpty;

  Future<void> cargarFlota(String uid) async {
    if (cargando) return;

    cargando = true;
    notifyListeners();

    try {
      listaVehiculos = await _dbService.obtenerVehiculosUsuario(uid);
      
      if (listaVehiculos.isNotEmpty) {
        seleccionarVehiculo(listaVehiculos.first);
      }
    } catch (e) {
      debugPrint("Error al cargar flota: $e");
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  void seleccionarVehiculo(Vehiculo vehiculo) {
    vehiculoSeleccionado = vehiculo;
    
    _suscripcionEstado?.cancel();
    
    _suscripcionEstado = _dbService
        .obtenerDispositivos(vehiculo.idDispositivo)
        .listen((nuevoEstado) {
      estadoActual = nuevoEstado;
      notifyListeners(); 
    }, onError: (error) {
      debugPrint("Error en Stream de dispositivo: $error");
    });

    notifyListeners();
  }

  Future<void> cambiarEstadoCortaCorriente(bool activar) async {
    if (vehiculoSeleccionado == null) return;
    
    await _dbService.actualizarEstadoMando(
      vehiculoSeleccionado!.idDispositivo, 
      'cortaCorriente', 
      activar
    );
  }

  Future<void> cambiarEstadoProtocolo(bool activar) async {
    if (vehiculoSeleccionado == null) return;
    
    await _dbService.actualizarEstadoMando(
      vehiculoSeleccionado!.idDispositivo, 
      'protocoloActivo', 
      activar
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
      nuevoEstado
    );
  }

}