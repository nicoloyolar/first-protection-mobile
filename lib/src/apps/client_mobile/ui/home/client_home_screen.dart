import 'package:first_protection/core/controllers/vehiculo_controller.dart';
import 'package:first_protection/core/models/estado_dispositivo_model.dart';
import 'package:first_protection/src/apps/client_mobile/ui/mobile_login_screen.dart';
import 'package:first_protection/src/apps/client_mobile/ui/vincular_vehiculo_screen.dart';
import 'package:first_protection/src/apps/client_mobile/ui/widgets/security_slider.dart';
import 'package:first_protection/core/services/auth_service.dart';
import 'package:first_protection/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  GoogleMapController? _mapController;

  final String _mapStyle =
      '[{"elementType":"geometry","stylers":[{"color":"#212121"}]},{"elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},{"elementType":"labels.text.stroke","stylers":[{"color":"#212121"}]},{"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#757575"}]},{"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},{"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#2c2c2c"}]},{"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"}]}]';

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _abrirNavegacionExterna(double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url, mode: LaunchMode.externalApplication);
    }
  }

  void _handleLogout(BuildContext context) async {
    final navigator = Navigator.of(context);
    final authService = AuthService();
    await authService.logout();

    if (!mounted) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vCtrl = Provider.of<VehiculoController>(context);
    final vehiculo = vCtrl.vehiculoSeleccionado;
    final estado = vCtrl.estadoActual;

    if (vehiculo == null || estado == null) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundBlack,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryOrange),
        ),
      );
    }

    LatLng posicionVehiculo = LatLng(estado.latitud, estado.longitud);

    return Scaffold(
      backgroundColor: estado.protocoloActivo
          ? const Color(0xFF2A0505)
          : AppColors.backgroundBlack,
      drawer: _buildVehicleDrawer(context, vCtrl),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            Text(
              vehiculo.alias.toUpperCase(),
              style: GoogleFonts.oswald(
                color: Colors.white,
                letterSpacing: 1.5,
                fontSize: 20,
              ),
            ),
            Text(
              vehiculo.patente,
              style: GoogleFonts.roboto(
                color: Colors.white54,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.5),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: posicionVehiculo,
                      zoom: 16,
                    ),
                    style: _mapStyle,
                    onMapCreated: (controller) => _mapController = controller,
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    markers: {
                      Marker(
                        markerId: const MarkerId('vehiculo'),
                        position: posicionVehiculo,
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          estado.protocoloActivo
                              ? BitmapDescriptor.hueRed
                              : BitmapDescriptor.hueOrange,
                        ),
                      ),
                    },
                  ),
                ),
                Positioned(
                  bottom: 30,
                  right: 30,
                  child: FloatingActionButton.small(
                    heroTag: "gps_btn",
                    backgroundColor: AppColors.primaryOrange,
                    child: const Icon(
                      Icons.navigation_rounded,
                      color: Colors.black,
                    ),
                    onPressed: () => _abrirNavegacionExterna(
                      estado.latitud,
                      estado.longitud,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(flex: 5, child: _buildControlPanel(vCtrl, estado)),
        ],
      ),
    );
  }

  Widget _buildControlPanel(
    VehiculoController vCtrl,
    EstadoDispositivo estado,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black, blurRadius: 20, offset: Offset(0, -5)),
        ],
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusIndicator(
              estado.protocoloActivo,
              estado.cortaCorriente,
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                _buildTelemetriaCard(
                  Icons.bolt,
                  "${estado.voltaje}V",
                  "BATERÍA",
                ),
                const SizedBox(width: 15),
                _buildTelemetriaCard(
                  Icons.speed,
                  "${estado.velocidad.toInt()}",
                  "KM/H",
                ),
              ],
            ),

            const SizedBox(height: 15),

            SecuritySlider(
              isActive: estado.cortaCorriente,
              text: estado.cortaCorriente
                  ? "DESLIZA PARA HABILITAR MOTOR"
                  : "DESLIZA PARA CORTAR CORRIENTE",
              onFinished: () async => await vCtrl.cambiarEstadoCortaCorriente(
                !estado.cortaCorriente,
              ),
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: _buildSubsystemButton(
                    icon: estado.humoActivo
                        ? Icons.cloud
                        : Icons.cloud_outlined,
                    label: "HUMO",
                    activeColor: Colors.blueAccent,
                    isActive: estado.humoActivo,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      vCtrl.cambiarEstadoHumo(!estado.humoActivo);
                    },
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildSubsystemButton(
                    icon: estado.protocoloActivo
                        ? Icons.notifications_active
                        : Icons.notifications_none,
                    label: "SIRENA",
                    activeColor: Colors.redAccent,
                    isActive: estado.protocoloActivo,
                    onTap: () {
                      HapticFeedback.heavyImpact();
                      vCtrl.cambiarEstadoProtocolo(!estado.protocoloActivo);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Text(
              "ID SEGURO: ${estado.idDispositivo}",
              style: GoogleFonts.poppins(
                color: Colors.white10,
                fontSize: 10,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetriaCard(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha:0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha:0.05)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryOrange, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.oswald(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubsystemButton({
    required IconData icon,
    required String label,
    required Color activeColor,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 75,
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha:0.15)
              : Colors.white.withValues(alpha:0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? activeColor : Colors.white.withValues(alpha:0.05),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? activeColor : Colors.white38,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.oswald(
                color: isActive ? activeColor : Colors.white38,
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(bool isAlert, bool isCut) {
    Color color;
    String text;
    IconData icon;

    if (isAlert) {
      color = Colors.red;
      text = "PROTOCOLO DE ROBO";
      icon = Icons.warning_amber_rounded;
    } else if (isCut) {
      color = AppColors.primaryOrange;
      text = "MOTOR BLOQUEADO";
      icon = Icons.lock;
    } else {
      color = Colors.green;
      text = "SISTEMA SEGURO";
      icon = Icons.shield;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha:0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Text(
            text,
            style: GoogleFonts.oswald(
              color: color,
              fontSize: 18,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleDrawer(BuildContext context, VehiculoController vCtrl) {
    return Drawer(
      backgroundColor: const Color(0xFF0D0D0D),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 30),
            decoration: const BoxDecoration(color: Color(0xFF080808)),
            child: Column(
              children: [
                Container(
                  height: 110,
                  width: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.backgroundBlack,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryOrange.withValues(alpha:0.15),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                    border: Border.all(
                      color: AppColors.primaryOrange.withValues(alpha:0.4),
                      width: 1.5,
                    ),
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Image.asset(
                        'assets/images/logo-first-protection.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  "CENTRAL DE MANDO",
                  style: GoogleFonts.oswald(
                    color: Colors.white,
                    letterSpacing: 2,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0D0D0D),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      "SELECCIONAR DISPOSITIVO",
                      style: GoogleFonts.poppins(
                        color: Colors.white24,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      itemCount: vCtrl.listaVehiculos.length,
                      itemBuilder: (context, index) {
                        final v = vCtrl.listaVehiculos[index];
                        final esSeleccionado =
                            v.idDispositivo ==
                            vCtrl.vehiculoSeleccionado?.idDispositivo;
                        final esOnline = vCtrl.vehiculoEstaOnline(
                          v.idDispositivo,
                        );

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: esSeleccionado
                                ? AppColors.primaryOrange.withValues(alpha:0.08)
                                : Colors.white.withValues(alpha:0.02),
                            border: Border.all(
                              color: esSeleccionado
                                  ? AppColors.primaryOrange.withValues(alpha:0.5)
                                  : Colors.white10,
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            onTap: () {
                              vCtrl.seleccionarVehiculo(v);
                              Navigator.pop(context);
                            },
                            leading: Stack(
                              children: [
                                Icon(
                                  Icons.radar_rounded,
                                  color: esSeleccionado
                                      ? AppColors.primaryOrange
                                      : Colors.white24,
                                  size: 28,
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: esOnline
                                          ? Colors.greenAccent
                                          : Colors.white24,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF0D0D0D),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: esOnline
                                              ? Colors.greenAccent.withValues(alpha:0.5)
                                              : Colors.transparent,
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            title: Text(
                              v.alias.toUpperCase(),
                              style: GoogleFonts.oswald(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 6,
                                  color: esOnline
                                      ? Colors.greenAccent.withValues(alpha:0.5)
                                      : Colors.white24,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  esOnline ? "EN LÍNEA" : "SIN SEÑAL",
                                  style: GoogleFonts.roboto(
                                    color: esOnline
                                        ? Colors.greenAccent.withValues(alpha:0.5)
                                        : Colors.white24,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            trailing: esSeleccionado
                                ? const Icon(
                                    Icons.check_circle,
                                    color: AppColors.primaryOrange,
                                    size: 18,
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VincularVehiculoScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_moderator_rounded, size: 20),
                    label: Text(
                      "VINCULAR NUEVO",
                      style: GoogleFonts.oswald(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () => _handleLogout(context),
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: Colors.white38,
                    size: 18,
                  ),
                  label: Text(
                    "CERRAR SESIÓN",
                    style: GoogleFonts.roboto(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
