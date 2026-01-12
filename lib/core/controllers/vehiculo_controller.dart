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

  Future<void> cargarFlota(String uid) async {
    cargando = true;
    notifyListeners();

    listaVehiculos = await _dbService.obtenerVehiculosUsuario(uid);
    
    if (listaVehiculos.isNotEmpty) {
      seleccionarVehiculo(listaVehiculos.first);
    }

    cargando = false;
    notifyListeners();
  }

  void seleccionarVehiculo(Vehiculo vehiculo) {
    vehiculoSeleccionado = vehiculo;
    
    _suscripcionEstado?.cancel();
    
    _suscripcionEstado = _dbService
        .obtenerDispositivos(vehiculo.idDispositivo)
        .listen((nuevoEstado) {
      estadoActual = nuevoEstado;
      notifyListeners(); 
    });

    notifyListeners();
  }

  @override
  void dispose() {
    _suscripcionEstado?.cancel();
    super.dispose();
  }
}