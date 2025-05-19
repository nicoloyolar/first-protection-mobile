import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VehicleHistoryScreen extends StatelessWidget {
  final String idVehiculo;
  final String patente;

  const VehicleHistoryScreen({
    super.key,
    required this.idVehiculo,
    required this.patente,
  });

  String _formatearFecha(DateTime fecha) {
    return DateFormat('dd/MM/yyyy HH:mm:ss').format(fecha);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historial de $patente'),
        backgroundColor: Colors.black87,
      ),
      backgroundColor: Colors.grey.shade200,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('eventos')
            .where('idVehiculo', isEqualTo: idVehiculo)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay eventos registrados.'));
          }

          final eventos = snapshot.data!.docs;

          return ListView.builder(
            itemCount: eventos.length,
            itemBuilder: (context, index) {
              final evento = eventos[index];
              final tipo = evento['tipo'];
              final detalle = evento['detalle'];
              final timestamp = (evento['timestamp'] as Timestamp).toDate();

              IconData icono;
              Color color;

              switch (tipo) {
                case 'activacion':
                  icono = Icons.lock_open;
                  color = Colors.redAccent;
                  break;
                case 'desactivacion':
                  icono = Icons.lock;
                  color = Colors.amber;
                  break;
                case 'corte_corriente':
                  icono = Icons.power_off;
                  color = Colors.black87;
                  break;
                default:
                  icono = Icons.info;
                  color = Colors.blueGrey;
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: Icon(icono, color: color),
                  title: Text(detalle),
                  subtitle: Text(_formatearFecha(timestamp)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
