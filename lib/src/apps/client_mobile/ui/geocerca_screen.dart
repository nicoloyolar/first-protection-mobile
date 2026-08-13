import 'package:first_protection/core/services/database_service.dart';
import 'package:first_protection/core/theme/app_colors.dart';
import 'package:first_protection/core/widgets/custom_notification.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Geocerca: zona fija configurable por el usuario, independiente del modo
/// estacionado/armado y de la ubicación del teléfono (ver
/// docs/plan-de-trabajo.md Pista A). Mientras esté activa, si el vehículo
/// se aleja más del radio configurado desde el centro definido, se genera
/// una alerta — en cualquier momento, no solo cuando el usuario armó el
/// sistema al estacionar.
class GeocercaScreen extends StatefulWidget {
  const GeocercaScreen({
    super.key,
    required this.idDispositivo,
    required this.alias,
  });

  final String idDispositivo;
  final String alias;

  @override
  State<GeocercaScreen> createState() => _GeocercaScreenState();
}

class _GeocercaScreenState extends State<GeocercaScreen> {
  final _databaseService = DatabaseService();

  bool _cargando = true;
  bool _guardando = false;
  bool _reubicando = false;

  bool _activa = false;
  double _radioMetros = 2000;
  double? _centerLat;
  double? _centerLng;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final geocerca = await _databaseService.obtenerGeocerca(widget.idDispositivo);
    _activa = geocerca['enabled'] == true;
    _radioMetros = (geocerca['radiusMeters'] as double?) ?? 2000;
    _centerLat = geocerca['centerLat'] as double?;
    _centerLng = geocerca['centerLng'] as double?;
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _usarPosicionActualDelVehiculo() async {
    setState(() => _reubicando = true);
    final posicion = await _databaseService.obtenerPosicionActualDispositivo(
      widget.idDispositivo,
    );
    if (!mounted) return;
    setState(() => _reubicando = false);

    if (posicion == null) {
      FirstProtectionNotification.show(
        context: context,
        message: "No se pudo leer la posición actual del vehículo",
        type: NotificationType.error,
      );
      return;
    }

    setState(() {
      _centerLat = posicion['lat'];
      _centerLng = posicion['lng'];
    });
    FirstProtectionNotification.show(
      context: context,
      message: "Centro actualizado a la posición actual del vehículo",
      type: NotificationType.success,
    );
  }

  Future<void> _guardar() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (_activa && (_centerLat == null || _centerLng == null)) {
      FirstProtectionNotification.show(
        context: context,
        message: "Define un centro antes de activar la geocerca",
        type: NotificationType.error,
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      await _databaseService.actualizarGeocerca(
        idDispositivo: widget.idDispositivo,
        enabled: _activa,
        centerLat: _centerLat,
        centerLng: _centerLng,
        radiusMeters: _radioMetros,
        actorUid: uid,
      );
      if (!mounted) return;
      FirstProtectionNotification.show(
        context: context,
        message: "Geocerca guardada",
        type: NotificationType.success,
      );
    } catch (e) {
      if (!mounted) return;
      FirstProtectionNotification.show(
        context: context,
        message: "No se pudo guardar: $e",
        type: NotificationType.error,
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  String get _radioLabel {
    if (_radioMetros < 1000) return "${_radioMetros.round()} m";
    return "${(_radioMetros / 1000).toStringAsFixed(1)} km";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              "GEOCERCA",
              style: GoogleFonts.oswald(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              widget.alias.toUpperCase(),
              style: GoogleFonts.roboto(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryOrange),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Define una zona segura para tu vehículo. Si sale de esa "
                    "zona en cualquier momento, te avisamos — sin importar si "
                    "activaste el modo estacionado o no.",
                    style: GoogleFonts.roboto(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 25),

                  _buildToggleCard(),
                  const SizedBox(height: 20),

                  _buildCentroCard(),
                  const SizedBox(height: 20),

                  _buildRadioCard(),

                  const SizedBox(height: 40),
                  _buildSubmitButton(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildToggleCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _activa
            ? AppColors.primaryOrange.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _activa
              ? AppColors.primaryOrange.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.share_location,
            color: _activa ? AppColors.primaryOrange : Colors.white38,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "GEOCERCA ACTIVA",
              style: GoogleFonts.oswald(
                color: _activa ? AppColors.primaryOrange : Colors.white70,
                fontSize: 13,
                letterSpacing: 1,
              ),
            ),
          ),
          Switch(
            value: _activa,
            activeThumbColor: AppColors.primaryOrange,
            onChanged: (v) => setState(() => _activa = v),
          ),
        ],
      ),
    );
  }

  Widget _buildCentroCard() {
    final tieneCentro = _centerLat != null && _centerLng != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "CENTRO DE LA ZONA",
            style: GoogleFonts.poppins(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tieneCentro
                ? "${_centerLat!.toStringAsFixed(5)}, ${_centerLng!.toStringAsFixed(5)}"
                : "Sin definir todavía",
            style: GoogleFonts.roboto(
              color: tieneCentro ? Colors.white : Colors.white38,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _reubicando ? null : _usarPosicionActualDelVehiculo,
              icon: _reubicando
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        color: AppColors.primaryOrange,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.my_location, size: 18),
              label: Text(tieneCentro ? "Actualizar al lugar actual" : "Usar posición actual del vehículo"),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryOrange,
                side: const BorderSide(color: AppColors.primaryOrange),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "RADIO DE LA ZONA",
                style: GoogleFonts.poppins(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              Text(
                _radioLabel,
                style: GoogleFonts.oswald(
                  color: AppColors.primaryOrange,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: _radioMetros,
            min: 200,
            max: 20000,
            divisions: 99,
            activeColor: AppColors.primaryOrange,
            onChanged: (v) => setState(() => _radioMetros = v),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryOrange,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        onPressed: _guardando ? null : _guardar,
        child: _guardando
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                "GUARDAR GEOCERCA",
                style: GoogleFonts.oswald(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
      ),
    );
  }
}
