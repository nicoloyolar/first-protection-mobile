// ignore_for_file: deprecated_member_use

import 'package:first_protection/core/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/auth_service.dart';
import '../mobile_login_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final _dbService = DatabaseService();
  final _authService = AuthService();

  String? _vehicleId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkUserVehicle();
  }

  void _checkUserVehicle() async {
    if (user == null) return;
    
    final vehicleId = await _dbService.getLinkedVehicleId(user!.uid);
    
    if (mounted) {
      setState(() {
        _vehicleId = vehicleId;
        _isLoading = false;
      });
    }
  }

  void _handleLogout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundBlack,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryOrange)),
      );
    }

    if (_vehicleId == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundBlack,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          actions: [IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: _handleLogout)],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.no_crash_outlined, size: 80, color: Colors.grey),
              const SizedBox(height: 20),
              Text(
                "NO TIENES DISPOSITIVOS",
                style: GoogleFonts.oswald(fontSize: 24, color: Colors.white),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                child: Text(
                  "Tu cuenta ha sido creada, pero no tienes un vehículo vinculado. Contacta a soporte para instalar tu First Protection.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<DatabaseEvent>(
      stream: _dbService.getVehicleStream(_vehicleId!),
      builder: (context, snapshot) {
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(backgroundColor: AppColors.backgroundBlack, body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
           return const Scaffold(
            backgroundColor: AppColors.backgroundBlack, 
            body: Center(child: Text("Error: Vehículo vinculado pero sin datos.", style: TextStyle(color: Colors.red)))
          );
        }

        final data = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
        
        bool isEngineCut = data['engine_cut'] ?? false;
        bool isProtocolActive = data['protocol_active'] ?? false;
        
        return _buildDashboard(isEngineCut, isProtocolActive);
      },
    );
  }

  Widget _buildDashboard(bool isEngineCut, bool isProtocolActive) {
    final bgColor = isProtocolActive ? const Color(0xFF3B0000) : AppColors.backgroundBlack;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text("MI VEHÍCULO ($_vehicleId)", style: GoogleFonts.oswald(color: Colors.white)),
        actions: [IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: _handleLogout)],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(child: Icon(Icons.map, color: Colors.white24, size: 50)),
            ),
          ),
          
          Expanded(
            flex: 6,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF121212),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  _buildStatusIndicator(isProtocolActive),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.power_settings_new,
                          label: isEngineCut ? "DESBLOQUEAR" : "CORTAR\nCORRIENTE",
                          isActive: isEngineCut,
                          color: Colors.orange,
                          onTap: () {
                            _dbService.sendCommand(_vehicleId!, 'engine_cut', !isEngineCut);
                          },
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.warning,
                          label: "PROTOCOLO\nEMERGENCIA",
                          isActive: isProtocolActive,
                          color: Colors.red,
                          onTap: () {
                            _dbService.sendCommand(_vehicleId!, 'protocol_active', !isProtocolActive);
                          },
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(bool isAlert) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.circle, color: isAlert ? Colors.red : Colors.green, size: 14),
        const SizedBox(width: 10),
        Text(
          isAlert ? "ALERTA ACTIVA" : "SISTEMA PROTEGIDO",
          style: GoogleFonts.oswald(color: isAlert ? Colors.red : Colors.green, fontSize: 18),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon, 
    required String label, 
    required bool isActive, 
    required Color color,
    required VoidCallback onTap
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.2) : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isActive ? color : Colors.white10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isActive ? color : Colors.white54),
            const SizedBox(height: 5),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}