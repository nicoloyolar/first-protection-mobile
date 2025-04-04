import 'package:first_protection/constants/messages.dart';
import 'package:first_protection/widgets/bottom_navigation_menu.dart';
import 'package:flutter/material.dart';

// ignore: use_key_in_widget_constructors
class HistoryScreen extends StatelessWidget {
  final List<Map<String, String>> events = [
    {"type": "Alerta", "date": "2023-10-01 10:30", "description": "Activación del sistema"},
    {"type": "Ubicación", "date": "2023-10-02 15:45", "description": "Ubicación actualizada"},
    {"type": "Alerta", "date": "2023-10-03 08:15", "description": "Intento de robo detectado"},
    {"type": "Alerta", "date": "2023-10-04 12:00", "description": "Activación manual del sistema"},
  ];

  final int _currentIndex = 1; 

  void _onItemTapped(int index, BuildContext context) {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFD32C2C),
        title: Text(Messages.appName, style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/select');
          },
        ),
        actions: [
          IconButton(icon: Icon(Icons.notifications, color: Colors.white), onPressed: () {}),
          IconButton(icon: Icon(Icons.menu, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(10),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return Card(
            elevation: 3,
            margin: EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text(
                event["type"]!,
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
              subtitle: Text(
                '${event["date"]}\n${event["description"]}',
                style: TextStyle(color: Colors.black87),
              ),
              trailing: Icon(Icons.arrow_forward_ios, color: Colors.red),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/eventDetail',
                  arguments: event,
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => _onItemTapped(index, context),
      ),
    );
  }
}