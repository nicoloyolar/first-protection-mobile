import 'package:first_protection/core/models/app_user_profile.dart';
import 'package:first_protection/core/models/estado_dispositivo_model.dart';
import 'package:first_protection/core/models/vehiculo_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Vehiculo', () {
    test('normaliza idPropietario e idDueno aunque venga el nombre nuevo', () {
      final vehiculo = Vehiculo.fromMap({
        'idVehiculo': 'VH-1',
        'idDispositivo': 'GPS-123456',
        'idPropietario': 'uid-1',
        'organizationId': 'first-protection',
        'patente': 'ABCD12',
        'marca': 'Toyota',
        'modelo': 'Hilux',
        'alias': 'Camioneta',
      });

      expect(vehiculo.idDueno, 'uid-1');
      expect(vehiculo.idPropietario, 'uid-1');
      expect(vehiculo.organizationId, 'first-protection');
      expect(vehiculo.patente, 'ABCD12');
    });

    test('mantiene compatibilidad con idDueno antiguo', () {
      final vehiculo = Vehiculo.fromMap({
        'idVehiculo': 'VH-2',
        'idDispositivo': 'GPS-654321',
        'idDueno': 'uid-old',
      });

      expect(vehiculo.idDueno, 'uid-old');
      expect(vehiculo.idPropietario, 'uid-old');
    });
  });

  group('EstadoDispositivo', () {
    test('parsea numeros aunque Firebase los entregue como texto', () {
      final estado = EstadoDispositivo.fromMap('GPS-1', {
        'ultimaActualizacion': '1710000000',
        'latitud': '-36.82',
        'longitud': '-73.04',
        'velocidad': '45.5',
        'voltaje': '12.4',
        'cortaCorriente': true,
        'protocoloActivo': false,
        'humo': true,
      });

      expect(estado.ultimaActualizacion, 1710000000);
      expect(estado.latitud, -36.82);
      expect(estado.longitud, -73.04);
      expect(estado.velocidad, 45.5);
      expect(estado.voltaje, 12.4);
      expect(estado.cortaCorriente, isTrue);
      expect(estado.humoActivo, isTrue);
    });
  });

  group('AppUserProfile', () {
    test('detecta acceso admin por roles internos', () {
      final profile = AppUserProfile.fromMap('uid-admin', {
        'email': 'admin@first-protection.cl',
        'role': 'operator',
        'accountType': 'internal',
        'active': true,
      });

      expect(profile.canAccessAdmin, isTrue);
      expect(profile.role, AppUserRole.operator);
      expect(profile.accountType, AccountType.internal);
    });

    test('bloquea perfiles cliente en panel admin', () {
      final profile = AppUserProfile.fromMap('uid-client', {
        'email': 'cliente@example.com',
        'role': 'client',
        'accountType': 'company',
      });

      expect(profile.canAccessAdmin, isFalse);
      expect(profile.accountType, AccountType.company);
    });
  });
}
