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
}
