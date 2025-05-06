// ignore_for_file: library_private_types_in_public_api

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:first_protection/widgets/bottom_navigation_menu.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final LatLng _carLocation = LatLng(-33.4489, -70.6693);
  bool _isAlarmActive = false;
  int _currentIndex = 0;

  DateTime? _alertStartTime;
  Timer? _timer;
  Duration _elapsedTime = Duration.zero;

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
    });
  }

  void _toggleAlarm() {
    setState(() {
      _isAlarmActive = !_isAlarmActive;
      if (_isAlarmActive) {
        _alertStartTime = DateTime.now();
        _elapsedTime = Duration.zero;
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

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/dashboard');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/history');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/settings');
        break;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFCCCCCC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF333333),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/images/banner-first-protection.png',
            height: 150,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (_isAlarmActive && _alertStartTime != null) ...[
                Text(
                  'Inicio Alerta: ${_alertStartTime!.hour.toString().padLeft(2, '0')}:${_alertStartTime!.minute.toString().padLeft(2, '0')}:${_alertStartTime!.second.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tiempo activo: ${_elapsedTime.inMinutes.toString().padLeft(2, '0')}:${(_elapsedTime.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 24, color: Colors.red, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
              ],
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black26),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: GoogleMap(
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: CameraPosition(
                        target: _carLocation,
                        zoom: 15,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId('car'),
                          position: _carLocation,
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                        ),
                      },
                      zoomControlsEnabled: false,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildRoundedButton("Inicio Carrera"),
                  _buildRoundedButton("Final Carrera"),
                ],
              ),
              const SizedBox(height: 20),
              Center(child: _buildRoundedButton("Llamar a Usuario")),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center, 
                children: [
                  _buildSquareButton("A"),
                  const SizedBox(width: 8), 
                  _buildSquareButton("B"),
                  const SizedBox(width: 8), 
                  _buildSquareButton("C"),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _toggleAlarm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 205, 42, 30),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text(_isAlarmActive ? "Detener Alerta" : "Activar Alerta"),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildRoundedButton(String text) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      ),
      child: Text(text),
    );
  }

  Widget _buildSquareButton(String label) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.white,
        fixedSize: const Size(80, 80),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(label),
    );
  }
}
