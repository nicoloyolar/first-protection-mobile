// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';

class AdminDeviceSelectionScreen extends StatefulWidget {
  const AdminDeviceSelectionScreen({super.key});

  @override
  _AdminDeviceSelectionScreenState createState() =>
      _AdminDeviceSelectionScreenState();
}

class _AdminDeviceSelectionScreenState extends State<AdminDeviceSelectionScreen> {
  final List<Map<String, String>> devices = [
    {"patente": "CDFG-34 - Kia Morning", "estado": "Activo"},
    {"patente": "BDDF-78 - Audi A3", "estado": "Inactivo"},
    {"patente": "EFBD-31 - Kia Cerato", "estado": "Activo"},
    {"patente": "GBDB-21 - Hyundai Accent", "estado": "Inactivo"},
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
        backgroundColor: Color(0xFF333333),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),  
          child: Image.asset(
            'assets/images/banner-first-protection.png', 
            height: 150,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      backgroundColor: Color(0xFFCCCCCC), 
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
        },
        backgroundColor: Colors.red,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30), 
        ),
        elevation: 10,
        child: Icon(
          Icons.add, 
          color: Colors.white, 
          size: 40, 
        ), 
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat, 
    );
  }
}
