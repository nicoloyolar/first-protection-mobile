import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import '../models/app_user_profile.dart';
import '../models/device_command_model.dart';
import '../models/device_event_model.dart';
import '../models/device_telemetry_model.dart';
import '../models/live_location_model.dart';
import '../models/vehiculo_model.dart';
import '../models/estado_dispositivo_model.dart';

class DatabaseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  static const String defaultOrganizationId = 'first-protection';

  Future<AppUserProfile?> obtenerPerfilUsuario(String uid) async {
    final snapshot = await _db.child('usuarios/$uid').get();
    if (!snapshot.exists || snapshot.value is! Map) return null;

    return AppUserProfile.fromMap(
      uid,
      Map<dynamic, dynamic>.from(snapshot.value as Map),
    );
  }

  Future<bool> usuarioPuedeAccederAdmin(String uid) async {
    final profile = await obtenerPerfilUsuario(uid);
    return profile?.canAccessAdmin ?? false;
  }

  Future<List<Vehiculo>> obtenerVehiculosUsuario(String uid) async {
    try {
      final snapshot = await _db.child('usuarios/$uid/mis_vehiculos').get();

      if (!snapshot.exists) return [];

      final mapIds = snapshot.value as Map<dynamic, dynamic>;

      final vehiculos = await Future.wait(
        mapIds.keys.map((idVehiculo) async {
          final vehicleSnap = await _db
              .child('vehicles_meta/$idVehiculo')
              .get();
          if (vehicleSnap.exists) {
            final data = vehicleSnap.value as Map<dynamic, dynamic>;
            data['idVehiculo'] = idVehiculo;
            return Vehiculo.fromMap(data);
          }
          return null;
        }),
      );

      return vehiculos.nonNulls.toList();
    } catch (e) {
      throw Exception('No se pudo cargar la flota del usuario: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> escucharDispositivosAdmin({
    String? organizationId,
  }) {
    return _db.child('dispositivos').onValue.map((event) {
      if (event.snapshot.value == null) return <Map<String, dynamic>>[];
      final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);

      return data.entries
          .where((entry) => entry.value is Map)
          .map((entry) {
            final device = Map<String, dynamic>.from(entry.value as Map);
            device['id'] = entry.key.toString();
            device['latitud'] = _asDouble(device['latitud']);
            device['longitud'] = _asDouble(device['longitud']);
            device['velocidad'] = _asDouble(device['velocidad']);
            device['voltaje'] = _asDouble(device['voltaje']);
            device['organizationId'] =
                device['organizationId'] ?? defaultOrganizationId;
            return device;
          })
          .where(
            (device) =>
                organizationId == null ||
                device['organizationId']?.toString() == organizationId,
          )
          .toList()
        ..sort(
          (a, b) => (a['alias'] ?? a['id']).toString().compareTo(
            (b['alias'] ?? b['id']).toString(),
          ),
        );
    });
  }

  Stream<EstadoDispositivo> obtenerDispositivos(String idDispositivo) {
    return _db.child('dispositivos').child(idDispositivo).onValue.map((event) {
      final snapshot = event.snapshot;

      if (snapshot.value == null) {
        throw Exception("No hay datos para este dispositivo");
      }

      final data = Map<dynamic, dynamic>.from(snapshot.value as Map);

      return EstadoDispositivo.fromMap(idDispositivo, data);
    });
  }

  Future<bool> vincularNuevoVehiculo({
    required String idUsuario,
    required String idDispositivo,
    required String alias,
    required String patente,
    required String marca,
    required String modelo,
    String color = '',
    String organizationId = defaultOrganizationId,
  }) async {
    try {
      final String idVehiculo = idDispositivo;

      Map<String, dynamic> actualizaciones = {};

      actualizaciones['vehicles_meta/$idVehiculo'] = {
        'idDispositivo': idDispositivo,
        'idPropietario': idUsuario,
        'idDueno': idUsuario,
        'organizationId': organizationId,
        'alias': alias,
        'patente': patente,
        'marca': marca,
        'modelo': modelo,
        'color': color,
      };

      actualizaciones['usuarios/$idUsuario/mis_vehiculos/$idVehiculo'] = true;
      actualizaciones['dispositivos/$idDispositivo/alias'] = alias;
      actualizaciones['dispositivos/$idDispositivo/patente'] = patente;
      actualizaciones['dispositivos/$idDispositivo/color'] = color;
      actualizaciones['dispositivos/$idDispositivo/id'] = idDispositivo;
      actualizaciones['dispositivos/$idDispositivo/idVehiculo'] = idVehiculo;
      actualizaciones['dispositivos/$idDispositivo/idPropietario'] = idUsuario;
      actualizaciones['dispositivos/$idDispositivo/organizationId'] =
          organizationId;
      actualizaciones['dispositivos/$idDispositivo/ultimaVinculacion'] =
          ServerValue.timestamp;

      await _db.update(actualizaciones);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Registra la ubicación del teléfono del usuario en
  /// `usuarios/{uid}/liveLocation`. Es la "ubicación del usuario" del modelo
  /// de datos — nunca debe escribirse en `dispositivos/{id}`, que es
  /// exclusivamente la ubicación oficial del vehículo reportada por el STM.
  /// Ver docs/physical-device-integration.md.
  Future<void> actualizarUbicacionUsuario({
    required String uid,
    required double lat,
    required double lng,
    double? accuracy,
  }) async {
    await _db.child('usuarios/$uid/liveLocation').set({
      'lat': lat,
      'lng': lng,
      if (accuracy != null) 'accuracy': accuracy,
      'timestamp': ServerValue.timestamp,
    });
  }

  Stream<LiveLocation?> escucharUbicacionUsuario(String uid) {
    return _db.child('usuarios/$uid/liveLocation').onValue.map((event) {
      if (event.snapshot.value is! Map) return null;
      return LiveLocation.fromMap(
        Map<dynamic, dynamic>.from(event.snapshot.value as Map),
      );
    });
  }

  /// Deja registro de que el vehículo se alejó del usuario mientras estaba
  /// en movimiento (heurística básica de "posible portonazo", ver
  /// docs/physical-device-integration.md sección "Cercania Usuario-
  /// Vehiculo"). Se escribe como evento de cliente, igual que un comando
  /// remoto — no cambia `systemMode` del dispositivo, eso requiere una
  /// decisión server-side (pendiente, ver docs/plan-de-trabajo.md).
  Future<void> registrarAlertaProximidad({
    required String idDispositivo,
    required String actorUid,
    required double distanciaMetros,
    required double velocidadKmh,
  }) async {
    await _db.update({
      'eventos/$idDispositivo/${_db.push().key}': {
        'tipo': 'posibleAlejamientoVehiculo',
        'distanciaMetros': distanciaMetros,
        'velocidadKmh': velocidadKmh,
        'actorUid': actorUid,
        'actorRole': 'client',
        'timestamp': ServerValue.timestamp,
      },
    });
  }

  /// Datos del propietario que hoy vive el cliente puede editar desde su
  /// celular. Igual que en el panel admin (`device_inventory_screen.dart`),
  /// estos campos viven planos en `dispositivos/{idDispositivo}` — no en
  /// `usuarios/{uid}` — porque el registro original se pensó por vehículo,
  /// no por cuenta.
  Future<Map<String, String>> obtenerDatosPropietario(
    String idDispositivo,
  ) async {
    final snapshot = await _db.child('dispositivos/$idDispositivo').get();
    if (!snapshot.exists || snapshot.value is! Map) return {};

    final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
    return {
      'nombrePropietario': data['nombrePropietario']?.toString() ?? '',
      'rutPropietario': data['rutPropietario']?.toString() ?? '',
      'emailPropietario': data['emailPropietario']?.toString() ?? '',
      'telefonoPropietario': data['telefonoPropietario']?.toString() ?? '',
      'domicilioPropietario': data['domicilioPropietario']?.toString() ?? '',
      'nombreEmergencia': data['nombreEmergencia']?.toString() ?? '',
      'telefonoEmergencia': data['telefonoEmergencia']?.toString() ?? '',
      'comentario': data['comentario']?.toString() ?? '',
    };
  }

  Future<void> actualizarDatosPropietario({
    required String idDispositivo,
    required String nombre,
    required String rut,
    required String email,
    required String telefono,
    required String domicilio,
    required String nombreEmergencia,
    required String telefonoEmergencia,
    required String comentario,
  }) async {
    await _db.child('dispositivos/$idDispositivo').update({
      'nombrePropietario': nombre,
      'rutPropietario': rut,
      'emailPropietario': email,
      'telefonoPropietario': telefono,
      'domicilioPropietario': domicilio,
      'nombreEmergencia': nombreEmergencia,
      'telefonoEmergencia': telefonoEmergencia,
      'comentario': comentario,
    });
  }

  /// Activa o desactiva el modo estacionado/armado (ver "Modos Del Sistema"
  /// en docs/physical-device-integration.md). Al armar, guarda la posición
  /// actual del vehículo como ancla (`armedAt`) para poder detectar
  /// movimiento no esperado mientras está desarmado el resto de la app.
  /// No requiere ACK del dispositivo: no es un actuador físico, es una
  /// bandera de monitoreo que decide el backend/app, no el STM.
  Future<void> actualizarModoArmado({
    required String idDispositivo,
    required bool armado,
    required String actorUid,
    double? lat,
    double? lng,
  }) async {
    final updates = <String, dynamic>{
      'dispositivos/$idDispositivo/systemMode': armado ? 'armed' : 'normal',
      'dispositivos/$idDispositivo/armedAt': armado && lat != null && lng != null
          ? {'lat': lat, 'lng': lng, 'timestamp': ServerValue.timestamp}
          : null,
      'eventos/$idDispositivo/${_db.push().key}': {
        'tipo': armado ? 'modoArmadoActivado' : 'modoArmadoDesactivado',
        'actorUid': actorUid,
        'actorRole': 'client',
        'timestamp': ServerValue.timestamp,
      },
    };
    await _db.update(updates);
  }

  /// Lee la posición actual del vehículo, para usarla como centro de la
  /// geocerca sin depender del stream reactivo (ej. desde una pantalla de
  /// configuración que se abre por fuera del vehículo seleccionado).
  Future<Map<String, double>?> obtenerPosicionActualDispositivo(
    String idDispositivo,
  ) async {
    final snapshot = await _db.child('dispositivos/$idDispositivo').get();
    if (!snapshot.exists || snapshot.value is! Map) return null;
    final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
    return {
      'lat': _asDouble(data['latitud']),
      'lng': _asDouble(data['longitud']),
    };
  }

  Future<Map<String, dynamic>> obtenerGeocerca(String idDispositivo) async {
    final snapshot = await _db.child('dispositivos/$idDispositivo/geofence').get();
    if (!snapshot.exists || snapshot.value is! Map) {
      return {'enabled': false, 'radiusMeters': 2000.0};
    }
    final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
    return {
      'enabled': data['enabled'] == true,
      'centerLat': data['centerLat'] == null ? null : _asDouble(data['centerLat']),
      'centerLng': data['centerLng'] == null ? null : _asDouble(data['centerLng']),
      'radiusMeters': data['radiusMeters'] == null ? 2000.0 : _asDouble(data['radiusMeters']),
    };
  }

  /// Configura la geocerca (zona fija, independiente del modo armado y de
  /// la ubicación del usuario — ver docs/plan-de-trabajo.md Pista A). No
  /// requiere ACK del dispositivo: no es un actuador físico.
  Future<void> actualizarGeocerca({
    required String idDispositivo,
    required bool enabled,
    double? centerLat,
    double? centerLng,
    required double radiusMeters,
    required String actorUid,
  }) async {
    await _db.update({
      'dispositivos/$idDispositivo/geofence': {
        'enabled': enabled,
        if (centerLat != null) 'centerLat': centerLat,
        if (centerLng != null) 'centerLng': centerLng,
        'radiusMeters': radiusMeters,
      },
      'eventos/$idDispositivo/${_db.push().key}': {
        'tipo': enabled ? 'geocercaActivada' : 'geocercaDesactivada',
        'actorUid': actorUid,
        'actorRole': 'client',
        'timestamp': ServerValue.timestamp,
      },
    });
  }

  Future<void> registrarAlertaGeocerca({
    required String idDispositivo,
    required String actorUid,
    required double distanciaMetros,
    required double radioMetros,
  }) async {
    await _db.update({
      'eventos/$idDispositivo/${_db.push().key}': {
        'tipo': 'geocercaSobrepasada',
        'distanciaMetros': distanciaMetros,
        'radioMetros': radioMetros,
        'actorUid': actorUid,
        'actorRole': 'client',
        'timestamp': ServerValue.timestamp,
      },
    });
  }

  /// Registra que el vehículo se movió más de lo esperado estando armado
  /// (posible robo/remolque de un vehículo que se dejó estacionado). Ver
  /// docs/physical-device-integration.md, "Cercania Usuario-Vehiculo".
  /// Reutiliza el nombre del `DeviceEventType.vehicleMovedWhileArmed` ya
  /// existente para que el formatter compartido lo reconozca igual que si
  /// viniera del dispositivo físico.
  Future<void> registrarAlertaModoArmado({
    required String idDispositivo,
    required String actorUid,
    required double distanciaMetros,
  }) async {
    await _db.update({
      'eventos/$idDispositivo/${_db.push().key}': {
        'tipo': 'vehicleMovedWhileArmed',
        'distanciaMetros': distanciaMetros,
        'actorUid': actorUid,
        'actorRole': 'client',
        'timestamp': ServerValue.timestamp,
      },
    });
  }

  Future<void> actualizarEstadoMando(
    String idDispositivo,
    String campo,
    bool valor,
  ) async {
    await actualizarComandoDispositivo(
      idDispositivo: idDispositivo,
      campo: campo,
      valor: valor,
    );
  }

  /// Crea un comando pendiente para el dispositivo y deja auditoría, pero
  /// YA NO toca el campo del actuador (`dispositivos/{id}/{campo}`)
  /// directamente. Ese campo solo debe reflejar lo que el dispositivo (o el
  /// simulador STM, mientras no exista hardware real) confirma vía ACK — ver
  /// `functions/index.js:ackCommand`. Este es el hito de sincronización de
  /// docs/plan-de-trabajo.md: antes, la UI mentía mostrando el comando como
  /// aplicado de inmediato aunque nadie lo hubiera ejecutado todavía.
  Future<void> actualizarComandoDispositivo({
    required String idDispositivo,
    required String campo,
    required bool valor,
    String actorUid = 'system',
    String actorRole = 'client',
  }) async {
    await crearComandoDispositivo(
      idDispositivo: idDispositivo,
      target: _targetForField(campo),
      value: valor,
      requestedBy: actorUid,
      requestedByRole: actorRole,
    );

    final updates = <String, dynamic>{
      'dispositivos/$idDispositivo/ultimoComando': {
        'campo': campo,
        'valor': valor,
        'actorUid': actorUid,
        'actorRole': actorRole,
        'timestamp': ServerValue.timestamp,
      },
      'eventos/$idDispositivo/${_db.push().key}': {
        'tipo': 'comandoRemoto',
        'campo': campo,
        'valor': valor,
        'actorUid': actorUid,
        'actorRole': actorRole,
        'timestamp': ServerValue.timestamp,
      },
    };

    await _db.update(updates);
  }

  Future<String> crearComandoDispositivo({
    required String idDispositivo,
    required DeviceCommandTarget target,
    required dynamic value,
    DeviceCommandType type = DeviceCommandType.setActuator,
    String requestedBy = 'system',
    String requestedByRole = 'client',
    Duration ttl = const Duration(seconds: 60),
  }) async {
    final commandRef = _db.child('device_commands/$idDispositivo').push();
    final now = DateTime.now().millisecondsSinceEpoch;
    final command = DeviceCommand(
      id: commandRef.key ?? '',
      deviceId: idDispositivo,
      type: type,
      target: target,
      value: value,
      status: DeviceCommandStatus.pending,
      requestedBy: requestedBy,
      requestedByRole: requestedByRole,
      createdAt: now,
      expiresAt: now + ttl.inMilliseconds,
    );

    await commandRef.set(command.toMap());
    return command.id;
  }

  Stream<List<DeviceCommand>> escucharComandosDispositivo(
    String idDispositivo,
  ) {
    return _db.child('device_commands/$idDispositivo').onValue.map((event) {
      if (event.snapshot.value == null) return <DeviceCommand>[];
      final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
      return data.entries
          .where((entry) => entry.value is Map)
          .map(
            (entry) => DeviceCommand.fromMap(
              entry.key.toString(),
              idDispositivo,
              Map<dynamic, dynamic>.from(entry.value as Map),
            ),
          )
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  Future<void> registrarAckComando({
    required String idDispositivo,
    required String commandId,
    required DeviceCommandStatus status,
    String? errorCode,
    String? message,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.update({
      'device_commands/$idDispositivo/$commandId/status': status.name,
      'device_commands/$idDispositivo/$commandId/executedAt':
          status == DeviceCommandStatus.executed ? now : null,
      'device_commands/$idDispositivo/$commandId/errorCode': errorCode,
      'device_commands/$idDispositivo/$commandId/message': message,
      'device_events/$idDispositivo/${_db.push().key}': DeviceEvent(
        id: '',
        deviceId: idDispositivo,
        type: DeviceEventType.commandAck,
        severity: status == DeviceCommandStatus.executed
            ? DeviceEventSeverity.info
            : DeviceEventSeverity.warning,
        timestamp: now,
        metadata: {
          'commandId': commandId,
          'status': status.name,
          if (errorCode != null) 'errorCode': errorCode,
          if (message != null) 'message': message,
        },
      ).toMap(),
    });
  }

  /// Combina `eventos/{id}` (comandos remotos, esquema legacy) y
  /// `device_events/{id}` (esquema nuevo: heartbeat/tamper/panic/ack) en un
  /// solo feed de auditoria para el panel admin. Filtra heartbeats: son
  /// telemetria rutinaria, no un evento critico que valga la pena auditar.
  Stream<List<Map<String, dynamic>>> escucharEventosDispositivo(
    String idDispositivo,
  ) {
    final controller = StreamController<List<Map<String, dynamic>>>.broadcast();
    List<Map<String, dynamic>> comandos = const [];
    List<Map<String, dynamic>> deviceEvents = const [];

    void emitir() {
      final combinados = [...comandos, ...deviceEvents]
        ..sort(
          (a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int),
        );
      controller.add(combinados);
    }

    final subComandos = _db
        .child('eventos/$idDispositivo')
        .limitToLast(50)
        .onValue
        .listen((event) {
          comandos = _parseComandoEvents(event.snapshot);
          emitir();
        });

    final subDeviceEvents = _db
        .child('device_events/$idDispositivo')
        .limitToLast(50)
        .onValue
        .listen((event) {
          deviceEvents = _parseDeviceEvents(idDispositivo, event.snapshot);
          emitir();
        });

    controller.onCancel = () async {
      await subComandos.cancel();
      await subDeviceEvents.cancel();
    };

    return controller.stream;
  }

  List<Map<String, dynamic>> _parseComandoEvents(DataSnapshot snapshot) {
    if (snapshot.value is! Map) return const [];
    final data = Map<dynamic, dynamic>.from(snapshot.value as Map);

    return data.entries.where((entry) => entry.value is Map).map((entry) {
      final value = Map<dynamic, dynamic>.from(entry.value as Map);
      final tipo = value['tipo']?.toString() ?? 'comandoRemoto';

      if (tipo == 'posibleAlejamientoVehiculo' ||
          tipo == 'vehicleMovedWhileArmed' ||
          tipo == 'geocercaSobrepasada') {
        return <String, dynamic>{
          'source': 'comando',
          'tipo': tipo,
          'distanciaMetros': _asDouble(value['distanciaMetros']),
          'radioMetros': _asDouble(value['radioMetros']),
          'velocidadKmh': _asDouble(value['velocidadKmh']),
          'actorRole': value['actorRole']?.toString(),
          'timestamp': _asInt(value['timestamp']),
          'severidad': 'critical',
        };
      }

      if (tipo == 'modoArmadoActivado' ||
          tipo == 'modoArmadoDesactivado' ||
          tipo == 'geocercaActivada' ||
          tipo == 'geocercaDesactivada') {
        return <String, dynamic>{
          'source': 'comando',
          'tipo': tipo,
          'actorRole': value['actorRole']?.toString(),
          'timestamp': _asInt(value['timestamp']),
          'severidad': 'info',
        };
      }

      final campo = value['campo']?.toString() ?? '';
      final valor = value['valor'] == true;
      final esCritico = campo == 'cortaCorriente' && valor;

      return <String, dynamic>{
        'source': 'comando',
        'tipo': tipo,
        'campo': campo,
        'valor': valor,
        'actorRole': value['actorRole']?.toString(),
        'timestamp': _asInt(value['timestamp']),
        'severidad': esCritico ? 'critical' : 'warning',
      };
    }).toList();
  }

  List<Map<String, dynamic>> _parseDeviceEvents(
    String deviceId,
    DataSnapshot snapshot,
  ) {
    if (snapshot.value is! Map) return const [];
    final data = Map<dynamic, dynamic>.from(snapshot.value as Map);

    return data.entries
        .where((entry) => entry.value is Map)
        .map((entry) {
          final deviceEvent = DeviceEvent.fromMap(
            entry.key.toString(),
            deviceId,
            Map<dynamic, dynamic>.from(entry.value as Map),
          );
          return deviceEvent;
        })
        .where((deviceEvent) => deviceEvent.type != DeviceEventType.heartbeat)
        .map(
          (deviceEvent) => <String, dynamic>{
            'source': 'device',
            'tipo': deviceEvent.type.name,
            'severidad': deviceEvent.severity.name,
            'timestamp': deviceEvent.timestamp,
            'metadata': deviceEvent.metadata,
          },
        )
        .toList();
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> registrarTelemetriaDispositivo(DeviceTelemetry telemetry) async {
    await _db.update({
      'dispositivos/${telemetry.deviceId}': telemetry.toMap(),
      'device_telemetry/${telemetry.deviceId}/${telemetry.sequence}': telemetry
          .toMap(),
      'device_events/${telemetry.deviceId}/${_db.push().key}': DeviceEvent(
        id: '',
        deviceId: telemetry.deviceId,
        type: DeviceEventType.heartbeat,
        severity: DeviceEventSeverity.info,
        timestamp: telemetry.timestamp,
        lat: telemetry.lat,
        lng: telemetry.lng,
        metadata: {
          'sequence': telemetry.sequence,
          'speedKmh': telemetry.speedKmh,
          'vehicleVoltage': telemetry.vehicleVoltage,
          'online': telemetry.online,
        },
      ).toMap(),
    });
  }

  Future<void> guardarDispositivoInventario({
    required String idDispositivo,
    required Map<String, dynamic> data,
  }) async {
    final normalized = Map<String, dynamic>.from(data)
      ..['id'] = idDispositivo
      ..['organizationId'] = data['organizationId'] ?? defaultOrganizationId
      ..['actualizadoEn'] = ServerValue.timestamp;

    await _db.child('dispositivos').child(idDispositivo).update(normalized);

    final idPropietario = normalized['idPropietario']?.toString();
    if (idPropietario != null && idPropietario.isNotEmpty) {
      await _db.update({
        'usuarios/$idPropietario/mis_vehiculos/$idDispositivo': true,
        'vehicles_meta/$idDispositivo': {
          'idVehiculo': idDispositivo,
          'idDispositivo': idDispositivo,
          'idPropietario': idPropietario,
          'idDueno': idPropietario,
          'organizationId': normalized['organizationId'],
          'alias': normalized['alias'] ?? '',
          'patente': normalized['patente'] ?? '',
          'marca': normalized['marca'] ?? '',
          'modelo': normalized['modelo'] ?? '',
          'anio': normalized['anio'] ?? '',
          'color': normalized['color'] ?? '',
        },
      });
    }
  }

  Future<void> eliminarDispositivo(
    String idDispositivo, {
    String? idPropietario,
  }) async {
    await _db.update({
      'dispositivos/$idDispositivo': null,
      'vehicles_meta/$idDispositivo': null,
      if (idPropietario != null && idPropietario.isNotEmpty)
        'usuarios/$idPropietario/mis_vehiculos/$idDispositivo': null,
      'device_commands/$idDispositivo': null,
      'device_telemetry/$idDispositivo': null,
      'device_events/$idDispositivo': null,
    });
  }

  Future<Map<String, bool>> obtenerEstadoOnlineDispositivos(
    List<String> ids,
  ) async {
    final threshold =
        DateTime.now().millisecondsSinceEpoch - (5 * 60 * 1000);
    final entries = await Future.wait(
      ids.map((id) async {
        final snap =
            await _db.child('dispositivos/$id/ultimaActualizacion').get();
        final lastSeen = snap.value is num ? (snap.value as num).toInt() : 0;
        return MapEntry(id, lastSeen > threshold);
      }),
    );
    return Map.fromEntries(entries);
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DeviceCommandTarget _targetForField(String field) {
    switch (field) {
      case 'sirena':
      case 'sirenaActiva':
        return DeviceCommandTarget.sirena;
      case 'cortaCorriente':
        return DeviceCommandTarget.cortaCorriente;
      case 'protocoloActivo':
        return DeviceCommandTarget.protocoloActivo;
      default:
        return DeviceCommandTarget.humo;
    }
  }
}
