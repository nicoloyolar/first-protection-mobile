// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, deprecated_member_use

import 'package:firebase_auth/firebase_auth.dart';
import 'package:first_protection/screens/dashboard_screen.dart';
import 'package:first_protection/widgets/custom_vehicle_dialog.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:first_protection/widgets/custom_alert_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminDeviceSelectionScreen extends StatefulWidget {
  const AdminDeviceSelectionScreen({super.key});

  @override
  _AdminDeviceSelectionScreenState createState() =>
      _AdminDeviceSelectionScreenState();
}

class _AdminDeviceSelectionScreenState extends State<AdminDeviceSelectionScreen> with SingleTickerProviderStateMixin {

  AnimationController? _pulseController;
  Animation<double>? _scaleAnimation;


  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController?.dispose();
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

  void _showAddVehicleDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return CustomVehicleDialog(
          onPatenteConfirmed: (patenteFormatted, marca, modelo, anio) async {
            final currentUser = FirebaseAuth.instance.currentUser;
            await FirebaseFirestore.instance.collection('vehiculos').add({
              'patente': patenteFormatted,
              'marca': marca,
              'modelo': modelo,
              'año': anio,
              'estado': 'Activo',
              'estadoAlarma': 'inactiva',
              'idUsuario': currentUser?.uid ?? '',
            });
            Navigator.of(context).pop();
          },
          onCancel: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  Widget _buildStatusIndicator(String status) {
    Color color = status == "Activo" ? Colors.green : Colors.red;
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Color getColorPorEstadoAlarma(String estadoAlarma) {
    switch (estadoAlarma) {
      case 'activa':
        return Colors.red.shade700;
      case 'pendiente':
        return Colors.amber.shade600;
      default:
        return Colors.grey[300]!;
    }
  }

  int _estadoPrioridad(String estado) {
    switch (estado) {
      case 'activa':
        return 0;
      case 'pendiente':
        return 1;
      default:
        return 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF333333),
        leading: const Icon(
          Icons.account_circle,
          color: Colors.white,
          size: 36,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              FirebaseAuth.instance.currentUser?.email ?? 'Usuario',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Selecciona tu vehículo',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _showLogoutConfirmation,
          ),
        ],
      ),
      backgroundColor: const Color(0xFFCCCCCC),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('vehiculos').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No hay vehículos registrados."));
            }

            final vehicles = snapshot.data!.docs;

            vehicles.sort((a, b) {
              final aEstado = a.data().toString().contains('estadoAlarma') ? a['estadoAlarma'] : 'inactiva';
              final bEstado = b.data().toString().contains('estadoAlarma') ? b['estadoAlarma'] : 'inactiva';
              return _estadoPrioridad(aEstado).compareTo(_estadoPrioridad(bEstado));
            });

            return ListView.builder(
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];
                final patente = vehicle['patente'] ?? 'Sin patente';
                final estado = vehicle['estado'] ?? 'Desconocido';
                final estadoAlarma = vehicle.data().toString().contains('estadoAlarma')
                  ? vehicle['estadoAlarma']
                  : 'inactiva';

                return (estadoAlarma == 'activa' && _scaleAnimation != null)
                ? AnimatedBuilder(
                    animation: _scaleAnimation!,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation!.value,
                        child: _buildAlertaCard(vehicle, patente, estado, estadoAlarma),
                      );
                    },
                  )
                : _buildAlertaCard(vehicle, patente, estado, estadoAlarma);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddVehicleDialog,
        backgroundColor: Colors.red,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 10,
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 40,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false); 
  }

  Widget _buildAlertaCard(DocumentSnapshot vehicle, String patente, String estado, String estadoAlarma) {
    
    final marca = vehicle.data().toString().contains('marca') ? vehicle['marca'] : 'Marca';
    final modelo = vehicle.data().toString().contains('modelo') ? vehicle['modelo'] : 'Modelo';
    final anio = vehicle.data().toString().contains('año') ? vehicle['año'].toString() : 'Año';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: getColorPorEstadoAlarma(estadoAlarma),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: estadoAlarma == 'activa' ? Colors.redAccent.withOpacity(0.9) : Colors.black26,
            blurRadius: estadoAlarma == 'activa' ? 20 : 4,
            spreadRadius: estadoAlarma == 'activa' ? 4 : 1,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: ListTile(
        leading: estadoAlarma == 'activa'
            ? const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 32)
            : null,
        title: Text(
          '$marca $modelo $anio',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: estadoAlarma == 'inactiva' ? Colors.black87 : Colors.white,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              patente,
              style: TextStyle(
                fontSize: 13,
                color: estadoAlarma == 'inactiva' ? Colors.black87 : Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildStatusIndicator(estado),
                const SizedBox(width: 8),
                Text(estado),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardScreen(
                patente: vehicle['patente'],
                estado: vehicle['estado'],
                idVehiculo: vehicle.id,
              ),
            ),
          );
        },
      ),
    );
  }
}
