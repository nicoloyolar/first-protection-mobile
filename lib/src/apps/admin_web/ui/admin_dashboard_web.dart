import 'package:first_protection/src/apps/admin_web/controllers/admin_dashboard_controller.dart';
import 'package:first_protection/src/apps/admin_web/models/admin_device_view_data.dart';
import 'package:first_protection/src/apps/admin_web/ui/admin_web_login_screen.dart';
import 'package:first_protection/src/apps/admin_web/ui/device_inventory_screen.dart';
import 'package:first_protection/core/services/auth_service.dart';
import 'package:first_protection/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminDashboardWeb extends StatefulWidget {
  const AdminDashboardWeb({super.key});

  @override
  State<AdminDashboardWeb> createState() => _AdminDashboardWebState();
}

class _AdminDashboardWebState extends State<AdminDashboardWeb> {
  GoogleMapController? _mapController;
  final AuthService _authService = AuthService();
  late final AdminDashboardController _dashboardController;

  int _activeTab = 0;

  static const CameraPosition _kInitialPosition = CameraPosition(
    target: LatLng(-36.82699, -73.04977),
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    _dashboardController = AdminDashboardController()
      ..addListener(_handleDashboardChanged)
      ..start();
  }

  @override
  void dispose() {
    _dashboardController
      ..removeListener(_handleDashboardChanged)
      ..dispose();
    super.dispose();
  }

  void _handleDashboardChanged() {
    if (!mounted) return;
    setState(() {});

    final selectedDevice = _dashboardController.selectedDevice;
    if (_dashboardController.isFollowing && selectedDevice?.isOnline == true) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(selectedDevice!.position),
      );
    }
  }

  void _seleccionarVehiculo(AdminDeviceViewData vData) {
    _dashboardController.selectDevice(vData);
    setState(() => _activeTab = 0);
    if (vData.isOnline) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(vData.position, 16),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final listaFiltrada = _dashboardController.filteredDevices;
    final vehiculoActualizado = _dashboardController.selectedDevice;
    final markers = _buildMarkers(_dashboardController.devices);

    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      body: Row(
        children: [
          Container(
            width: 320,
            color: const Color(0xFF141414),
            child: Column(
              children: [
                _buildSidebarHeader(),
                Expanded(
                  child: _dashboardController.devices.isEmpty
                      ? _buildEmptyState(
                          message: "CONECTANDO CON EL SISTEMA...",
                          icon: Icons.sensors_off,
                        )
                      : listaFiltrada.isEmpty
                      ? _buildEmptyState(
                          message: "SIN RESULTADOS",
                          icon: Icons.manage_search,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: listaFiltrada.length,
                          itemBuilder: (context, index) =>
                              _buildPremiumVehicleCard(listaFiltrada[index]),
                        ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: GoogleMap(
                      initialCameraPosition: _kInitialPosition,
                      onMapCreated: (controller) => _mapController = controller,
                      markers: markers,
                      zoomControlsEnabled: false,
                    ),
                  ),
                ),
                if (vehiculoActualizado != null)
                  Positioned(
                    top: 40,
                    right: 40,
                    child: _buildPremiumPanel(vehiculoActualizado.toMap()),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Set<Marker> _buildMarkers(List<AdminDeviceViewData> devices) {
    return devices.where((device) => device.isOnline).map((device) {
      return Marker(
        markerId: MarkerId(device.id),
        position: device.position,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          device.isAlert ? BitmapDescriptor.hueRed : BitmapDescriptor.hueOrange,
        ),
        onTap: () => _seleccionarVehiculo(device),
      );
    }).toSet();
  }

  Widget _buildSidebarHeader() {
    final int alertas = _dashboardController.alertCount;

    return Container(
      padding: const EdgeInsets.fromLTRB(25, 40, 25, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FIRST PROTECTION',
                    style: GoogleFonts.oswald(
                      color: AppColors.primaryOrange,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Text(
                    'COMMAND CENTER',
                    style: TextStyle(
                      color: Colors.white24,
                      fontSize: 10,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DeviceInventoryScreen(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.settings_suggest_outlined,
                        color: Colors.white38,
                        size: 22,
                      ),
                      tooltip: "Gestión de Inventario",
                      hoverColor: AppColors.primaryOrange.withValues(alpha:0.1),
                      splashRadius: 24,
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: IconButton(
                      onPressed: _logout,
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: Colors.white38,
                        size: 22,
                      ),
                      tooltip: "Cerrar sesión",
                      hoverColor: AppColors.primaryOrange.withValues(alpha:0.1),
                      splashRadius: 24,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 25),

          Container(
            height: 45,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Center(
              child: TextField(
                onChanged: _dashboardController.setSearchQuery,
                textAlignVertical: TextAlignVertical.center,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: "Buscar unidad...",
                  hintStyle: const TextStyle(color: Colors.white24),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.primaryOrange,
                    size: 18,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),

          const SizedBox(height: 15),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _filterChip("TODOS", _dashboardController.devices.length),
                _filterChip("ALERTA", alertas, isCritical: true),
                _filterChip(
                  "ONLINE",
                  _dashboardController.onlineCount,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, int count, {bool isCritical = false}) {
    bool isSelected = _dashboardController.statusFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => _dashboardController.setStatusFilter(label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryOrange
                : Colors.white.withValues(alpha:0.03),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            "$label ($count)",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? Colors.black
                  : (isCritical && count > 0
                        ? Colors.redAccent
                        : Colors.white38),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumPanel(Map<String, dynamic> info) {
    return Container(
      width: 320,
      constraints: const BoxConstraints(maxHeight: 620),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141414).withValues(alpha:0.98),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryOrange.withValues(alpha:0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha:0.5), blurRadius: 20),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info['alias'] ?? "Unidad",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      info['patente'] ?? "S/P",
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white38, size: 20),
                onPressed: _dashboardController.clearSelection,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(children: [_tabButton("CONTROL", 0), _tabButton("DUEÑO", 1)]),
          const Divider(color: Colors.white10, height: 30),
          Flexible(
            child: SingleChildScrollView(
              child: _activeTab == 0
                  ? _buildControlTab(info)
                  : _buildOwnerTab(info),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    bool isActive = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? AppColors.primaryOrange : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white24,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlTab(Map<String, dynamic> info) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _statusSquare(
              icon: Icons.smoke_free,
              label: "HUMO",
              isActive: info['humo'] == true,
              activeColor: Colors.orange,
              onTap: () => _confirmCommand(
                info,
                'humo',
                !(info['humo'] == true),
                'humo',
              ),
            ),
            _statusSquare(
              icon: Icons.notifications_active,
              label: "PROTOCOLO",
              isActive: info['protocoloActivo'] == true,
              activeColor: Colors.redAccent,
              onTap: () => _confirmCommand(
                info,
                'protocoloActivo',
                !(info['protocoloActivo'] == true),
                'protocolo',
              ),
            ),
            _statusSquare(
              icon: Icons.power_settings_new,
              label: "CORTE",
              isActive: info['cortaCorriente'] == true,
              activeColor: Colors.blueAccent,
              onTap: () => _confirmCommand(
                info,
                'cortaCorriente',
                !(info['cortaCorriente'] == true),
                'corte de corriente',
              ),
            ),
          ],
        ),
        const SizedBox(height: 25),
        _rowDetail(
          Icons.speed,
          "VELOCIDAD",
          "${info['velocidad']?.toStringAsFixed(1) ?? '0'} km/h",
        ),
        const SizedBox(height: 12),
        _rowDetail(
          Icons.location_on,
          "LATITUD",
          "${info['latitud']?.toStringAsFixed(4) ?? '0'}",
        ),
        const SizedBox(height: 12),
        _rowDetail(
          Icons.location_on,
          "LONGITUD",
          "${info['longitud']?.toStringAsFixed(4) ?? '0'}",
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 45,
          child: ElevatedButton.icon(
            onPressed: _dashboardController.toggleFollowing,
            icon: Icon(
              _dashboardController.isFollowing
                  ? Icons.gps_fixed
                  : Icons.gps_not_fixed,
              size: 16,
            ),
            label: Text(
              _dashboardController.isFollowing ? "SIGUIENDO..." : "RASTREAR",
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _dashboardController.isFollowing
                  ? AppColors.primaryOrange
                  : Colors.white10,
              foregroundColor: _dashboardController.isFollowing
                  ? Colors.black
                  : Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOwnerTab(Map<String, dynamic> vData) {
    return Column(
      children: [
        _readOnlyDetail(
          Icons.person_outline,
          'Nombre',
          vData['nombrePropietario'] ?? '---',
        ),
        const SizedBox(height: 15),
        _readOnlyDetail(
          Icons.badge_outlined,
          'RUT',
          vData['rutPropietario'] ?? '---',
        ),
        const SizedBox(height: 15),
        _readOnlyDetail(
          Icons.email_outlined,
          'Email',
          vData['emailPropietario'] ?? '---',
        ),
        const SizedBox(height: 15),
        _readOnlyDetail(
          Icons.phone_android_outlined,
          'Teléfono',
          vData['telefonoPropietario'] ?? '---',
        ),
        const SizedBox(height: 15),
        _readOnlyDetail(
          Icons.home_outlined,
          'Domicilio',
          vData['domicilioPropietario'] ?? '---',
        ),
        const SizedBox(height: 25),

        const Text(
          "Para editar estos datos, diríjase al módulo de Gestión de Dispositivos.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white12,
            fontSize: 9,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _readOnlyDetail(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryOrange.withValues(alpha:0.5), size: 16),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: Colors.white24,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              value,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statusSquare({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha:0.1)
              : Colors.white.withValues(alpha:0.02),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isActive ? activeColor : Colors.white10),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isActive ? activeColor : Colors.white10,
              size: 18,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : Colors.white24,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowDetail(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryOrange, size: 14),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white24, fontSize: 8),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState({required String message, required IconData icon}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white10, size: 50),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(color: Colors.white24, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumVehicleCard(AdminDeviceViewData device) {
    final bool isSel = _dashboardController.selectedDevice?.id == device.id;
    return GestureDetector(
      onTap: () => _seleccionarVehiculo(device),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSel
              ? AppColors.primaryOrange.withValues(alpha:0.1)
              : Colors.white.withValues(alpha:0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSel ? AppColors.primaryOrange : Colors.white10,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              device.alias,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            Text(
              device.patente,
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCommand(
    Map<String, dynamic> info,
    String field,
    bool value,
    String label,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          value ? "Activar $label" : "Desactivar $label",
          style: GoogleFonts.oswald(color: AppColors.primaryOrange),
        ),
        content: Text(
          "Unidad: ${info['alias'] ?? info['id']}\nPatente: ${info['patente'] ?? 'S/P'}",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "CANCELAR",
              style: TextStyle(color: Colors.white38),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
            ),
            child: const Text(
              "CONFIRMAR",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _dashboardController.updateDeviceCommand(
      deviceId: info['id'].toString(),
      field: field,
      value: value,
      actorRole: 'admin',
    );
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
      (route) => false,
    );
  }
}
