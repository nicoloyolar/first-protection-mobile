import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import '../models/app_user_profile.dart';
import '../models/device_command_model.dart';
import '../models/device_event_model.dart';
import '../models/device_telemetry_model.dart';
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
      };

      actualizaciones['usuarios/$idUsuario/mis_vehiculos/$idVehiculo'] = true;
      actualizaciones['dispositivos/$idDispositivo/alias'] = alias;
      actualizaciones['dispositivos/$idDispositivo/patente'] = patente;
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
      final campo = value['campo']?.toString() ?? '';
      final valor = value['valor'] == true;
      final esCritico = campo == 'cortaCorriente' && valor;

      return <String, dynamic>{
        'source': 'comando',
        'tipo': value['tipo']?.toString() ?? 'comandoRemoto',
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
