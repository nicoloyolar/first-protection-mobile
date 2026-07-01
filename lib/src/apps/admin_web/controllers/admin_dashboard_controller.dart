import 'dart:async';

import 'package:first_protection/core/services/database_service.dart';
import 'package:first_protection/src/apps/admin_web/models/admin_device_view_data.dart';
import 'package:flutter/foundation.dart';

class AdminDashboardController extends ChangeNotifier {
  final DatabaseService _databaseService;
  StreamSubscription<List<Map<String, dynamic>>>? _devicesSubscription;
  Timer? _devicesDebounce;
  List<Map<String, dynamic>> _pendingDevices = const [];

  List<AdminDeviceViewData> _devices = [];
  AdminDeviceViewData? _selectedDevice;
  String _searchQuery = '';
  String _statusFilter = 'TODOS';
  bool _isFollowing = false;

  AdminDashboardController({DatabaseService? databaseService})
    : _databaseService = databaseService ?? DatabaseService();

  List<AdminDeviceViewData> get devices => List.unmodifiable(_devices);

  AdminDeviceViewData? get selectedDevice => _selectedDevice;

  String get searchQuery => _searchQuery;

  String get statusFilter => _statusFilter;

  bool get isFollowing => _isFollowing;

  int get alertCount => _devices.where((device) => device.isAlert).length;

  int get onlineCount => _devices.where((device) => device.isOnline).length;

  List<AdminDeviceViewData> get filteredDevices => _devices
      .where(
        (device) =>
            device.matchesSearch(_searchQuery) &&
            device.matchesStatus(_statusFilter),
      )
      .toList();

  void start() {
    _devicesSubscription ??= _databaseService.escucharDispositivosAdmin().listen(
      (devices) {
        _pendingDevices = devices;
        _devicesDebounce?.cancel();
        _devicesDebounce = Timer(
          const Duration(milliseconds: 150),
          () => _applyDeviceSnapshot(_pendingDevices),
        );
      },
    );
  }

  void setSearchQuery(String value) {
    if (_searchQuery == value) return;
    _searchQuery = value;
    notifyListeners();
  }

  void setStatusFilter(String value) {
    if (_statusFilter == value) return;
    _statusFilter = value;
    notifyListeners();
  }

  void selectDevice(AdminDeviceViewData device) {
    _selectedDevice = device;
    _isFollowing = true;
    notifyListeners();
  }

  void clearSelection() {
    if (_selectedDevice == null) return;
    _selectedDevice = null;
    notifyListeners();
  }

  void toggleFollowing() {
    _isFollowing = !_isFollowing;
    notifyListeners();
  }

  Future<void> updateDeviceCommand({
    required String deviceId,
    required String field,
    required bool value,
    String actorRole = 'admin',
  }) {
    return _databaseService.actualizarComandoDispositivo(
      idDispositivo: deviceId,
      campo: field,
      valor: value,
      actorRole: actorRole,
    );
  }

  void _applyDeviceSnapshot(List<Map<String, dynamic>> devices) {
    try {
      _devices = devices.map(AdminDeviceViewData.fromMap).toList();
      _refreshSelectedDevice();
      notifyListeners();
    } catch (error) {
      debugPrint("Error en Dashboard: $error");
    }
  }

  void _refreshSelectedDevice() {
    final selected = _selectedDevice;
    if (selected == null) return;

    try {
      _selectedDevice = _devices.firstWhere((device) => device.id == selected.id);
    } catch (_) {
      _selectedDevice = selected;
    }
  }

  @override
  void dispose() {
    _devicesSubscription?.cancel();
    _devicesDebounce?.cancel();
    super.dispose();
  }
}
