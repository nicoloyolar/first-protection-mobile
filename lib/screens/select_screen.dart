// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:first_protection/screens/dashboard_screen.dart';
import 'package:first_protection/widgets/custom_vehicle_dialog.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:first_protection/widgets/custom_alert_dialog.dart';

class AdminDeviceSelectionScreen extends StatefulWidget {
  const AdminDeviceSelectionScreen({super.key});

  @override
  _AdminDeviceSelectionScreenState createState() =>
      _AdminDeviceSelectionScreenState();
}

class _AdminDeviceSelectionScreenState extends State<AdminDeviceSelectionScreen> {
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (_) => CustomAlert(
        message: "¿Estás seguro que deseas cerrar sesión?",
        onCancel: () {
          Navigator.of(context).pop();
        },
        onConfirm: () {
          Navigator.of(context).pop();
          Navigator.pushReplacementNamed(context, '/');
        },
        showCancelButton: true,
      ),
    );
  }

  void _showAddVehicleDialog() {
  final TextEditingController patenteController = TextEditingController();
  String estadoSeleccionado = 'Activo';

  showDialog(
    context: context,
      builder: (context) {
        return CustomVehicleDialog(
          patenteController: patenteController,
          estadoSeleccionado: estadoSeleccionado,
          onEstadoChanged: (nuevoEstado) {
            estadoSeleccionado = nuevoEstado;
          },
          onCancel: () {
            Navigator.of(context).pop();
          },
          onConfirm: () async {
            final patente = patenteController.text.trim();

            if (patente.isNotEmpty) {
              final currentUser = FirebaseAuth.instance.currentUser;

              await FirebaseFirestore.instance.collection('vehiculos').add({
                'patente': patente,
                'estado': estadoSeleccionado,
                'idUsuario': currentUser?.uid ?? '',
              });

              Navigator.of(context).pop();
            }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

            return ListView.builder(
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];
                final patente = vehicle['patente'] ?? 'Sin patente';
                final estado = vehicle['estado'] ?? 'Desconocido';

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(
                      patente,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Row(
                      children: [
                        _buildStatusIndicator(estado),
                        const SizedBox(width: 8),
                        Text(estado),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.red),
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
}
