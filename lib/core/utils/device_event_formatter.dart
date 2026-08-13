/// Traduce los eventos crudos que devuelve
/// `DatabaseService.escucharEventosDispositivo` (mezcla de `eventos/` legacy
/// y `device_events/` nuevo) a texto legible. Compartido entre el panel
/// admin y el historial de eventos de la app móvil.
class DeviceEventFormatter {
  const DeviceEventFormatter._();

  static String describe(Map<String, dynamic> evento) {
    if (evento['source'] == 'comando') {
      if (evento['tipo'] == 'posibleAlejamientoVehiculo') {
        final distancia = evento['distanciaMetros'];
        final sufijo = distancia is num
            ? ' (${distancia.round()} m, en movimiento)'
            : '';
        return 'Posible alejamiento del vehículo$sufijo';
      }

      if (evento['tipo'] == 'vehicleMovedWhileArmed') {
        final distancia = evento['distanciaMetros'];
        final sufijo = distancia is num ? ' (${distancia.round()} m)' : '';
        return 'Vehículo se movió estando armado$sufijo';
      }

      if (evento['tipo'] == 'modoArmadoActivado') {
        return 'Modo estacionado/armado activado';
      }
      if (evento['tipo'] == 'modoArmadoDesactivado') {
        return 'Modo estacionado/armado desactivado';
      }

      if (evento['tipo'] == 'geocercaSobrepasada') {
        final distancia = evento['distanciaMetros'];
        final sufijo = distancia is num ? ' (${distancia.round()} m del centro)' : '';
        return 'El vehículo salió de la geocerca$sufijo';
      }
      if (evento['tipo'] == 'geocercaActivada') {
        return 'Geocerca activada';
      }
      if (evento['tipo'] == 'geocercaDesactivada') {
        return 'Geocerca desactivada';
      }

      final campo = evento['campo']?.toString() ?? '';
      final valor = evento['valor'] == true;
      final campoLabel = switch (campo) {
        'humo' => 'Humo',
        'sirena' || 'sirenaActiva' => 'Sirena',
        'cortaCorriente' => 'Corta corriente',
        'protocoloActivo' => 'Protocolo de emergencia',
        _ => campo.isEmpty ? 'Comando' : campo,
      };
      return "$campoLabel → ${valor ? 'activado' : 'desactivado'}";
    }

    final metadata = evento['metadata'] is Map
        ? evento['metadata'] as Map
        : const {};

    return switch (evento['tipo']) {
      'panicButtonPressed' => 'Botón físico presionado',
      'ignitionOn' => 'Encendido del vehículo',
      'ignitionOff' => 'Vehículo apagado',
      'movementDetected' => 'Movimiento detectado',
      'vehicleMovedWhileArmed' => 'Vehículo se movió estando armado',
      'tamperDetected' => 'Posible manipulación del dispositivo',
      'gpsLost' => 'Señal GPS perdida',
      'gpsRecovered' => 'Señal GPS recuperada',
      'powerDisconnected' => 'Alimentación desconectada',
      'powerRestored' => 'Alimentación restaurada',
      'actuatorStateChanged' => 'Cambio de estado de actuador',
      'commandAck' =>
        'Dispositivo confirmó comando: ${metadata['status'] ?? '—'}',
      _ => 'Evento del dispositivo',
    };
  }

  /// Etiqueta amigable para quién originó un comando. Pensada para la app
  /// móvil, donde no tiene sentido mostrarle al cliente roles internos como
  /// "operator" o "technician".
  static String actorLabel(String? role) {
    switch (role) {
      case 'admin':
      case 'operator':
      case 'technician':
        return 'Equipo First Protection';
      case 'client':
        return 'Tú';
      default:
        return '';
    }
  }
}
