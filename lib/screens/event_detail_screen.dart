import 'package:first_protection/constants/messages.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class EventDetailScreen extends StatelessWidget {
  final Map<String, String> event;

  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final LatLng eventLocation = LatLng(-33.4489, -70.6693);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFD32C2C),
        title: Text(Messages.appName, style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/history');
          },
        ),
        actions: [
          IconButton(icon: Icon(Icons.notifications, color: Colors.white), onPressed: () {}),
          IconButton(icon: Icon(Icons.menu, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${event["type"]}',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '${event["date"]}',
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '${event["description"]}',
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            SizedBox(height: 10),
            Container(
              width: double.infinity, 
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: eventLocation,
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: MarkerId('eventLocation'),
                      position: eventLocation,
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                    ),
                  },
                ),
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Coordenadas: ${eventLocation.latitude}, ${eventLocation.longitude}',
              style: TextStyle(fontSize: 14, color: Colors.black),
            ),
            SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: Text('Marcar como resuelta'),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: Text('Compartir ubicación'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 2,
                  margin: EdgeInsets.symmetric(vertical: 5),
                  child: ListTile(
                    title: Text(
                      'Acción ${index + 1}',
                      style: TextStyle(color: Colors.red),
                    ),
                    subtitle: Text(
                      'Descripción de la acción ${index + 1}',
                      style: TextStyle(color: Colors.black87),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, color: Colors.red),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}