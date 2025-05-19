// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:first_protection/widgets/custom_alert_dialog.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  final String patente;
  final String estado;
  final String idVehiculo;

  const DashboardScreen({super.key, required this.patente, required this.estado, required this.idVehiculo});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  final LatLng _carLocation = LatLng(-36.8260, -73.0498);
  bool _isAlarmActive = false;
  late final AnimationController _animationController;

  DateTime? _alertStartTime;
  Timer? _timer;
  Duration _elapsedTime = Duration.zero;

  String? _inicioCarrera;
  String? _finalCarrera;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (_) => CustomAlert(
        message: "¿Estás seguro que deseas cerrar sesión?",
        onCancel: () => Navigator.of(context).pop(),
        onConfirm: () async {
          Navigator.of(context).pop();
          await _logout(); 
        },
        showCancelButton: true,
      ),
    );
  }


  void _onMapCreated(GoogleMapController controller) {}

  void _toggleAlarm() {
    setState(() {
      _isAlarmActive = !_isAlarmActive;
      if (_isAlarmActive) {
        _alertStartTime = DateTime.now();
        _elapsedTime = Duration.zero;
        _inicioCarrera = _formatTime(_alertStartTime!);
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          setState(() {
            _elapsedTime = DateTime.now().difference(_alertStartTime!);
          });
        });
      } else {
        _timer?.cancel();
        _alertStartTime = null;
        _elapsedTime = Duration.zero;
      }
    });
  }

  void _showCustomAlert(String buttonPressed) {
    String message = '';
    IconData icon = Icons.warning_amber_rounded;
    Color iconColor = const Color(0xFFFF6C2C);

    switch (buttonPressed) {
      case 'A':
        message = '¡Humo activado! El sistema ha comenzado la disuasión.';
        icon = Icons.smoke_free;
        iconColor = Colors.blue;
        break;
      case 'B':
        message = 'Corte de corriente activado. Se ha interrumpido el suministro.';
        icon = Icons.power_off;
        iconColor = Colors.red;
        final now = DateTime.now();
        setState(() {
          _finalCarrera = _formatTime(now);
        });
        break;
      case 'C':
        message = '¡Alarma sonora activada! El sistema está emitiendo una alerta.';
        icon = Icons.volume_up;
        iconColor = Colors.green;
        break;
      case 'CALL':
        message = 'Función de llamada no implementada aún.';
        icon = Icons.phone;
        iconColor = Colors.blueAccent;
        break;
    }

    showDialog(
      context: context,
      builder: (_) => CustomAlert(
        message: message,
        icon: icon,
        iconColor: iconColor,
        onConfirm: () => Navigator.of(context).pop(),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonSize = (screenWidth - 80) / 4;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        leading: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/select');
              },
            ),
          ],
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.patente, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Text(widget.estado, style: TextStyle(fontSize: 14, color: widget.estado == "Activo" ? Colors.greenAccent : Colors.redAccent)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _showLogoutConfirmation,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (_isAlarmActive && _alertStartTime != null) ...[
                Text('Tiempo activo: ${_elapsedTime.inMinutes.toString().padLeft(2, '0')}:${(_elapsedTime.inSeconds % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 24, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildInfoCard("Inicio Carrera", _inicioCarrera ?? "--:--:--"),
                  _buildInfoCard("Final Carrera", _finalCarrera ?? "--:--:--"),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade800),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(target: _carLocation, zoom: 15),
                    markers: {
                      Marker(markerId: const MarkerId('car'), position: _carLocation, icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)),
                    },
                    zoomControlsEnabled: false,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSquareButton("A", 'assets/images/btn-humo-activado.png', buttonSize),
                  _buildSquareButton("B", 'assets/images/btn-cortacorriente-activado.png', buttonSize),
                  _buildSquareButton("C", 'assets/images/btn-audio-activado.png', buttonSize),
                  _buildSquareButton("CALL", 'assets/images/btn-audio-activado.png', buttonSize),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _toggleAlarm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text(_isAlarmActive ? "Detener Alerta" : "Activar Alerta"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSquareButton(String label, String asset, double size) {
    return SizedBox(
      width: size,
      height: size,
      child: ElevatedButton(
        onPressed: () => _showCustomAlert(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[900],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Image.asset(asset, fit: BoxFit.contain),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Expanded(
      child: Card(
        color: Colors.grey.shade900,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Column(
            children: [
              Text(title, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 20)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); 
    await FirebaseAuth.instance.signOut(); 
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false); 
  }

}
