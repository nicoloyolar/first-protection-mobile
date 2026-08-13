import 'package:first_protection/src/apps/admin_web/controllers/admin_dashboard_controller.dart';
import 'package:first_protection/src/apps/admin_web/models/admin_device_view_data.dart';
import 'package:first_protection/src/apps/admin_web/ui/admin_web_login_screen.dart';
import 'package:first_protection/src/apps/admin_web/ui/device_inventory_screen.dart';
import 'package:first_protection/core/services/auth_service.dart';
import 'package:first_protection/core/models/device_command_model.dart';
import 'package:first_protection/core/services/database_service.dart';
import 'package:first_protection/core/theme/app_colors.dart';
import 'package:first_protection/core/utils/device_command_status_ui.dart';
import 'package:first_protection/core/utils/device_event_formatter.dart';
import 'package:first_protection/core/utils/time_ago.dart';
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
  final DatabaseService _databaseService = DatabaseService();
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

          // Filtro por organización/flota: el modelo de datos ya soporta
          // multi-organización, pero la UI solo la muestra cuando hay más
          // de una organización real en la flota — con una sola, el filtro
          // no aporta nada y solo ensucia el panel.
          if (_dashboardController.organizations.length > 1) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _organizationChip("TODAS"),
                  ..._dashboardController.organizations.map(
                    _organizationChip,
                  ),
                ],
              ),
            ),
          ],
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

  Widget _organizationChip(String organizationId) {
    final isSelected = _dashboardController.organizationFilter == organizationId;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => _dashboardController.setOrganizationFilter(organizationId),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.blueAccent.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.blueAccent : Colors.white10,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.apartment_rounded,
                size: 11,
                color: isSelected ? Colors.blueAccent : Colors.white24,
              ),
              const SizedBox(width: 5),
              Text(
                organizationId,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.blueAccent : Colors.white38,
                ),
              ),
            ],
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
          Row(
            children: [
              _tabButton("CONTROL", 0),
              _tabButton("DUEÑO", 1),
              _tabButton("DIAGNÓSTICO", 2),
              _tabButton("EVENTOS", 3),
              _tabButton("COMANDOS", 4),
            ],
          ),
          const Divider(color: Colors.white10, height: 30),
          Flexible(
            child: SingleChildScrollView(
              child: switch (_activeTab) {
                1 => _buildOwnerTab(info),
                2 => _buildDiagnosticoTab(info),
                3 => _buildEventosTab(info),
                4 => _buildComandosTab(info),
                _ => _buildControlTab(info),
              },
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white24,
              fontSize: 9,
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

  Widget _buildDiagnosticoTab(Map<String, dynamic> info) {
    final network = info['network'] is Map
        ? info['network'] as Map
        : const {};
    final power = info['power'] is Map ? info['power'] as Map : const {};
    final location = info['location'] is Map
        ? info['location'] as Map
        : const {};

    final int? rssi = network['rssi'] is num
        ? (network['rssi'] as num).toInt()
        : null;
    final int? lastSeen = _asMillis(
      info['timestamp'] ?? info['ultimaActualizacion'],
    );
    final bool isOnline = network.containsKey('online')
        ? network['online'] == true
        : _isRecentlySeen(lastSeen);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isOnline ? Colors.greenAccent : Colors.white24,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isOnline ? "EN LÍNEA" : "SIN CONEXIÓN",
              style: TextStyle(
                color: isOnline ? Colors.greenAccent : Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              "Últ. reporte: ${formatTimeAgo(lastSeen)}",
              style: const TextStyle(color: Colors.white24, fontSize: 9),
            ),
          ],
        ),
        const SizedBox(height: 20),

        _sectionLabel("DISPOSITIVO"),
        const SizedBox(height: 12),
        _rowDetail(
          Icons.memory,
          "FIRMWARE",
          _orSinDato(info['firmwareVersion']?.toString()),
        ),
        const SizedBox(height: 12),
        _rowDetail(
          Icons.developer_board,
          "HARDWARE",
          _orSinDato(info['hardwareVersion']?.toString()),
        ),

        const SizedBox(height: 20),
        _sectionLabel("CONECTIVIDAD"),
        const SizedBox(height: 12),
        _rowDetail(Icons.signal_cellular_alt, "SEÑAL RED", _signalLabel(rssi)),
        const SizedBox(height: 12),
        _rowDetail(
          Icons.satellite_alt,
          "GPS",
          location['gpsFix'] == false
              ? "Sin fix"
              : "${_orSinDato(location['satellites']?.toString())} satélites · ±${_orSinDato(location['accuracyMeters']?.toString())} m",
        ),

        const SizedBox(height: 20),
        _sectionLabel("ENERGÍA"),
        const SizedBox(height: 12),
        _rowDetail(
          Icons.battery_charging_full,
          "BATERÍA DE RESPALDO",
          power['backupBatteryPercent'] != null
              ? "${power['backupBatteryPercent']}%"
              : "Sin dato",
        ),
        const SizedBox(height: 12),
        _rowDetail(
          Icons.bolt,
          "VOLTAJE VEHÍCULO",
          "${_orSinDato((power['vehicleVoltage'] ?? info['voltaje'])?.toString())} V",
        ),
        const SizedBox(height: 12),
        _rowDetail(
          Icons.power_input,
          "ALIMENTACIÓN EXTERNA",
          power['externalPower'] == true ? "Conectada" : "Desconectada",
        ),
      ],
    );
  }

  /// Estado de los comandos enviados a este dispositivo. Hoy el estado casi
  /// siempre va a mostrar "Pendiente" porque el actuador todavía se escribe
  /// directo (ver hito de sincronización en docs/plan-de-trabajo.md); esta
  /// vista deja lista la UI para cuando el simulador/hardware empiece a
  /// mandar el ACK real.
  Widget _buildComandosTab(Map<String, dynamic> info) {
    final deviceId = info['id']?.toString() ?? '';
    if (deviceId.isEmpty) {
      return const Text(
        "Sin dispositivo seleccionado",
        style: TextStyle(color: Colors.white24, fontSize: 11),
      );
    }

    return StreamBuilder<List<DeviceCommand>>(
      stream: _databaseService.escucharComandosDispositivo(deviceId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: AppColors.primaryOrange,
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        }

        final comandos = snapshot.data!;
        if (comandos.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: Text(
                "Sin comandos registrados",
                style: TextStyle(color: Colors.white24, fontSize: 11),
              ),
            ),
          );
        }

        return Column(
          children: comandos.take(30).map(_comandoTile).toList(),
        );
      },
    );
  }

  Widget _comandoTile(DeviceCommand comando) {
    final estadoUi = DeviceCommandStatusUi.forStatus(comando.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: estadoUi.color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  "${DeviceCommandStatusUi.targetLabel(comando.target)} → ${comando.value == true ? 'activar' : 'desactivar'}",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatTimeAgo(comando.createdAt),
                style: const TextStyle(color: Colors.white24, fontSize: 9),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: estadoUi.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                estadoUi.label,
                style: TextStyle(
                  color: estadoUi.color,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (comando.requestedByRole.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  "· solicitado por ${comando.requestedByRole}",
                  style: const TextStyle(color: Colors.white24, fontSize: 9),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventosTab(Map<String, dynamic> info) {
    final deviceId = info['id']?.toString() ?? '';
    if (deviceId.isEmpty) {
      return const Text(
        "Sin dispositivo seleccionado",
        style: TextStyle(color: Colors.white24, fontSize: 11),
      );
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _databaseService.escucharEventosDispositivo(deviceId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: AppColors.primaryOrange,
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        }

        final eventos = snapshot.data!;
        if (eventos.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: Text(
                "Sin eventos registrados",
                style: TextStyle(color: Colors.white24, fontSize: 11),
              ),
            ),
          );
        }

        return Column(
          children: eventos.take(30).map(_eventoTile).toList(),
        );
      },
    );
  }

  Widget _eventoTile(Map<String, dynamic> evento) {
    final severidad = evento['severidad']?.toString() ?? 'info';
    final color = switch (severidad) {
      'critical' => Colors.redAccent,
      'warning' => Colors.orangeAccent,
      _ => Colors.white38,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  DeviceEventFormatter.describe(evento),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatTimeAgo(evento['timestamp'] as int?),
                style: const TextStyle(color: Colors.white24, fontSize: 9),
              ),
            ],
          ),
          if ((evento['actorRole'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(
              "Solicitado por: ${evento['actorRole']}",
              style: const TextStyle(color: Colors.white24, fontSize: 9),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white24,
        fontSize: 9,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  String _orSinDato(String? value) =>
      (value == null || value.isEmpty) ? "Sin dato" : value;

  String _signalLabel(int? rssi) {
    if (rssi == null) return "Sin dato";
    if (rssi >= -70) return "Buena ($rssi dBm)";
    if (rssi >= -90) return "Regular ($rssi dBm)";
    return "Débil ($rssi dBm)";
  }

  int? _asMillis(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }

  bool _isRecentlySeen(int? lastSeenMillis) {
    if (lastSeenMillis == null || lastSeenMillis == 0) return false;
    final ageMs = DateTime.now().millisecondsSinceEpoch - lastSeenMillis;
    return ageMs >= 0 && ageMs <= const Duration(minutes: 5).inMilliseconds;
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
    // Corta corriente es el único actuador que puede ser peligroso en el
    // sentido físico (inmovilizar un vehículo en marcha) — ver
    // docs/plan-de-trabajo.md Pista B. Desactivarlo (restaurar el motor) es
    // la acción segura/de recuperación, así que solo se refuerza el activar.
    final esCorteCritico = field == 'cortaCorriente' && value == true;

    bool? confirmed;
    if (esCorteCritico) {
      confirmed = await _confirmarCorteCorrienteReforzado(info);
    } else {
      confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF141414),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
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
    }

    if (confirmed != true) return;

    await _dashboardController.updateDeviceCommand(
      deviceId: info['id'].toString(),
      field: field,
      value: value,
      actorRole: 'admin',
    );
  }

  /// Segunda capa de confirmación exclusiva para activar el corte de
  /// corriente: el admin tiene que escribir la patente de la unidad para
  /// habilitar el botón. Si el último dato de velocidad conocido es mayor a
  /// 0, se agrega una advertencia explícita de que el vehículo podría estar
  /// en movimiento. Esto no bloquea la acción ni decide política de negocio
  /// (eso sigue abierto, ver `physical-device-integration.md`) — solo hace
  /// más difícil que sea un click accidental.
  Future<bool?> _confirmarCorteCorrienteReforzado(
    Map<String, dynamic> info,
  ) async {
    final patente = (info['patente'] ?? 'S/P').toString();
    final velocidad = (info['velocidad'] is num)
        ? (info['velocidad'] as num).toDouble()
        : 0.0;
    final controller = TextEditingController();

    try {
      return await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setModalState) {
            final habilitado =
                controller.text.trim().toUpperCase() == patente.toUpperCase();

            return AlertDialog(
              backgroundColor: const Color(0xFF141414),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Cortar corriente",
                      style: GoogleFonts.oswald(color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Unidad: ${info['alias'] ?? info['id']}\nPatente: $patente",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  if (velocidad > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.redAccent.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        "El último dato conocido muestra ${velocidad.toStringAsFixed(1)} km/h — "
                        "el vehículo podría estar en movimiento.",
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    "Escribe la patente ($patente) para confirmar:",
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (_) => setModalState(() {}),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
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
                  onPressed: habilitado
                      ? () => Navigator.pop(context, true)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    disabledBackgroundColor: Colors.white10,
                  ),
                  child: const Text(
                    "CORTAR CORRIENTE",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    } finally {
      controller.dispose();
    }
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
