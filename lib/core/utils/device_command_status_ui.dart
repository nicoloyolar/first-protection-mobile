import 'package:flutter/material.dart';
import '../models/device_command_model.dart';

/// Etiqueta y color por estado/target de comando, compartido entre el panel
/// admin y la app móvil para que "pendiente/ejecutado/fallido/expirado" se
/// vea igual en ambas interfaces.
class DeviceCommandStatusUi {
  final String label;
  final Color color;

  const DeviceCommandStatusUi(this.label, this.color);

  static DeviceCommandStatusUi forStatus(DeviceCommandStatus status) {
    return switch (status) {
      DeviceCommandStatus.pending => const DeviceCommandStatusUi(
        'Pendiente',
        Colors.amberAccent,
      ),
      DeviceCommandStatus.received => const DeviceCommandStatusUi(
        'Recibido',
        Colors.blueAccent,
      ),
      DeviceCommandStatus.executed => const DeviceCommandStatusUi(
        'Ejecutado',
        Colors.greenAccent,
      ),
      DeviceCommandStatus.rejected => const DeviceCommandStatusUi(
        'Rechazado',
        Colors.orangeAccent,
      ),
      DeviceCommandStatus.failed => const DeviceCommandStatusUi(
        'Falló',
        Colors.redAccent,
      ),
      DeviceCommandStatus.expired => const DeviceCommandStatusUi(
        'Expiró',
        Colors.white38,
      ),
    };
  }

  static String targetLabel(DeviceCommandTarget target) {
    return switch (target) {
      DeviceCommandTarget.humo => 'Humo',
      DeviceCommandTarget.sirena => 'Sirena',
      DeviceCommandTarget.cortaCorriente => 'Corta corriente',
      DeviceCommandTarget.protocoloActivo => 'Protocolo de emergencia',
      DeviceCommandTarget.systemMode => 'Modo del sistema',
      DeviceCommandTarget.telemetry => 'Telemetría',
      DeviceCommandTarget.device => 'Dispositivo',
    };
  }

  /// El comando más reciente para un `target` dado, o null si no hay
  /// ninguno todavía. `commands` debe venir ordenado por `createdAt`
  /// descendente (así lo entrega `DatabaseService.escucharComandosDispositivo`).
  static DeviceCommand? latestFor(
    List<DeviceCommand> commands,
    DeviceCommandTarget target,
  ) {
    for (final command in commands) {
      if (command.target == target) return command;
    }
    return null;
  }
}
