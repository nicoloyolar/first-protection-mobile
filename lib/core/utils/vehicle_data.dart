import 'package:flutter/material.dart';

class VehicleData {
  static const List<String> marcas = [
    "TOYOTA",
    "HYUNDAI",
    "KIA",
    "CHEVROLET",
    "SUZUKI",
    "NISSAN",
  ];

  static const Map<String, List<String>> modelosPorMarca = {
    "TOYOTA": ["YARIS", "COROLLA", "RAV4", "HILUX", "FORTUNER"],
    "HYUNDAI": ["ACCENT", "ELANTRA", "TUCSON", "SANTA FE", "IONIQ"],
    "KIA": ["RIO", "CERATO", "SPORTAGE", "SORENTO", "MORNING"],
    "CHEVROLET": ["SAIL", "ONIX", "TRACKER", "CAPTIVA", "SILVERADO"],
    "SUZUKI": ["SWIFT", "BALENO", "VITARA", "JIMNY", "S-CROSS"],
    "NISSAN": ["VERSA", "SENTRA", "KICKS", "QASHQAI", "NAVARA"],
  };

  static const List<String> colores = [
    "BLANCO",
    "NEGRO",
    "GRIS",
    "PLATA",
    "ROJO",
    "AZUL",
  ];

  static List<String> getAnios() {
    return List.generate(
      (2026 - 2010) + 1,
      (i) => (2010 + i).toString(),
    ).reversed.toList();
  }

  /// Color visual para mostrar un punto identificador junto al nombre del
  /// color (selector de vinculación, lista de vehículos). `PLATA` usa un
  /// gris más claro que `GRIS` para que se distingan como puntos sólidos.
  static Color colorFor(String? nombre) {
    switch ((nombre ?? '').toUpperCase()) {
      case 'BLANCO':
        return const Color(0xFFF5F5F5);
      case 'NEGRO':
        return const Color(0xFF1A1A1A);
      case 'GRIS':
        return const Color(0xFF6B6B6B);
      case 'PLATA':
        return const Color(0xFFC0C0C0);
      case 'ROJO':
        return const Color(0xFFD32F2F);
      case 'AZUL':
        return const Color(0xFF1565C0);
      default:
        return Colors.transparent;
    }
  }
}
