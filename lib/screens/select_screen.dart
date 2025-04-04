// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:first_protection/constants/messages.dart';

class AdminDeviceSelectionScreen extends StatefulWidget {
  const AdminDeviceSelectionScreen({super.key});

  @override
  _AdminDeviceSelectionScreenState createState() =>
      _AdminDeviceSelectionScreenState();
}

class _AdminDeviceSelectionScreenState extends State<AdminDeviceSelectionScreen> {
  final List<Map<String, String>> devices = [
    {"patente": "CD-FG-34 - Kia Morning", "estado": "Activo"},
    {"patente": "BD-DF-78 - Audi A3", "estado": "Inactivo"},
    {"patente": "EF-BD-31 - Kia Cerato", "estado": "Activo"},
    {"patente": "GB-DB-21 - Hyundai Accent", "estado": "Inactivo"},
  ];

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
        title: Text(Messages.appName, style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFFD32C2C),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/userRegistration');
            },
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: devices.length,
          itemBuilder: (context, index) {
            final device = devices[index];
            return Card(
              elevation: 3,
              margin: EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Text(
                  '${device["patente"]}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Row(
                  children: [
                    _buildStatusIndicator(device["estado"]!), 
                    SizedBox(width: 8), 
                    Text('${device["estado"]}'),
                  ],
                ),
                trailing: Icon(Icons.arrow_forward_ios, color: Colors.red),
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/dashboard');
                },
              ),
            );
          },
        ),
      ),
    );
  }
}