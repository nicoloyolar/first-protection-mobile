enum AppUserRole { admin, operator, technician, client }

enum AccountType { internal, company, family, individual }

class AppUserProfile {
  final String uid;
  final String email;
  final String displayName;
  final AppUserRole role;
  final AccountType accountType;
  final String organizationId;
  final List<String> vehicleIds;
  final bool active;

  const AppUserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.accountType,
    required this.organizationId,
    this.vehicleIds = const [],
    this.active = true,
  });

  bool get canAccessAdmin =>
      active &&
      (role == AppUserRole.admin ||
          role == AppUserRole.operator ||
          role == AppUserRole.technician);

  factory AppUserProfile.fromMap(String uid, Map<dynamic, dynamic> data) {
    return AppUserProfile(
      uid: uid,
      email: data['email']?.toString() ?? '',
      displayName:
          data['nombre']?.toString() ??
          data['displayName']?.toString() ??
          data['nombreCompleto']?.toString() ??
          '',
      role: _roleFromString(
        data['role']?.toString() ?? data['rol']?.toString(),
      ),
      accountType: _accountTypeFromString(
        data['accountType']?.toString() ?? data['tipoCuenta']?.toString(),
      ),
      organizationId:
          data['organizationId']?.toString() ??
          data['organizacionId']?.toString() ??
          'first-protection',
      vehicleIds: _idsFromValue(data['mis_vehiculos'] ?? data['vehicleIds']),
      active: data['active'] != false && data['activo'] != false,
    );
  }

  Map<String, dynamic> toMap() => {
    'email': email,
    'nombre': displayName,
    'role': role.name,
    'accountType': accountType.name,
    'organizationId': organizationId,
    'vehicleIds': vehicleIds,
    'active': active,
  };

  static AppUserRole _roleFromString(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'admin':
      case 'administrador':
        return AppUserRole.admin;
      case 'operator':
      case 'operador':
        return AppUserRole.operator;
      case 'technician':
      case 'tecnico':
      case 'técnico':
        return AppUserRole.technician;
      default:
        return AppUserRole.client;
    }
  }

  static AccountType _accountTypeFromString(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'internal':
      case 'interno':
      case 'first-protection':
        return AccountType.internal;
      case 'company':
      case 'empresa':
        return AccountType.company;
      case 'family':
      case 'familia':
        return AccountType.family;
      default:
        return AccountType.individual;
    }
  }

  static List<String> _idsFromValue(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }

    if (value is Map) {
      return value.keys.map((key) => key.toString()).toList();
    }

    return const [];
  }
}
