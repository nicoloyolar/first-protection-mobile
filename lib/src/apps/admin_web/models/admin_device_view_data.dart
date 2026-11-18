import 'package:google_maps_flutter/google_maps_flutter.dart';

class AdminDeviceViewData {
  final Map<String, dynamic> raw;
  final String id;
  final String alias;
  final String patente;
  final double latitud;
  final double longitud;
  final double velocidad;
  final bool humo;
  final bool protocoloActivo;
  final bool cortaCorriente;
  final String organizationId;

  AdminDeviceViewData({
    required this.raw,
    required this.id,
    required this.alias,
    required this.patente,
    required this.latitud,
    required this.longitud,
    required this.velocidad,
    required this.humo,
    required this.protocoloActivo,
    required this.cortaCorriente,
    required this.organizationId,
  });

  factory AdminDeviceViewData.fromMap(Map<String, dynamic> data) {
    final id = data['id']?.toString() ?? '';

    return AdminDeviceViewData(
      raw: Map<String, dynamic>.from(data)..['id'] = id,
      id: id,
      alias: data['alias']?.toString() ?? 'Unidad',
      patente: data['patente']?.toString() ?? 'S/P',
      latitud: _asDouble(data['latitud']),
      longitud: _asDouble(data['longitud']),
      velocidad: _asDouble(data['velocidad']),
      humo: data['humo'] == true,
      protocoloActivo: data['protocoloActivo'] == true,
      cortaCorriente: data['cortaCorriente'] == true,
      organizationId: data['organizationId']?.toString().trim().isNotEmpty == true
          ? data['organizationId'].toString()
          : 'first-protection',
    );
  }

  bool get isAlert => humo || protocoloActivo;

  bool get isArmed => raw['systemMode'] == 'armed';

  Map<dynamic, dynamic> get _location =>
      raw['location'] is Map ? raw['location'] as Map : const {};

  /// Sin el dato (dispositivos antiguos con solo campos planos) se asume fix.
  bool get gpsFix => _location['gpsFix'] != false;

  double? get heading =>
      _location['heading'] is num ? (_location['heading'] as num).toDouble() : null;

  bool get isOnline => latitud != 0 && longitud != 0;

  LatLng get position => LatLng(latitud, longitud);

  bool matchesSearch(String query) {
    if (query.trim().isEmpty) return true;
    final normalized = query.toLowerCase();
    return alias.toLowerCase().contains(normalized) ||
        patente.toLowerCase().contains(normalized) ||
        id.toLowerCase().contains(normalized);
  }

  bool matchesStatus(String status) {
    switch (status) {
      case 'ALERTA':
        return isAlert;
      case 'ONLINE':
        return isOnline;
      default:
        return true;
    }
  }

  bool matchesOrganization(String organizationFilter) {
    return organizationFilter == 'TODAS' ||
        organizationId == organizationFilter;
  }

  Map<String, dynamic> toMap() => {
    ...raw,
    'id': id,
    'alias': alias,
    'patente': patente,
    'latitud': latitud,
    'longitud': longitud,
    'velocidad': velocidad,
    'humo': humo,
    'protocoloActivo': protocoloActivo,
    'cortaCorriente': cortaCorriente,
    'organizationId': organizationId,
  };

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
