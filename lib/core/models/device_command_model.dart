enum DeviceCommandType {
  setActuator,
  setSystemMode,
  requestTelemetryNow,
  restartDevice,
  updateConfig,
}

enum DeviceCommandTarget {
  humo,
  sirena,
  cortaCorriente,
  protocoloActivo,
  systemMode,
  telemetry,
  device,
}

enum DeviceCommandStatus {
  pending,
  received,
  executed,
  rejected,
  failed,
  expired,
}

class DeviceCommand {
  final String id;
  final String deviceId;
  final DeviceCommandType type;
  final DeviceCommandTarget target;
  final dynamic value;
  final DeviceCommandStatus status;
  final String requestedBy;
  final String requestedByRole;
  final int createdAt;
  final int expiresAt;
  final int? receivedAt;
  final int? executedAt;
  final String? errorCode;
  final String? message;

  const DeviceCommand({
    required this.id,
    required this.deviceId,
    required this.type,
    required this.target,
    required this.value,
    required this.status,
    required this.requestedBy,
    required this.requestedByRole,
    required this.createdAt,
    required this.expiresAt,
    this.receivedAt,
    this.executedAt,
    this.errorCode,
    this.message,
  });

  bool get isFinished =>
      status == DeviceCommandStatus.executed ||
      status == DeviceCommandStatus.rejected ||
      status == DeviceCommandStatus.failed ||
      status == DeviceCommandStatus.expired;

  factory DeviceCommand.fromMap(
    String id,
    String deviceId,
    Map<dynamic, dynamic> data,
  ) {
    return DeviceCommand(
      id: id,
      deviceId: deviceId,
      type: _typeFromString(data['type']?.toString()),
      target: _targetFromString(data['target']?.toString()),
      value: data['value'],
      status: _statusFromString(data['status']?.toString()),
      requestedBy: data['requestedBy']?.toString() ?? '',
      requestedByRole: data['requestedByRole']?.toString() ?? '',
      createdAt: _asInt(data['createdAt']),
      expiresAt: _asInt(data['expiresAt']),
      receivedAt: _nullableInt(data['receivedAt']),
      executedAt: _nullableInt(data['executedAt']),
      errorCode: data['errorCode']?.toString(),
      message: data['message']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'type': type.name,
    'target': target.name,
    'value': value,
    'status': status.name,
    'requestedBy': requestedBy,
    'requestedByRole': requestedByRole,
    'createdAt': createdAt,
    'expiresAt': expiresAt,
    if (receivedAt != null) 'receivedAt': receivedAt,
    if (executedAt != null) 'executedAt': executedAt,
    if (errorCode != null) 'errorCode': errorCode,
    if (message != null) 'message': message,
  };

  DeviceCommand copyWith({
    DeviceCommandStatus? status,
    int? receivedAt,
    int? executedAt,
    String? errorCode,
    String? message,
  }) {
    return DeviceCommand(
      id: id,
      deviceId: deviceId,
      type: type,
      target: target,
      value: value,
      status: status ?? this.status,
      requestedBy: requestedBy,
      requestedByRole: requestedByRole,
      createdAt: createdAt,
      expiresAt: expiresAt,
      receivedAt: receivedAt ?? this.receivedAt,
      executedAt: executedAt ?? this.executedAt,
      errorCode: errorCode ?? this.errorCode,
      message: message ?? this.message,
    );
  }

  static DeviceCommandType _typeFromString(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'setsystemmode':
        return DeviceCommandType.setSystemMode;
      case 'requesttelemetrynow':
        return DeviceCommandType.requestTelemetryNow;
      case 'restartdevice':
        return DeviceCommandType.restartDevice;
      case 'updateconfig':
        return DeviceCommandType.updateConfig;
      default:
        return DeviceCommandType.setActuator;
    }
  }

  static DeviceCommandTarget _targetFromString(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'sirena':
        return DeviceCommandTarget.sirena;
      case 'cortacorriente':
        return DeviceCommandTarget.cortaCorriente;
      case 'protocoloactivo':
        return DeviceCommandTarget.protocoloActivo;
      case 'systemmode':
        return DeviceCommandTarget.systemMode;
      case 'telemetry':
        return DeviceCommandTarget.telemetry;
      case 'device':
        return DeviceCommandTarget.device;
      default:
        return DeviceCommandTarget.humo;
    }
  }

  static DeviceCommandStatus _statusFromString(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'received':
        return DeviceCommandStatus.received;
      case 'executed':
        return DeviceCommandStatus.executed;
      case 'rejected':
        return DeviceCommandStatus.rejected;
      case 'failed':
        return DeviceCommandStatus.failed;
      case 'expired':
        return DeviceCommandStatus.expired;
      default:
        return DeviceCommandStatus.pending;
    }
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _nullableInt(dynamic value) {
    if (value == null) return null;
    return _asInt(value);
  }
}
